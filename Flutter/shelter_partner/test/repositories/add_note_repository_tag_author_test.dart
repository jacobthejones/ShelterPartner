import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/add_note_repository.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/test_animal_data.dart';

void main() {
  group('AddNoteRepository Tag Author Tests', () {
    late ProviderContainer container;
    late FakeFirebaseFirestore fakeFirestore;

    const shelterID = 'test-shelter';
    const animalId = 'animal1';

    setUp(() {
      FirebaseTestOverrides.initialize();
      container = ProviderContainer(overrides: FirebaseTestOverrides.overrides);
      fakeFirestore = FirebaseTestOverrides.fakeFirestore;
    });

    tearDown(() {
      container.dispose();
      FirebaseTestOverrides.cleanup();
    });

    Future<void> setUpAnimalDocument() async {
      await fakeFirestore
          .collection('shelters/$shelterID/dogs')
          .doc(animalId)
          .set({'name': 'Test Dog', 'species': 'dog', 'tags': []});
    }

    test(
      'should add tag without author when author info is not provided',
      () async {
        // Arrange
        final repository = container.read(addNoteRepositoryProvider);
        await setUpAnimalDocument();
        final animal = createTestAnimal(id: animalId, name: 'Test Dog');

        // Act
        await repository.updateAnimalTags(animal, shelterID, 'Friendly');

        // Assert
        final doc = await fakeFirestore
            .collection('shelters/$shelterID/dogs')
            .doc(animalId)
            .get();
        final tags = List<Map<String, dynamic>>.from(doc.data()!['tags']);

        expect(tags, hasLength(1));
        expect(tags[0]['title'], equals('Friendly'));
        expect(tags[0]['count'], equals(1));
        expect(tags[0]['authors'], isEmpty);
      },
    );

    test('should add tag with author when author info is provided', () async {
      // Arrange
      final repository = container.read(addNoteRepositoryProvider);
      await setUpAnimalDocument();
      final animal = createTestAnimal(id: animalId, name: 'Test Dog');

      // Act
      await repository.updateAnimalTags(
        animal,
        shelterID,
        'Friendly',
        authorName: 'John Doe',
        authorID: 'user123',
      );

      // Assert
      final doc = await fakeFirestore
          .collection('shelters/$shelterID/dogs')
          .doc(animalId)
          .get();
      final tags = List<Map<String, dynamic>>.from(doc.data()!['tags']);

      expect(tags, hasLength(1));
      expect(tags[0]['title'], equals('Friendly'));
      expect(tags[0]['count'], equals(1));
      expect(tags[0]['authors'], hasLength(1));
      expect(tags[0]['authors'][0]['author'], equals('John Doe'));
      expect(tags[0]['authors'][0]['authorID'], equals('user123'));
    });

    test(
      'should increment count and add new author when same tag is added by different user',
      () async {
        // Arrange
        final repository = container.read(addNoteRepositoryProvider);
        await setUpAnimalDocument();
        final animal = createTestAnimal(id: animalId, name: 'Test Dog');

        // Act - First user adds tag
        await repository.updateAnimalTags(
          animal,
          shelterID,
          'Friendly',
          authorName: 'John Doe',
          authorID: 'user123',
        );

        // Act - Second user adds same tag
        await repository.updateAnimalTags(
          animal,
          shelterID,
          'Friendly',
          authorName: 'Jane Smith',
          authorID: 'user456',
        );

        // Assert
        final doc = await fakeFirestore
            .collection('shelters/$shelterID/dogs')
            .doc(animalId)
            .get();
        final tags = List<Map<String, dynamic>>.from(doc.data()!['tags']);

        expect(tags, hasLength(1));
        expect(tags[0]['title'], equals('Friendly'));
        expect(tags[0]['count'], equals(2));
        expect(tags[0]['authors'], hasLength(2));

        final authors = List<Map<String, dynamic>>.from(tags[0]['authors']);
        expect(authors[0]['author'], equals('John Doe'));
        expect(authors[0]['authorID'], equals('user123'));
        expect(authors[1]['author'], equals('Jane Smith'));
        expect(authors[1]['authorID'], equals('user456'));
      },
    );

    test(
      'should not add duplicate author when same user adds same tag multiple times',
      () async {
        // Arrange
        final repository = container.read(addNoteRepositoryProvider);
        await setUpAnimalDocument();
        final animal = createTestAnimal(id: animalId, name: 'Test Dog');

        // Act - Same user adds tag twice
        await repository.updateAnimalTags(
          animal,
          shelterID,
          'Friendly',
          authorName: 'John Doe',
          authorID: 'user123',
        );

        await repository.updateAnimalTags(
          animal,
          shelterID,
          'Friendly',
          authorName: 'John Doe',
          authorID: 'user123',
        );

        // Assert
        final doc = await fakeFirestore
            .collection('shelters/$shelterID/dogs')
            .doc(animalId)
            .get();
        final tags = List<Map<String, dynamic>>.from(doc.data()!['tags']);

        expect(tags, hasLength(1));
        expect(tags[0]['title'], equals('Friendly'));
        expect(tags[0]['count'], equals(2));
        expect(tags[0]['authors'], hasLength(1)); // Should not duplicate
        expect(tags[0]['authors'][0]['author'], equals('John Doe'));
        expect(tags[0]['authors'][0]['authorID'], equals('user123'));
      },
    );

    test('should handle cats collection correctly', () async {
      // Arrange
      final repository = container.read(addNoteRepositoryProvider);
      await fakeFirestore
          .collection('shelters/$shelterID/cats')
          .doc(animalId)
          .set({'name': 'Test Cat', 'species': 'cat', 'tags': []});

      final animal = createTestAnimal(
        id: animalId,
        name: 'Test Cat',
        species: 'Cat',
      );

      // Act
      await repository.updateAnimalTags(
        animal,
        shelterID,
        'Playful',
        authorName: 'Jane Doe',
        authorID: 'user789',
      );

      // Assert
      final doc = await fakeFirestore
          .collection('shelters/$shelterID/cats')
          .doc(animalId)
          .get();
      final tags = List<Map<String, dynamic>>.from(doc.data()!['tags']);

      expect(tags, hasLength(1));
      expect(tags[0]['title'], equals('Playful'));
      expect(tags[0]['authors'], hasLength(1));
      expect(tags[0]['authors'][0]['author'], equals('Jane Doe'));
    });

    test(
      'should handle existing tags without authors field (backward compatibility)',
      () async {
        // Arrange
        final repository = container.read(addNoteRepositoryProvider);
        await fakeFirestore
            .collection('shelters/$shelterID/dogs')
            .doc(animalId)
            .set({
              'name': 'Test Dog',
              'species': 'dog',
              'tags': [
                {
                  'id': 'tag1',
                  'title': 'Friendly',
                  'count': 1,
                  'timestamp': Timestamp.now(),
                  // No authors field - legacy format
                },
              ],
            });

        final animal = createTestAnimal(id: animalId, name: 'Test Dog');

        // Act - Add same tag with author
        await repository.updateAnimalTags(
          animal,
          shelterID,
          'Friendly',
          authorName: 'John Doe',
          authorID: 'user123',
        );

        // Assert
        final doc = await fakeFirestore
            .collection('shelters/$shelterID/dogs')
            .doc(animalId)
            .get();
        final tags = List<Map<String, dynamic>>.from(doc.data()!['tags']);

        expect(tags, hasLength(1));
        expect(tags[0]['title'], equals('Friendly'));
        expect(tags[0]['count'], equals(2)); // Should increment count
        expect(tags[0]['authors'], hasLength(1)); // Should add author
        expect(tags[0]['authors'][0]['author'], equals('John Doe'));
      },
    );
  });
}
