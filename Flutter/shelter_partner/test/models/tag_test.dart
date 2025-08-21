import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/tag.dart';

void main() {
  group('Tag Model Tests', () {
    test('should create tag with authors field', () {
      // Arrange
      final timestamp = Timestamp.now();
      final authors = [
        {'author': 'John Doe', 'authorID': 'user1'},
        {'author': 'Jane Smith', 'authorID': 'user2'},
      ];

      // Act
      final tag = Tag(
        id: 'tag1',
        title: 'Friendly',
        count: 2,
        timestamp: timestamp,
        authors: authors,
      );

      // Assert
      expect(tag.id, equals('tag1'));
      expect(tag.title, equals('Friendly'));
      expect(tag.count, equals(2));
      expect(tag.timestamp, equals(timestamp));
      expect(tag.authors, equals(authors));
    });

    test('should create tag with empty authors by default', () {
      // Arrange
      final timestamp = Timestamp.now();

      // Act
      final tag = Tag(
        id: 'tag1',
        title: 'Friendly',
        count: 1,
        timestamp: timestamp,
      );

      // Assert
      expect(tag.authors, isEmpty);
    });

    test('should serialize and deserialize correctly with authors', () {
      // Arrange
      final timestamp = Timestamp.now();
      final authors = [
        {'author': 'John Doe', 'authorID': 'user1'},
      ];
      final tag = Tag(
        id: 'tag1',
        title: 'Friendly',
        count: 1,
        timestamp: timestamp,
        authors: authors,
      );

      // Act
      final map = tag.toMap();
      final recreatedTag = Tag.fromMap(map);

      // Assert
      expect(recreatedTag.id, equals(tag.id));
      expect(recreatedTag.title, equals(tag.title));
      expect(recreatedTag.count, equals(tag.count));
      expect(recreatedTag.timestamp, equals(tag.timestamp));
      expect(recreatedTag.authors, equals(tag.authors));
    });

    test('should serialize and deserialize correctly without authors', () {
      // Arrange
      final timestamp = Timestamp.now();
      final tag = Tag(
        id: 'tag1',
        title: 'Friendly',
        count: 1,
        timestamp: timestamp,
      );

      // Act
      final map = tag.toMap();
      final recreatedTag = Tag.fromMap(map);

      // Assert
      expect(recreatedTag.id, equals(tag.id));
      expect(recreatedTag.title, equals(tag.title));
      expect(recreatedTag.count, equals(tag.count));
      expect(recreatedTag.timestamp, equals(tag.timestamp));
      expect(recreatedTag.authors, isEmpty);
    });

    test('should handle legacy tags without authors field', () {
      // Arrange
      final legacyTagMap = {
        'id': 'tag1',
        'title': 'Friendly',
        'count': 1,
        'timestamp': Timestamp.now(),
        // No authors field - legacy format
      };

      // Act
      final tag = Tag.fromMap(legacyTagMap);

      // Assert
      expect(tag.id, equals('tag1'));
      expect(tag.title, equals('Friendly'));
      expect(tag.count, equals(1));
      expect(tag.authors, isEmpty);
    });

    test('should copyWith work correctly', () {
      // Arrange
      final originalTag = Tag(
        id: 'tag1',
        title: 'Friendly',
        count: 1,
        timestamp: Timestamp.now(),
        authors: [
          {'author': 'John Doe', 'authorID': 'user1'},
        ],
      );

      final newAuthors = [
        {'author': 'Jane Smith', 'authorID': 'user2'},
      ];

      // Act
      final updatedTag = originalTag.copyWith(count: 2, authors: newAuthors);

      // Assert
      expect(updatedTag.id, equals(originalTag.id));
      expect(updatedTag.title, equals(originalTag.title));
      expect(updatedTag.count, equals(2));
      expect(updatedTag.timestamp, equals(originalTag.timestamp));
      expect(updatedTag.authors, equals(newAuthors));
    });

    test('should handle fromFirestore factory', () {
      // Arrange
      final firestoreData = {
        'id': 'tag1',
        'title': 'Playful',
        'count': 3,
        'timestamp': Timestamp.now(),
        'authors': [
          {'author': 'Alice', 'authorID': 'user3'},
        ],
      };

      // Act
      final tag = Tag.fromFirestore(firestoreData);

      // Assert
      expect(tag.id, equals('tag1'));
      expect(tag.title, equals('Playful'));
      expect(tag.count, equals(3));
      expect(tag.authors, hasLength(1));
      expect(tag.authors[0]['author'], equals('Alice'));
      expect(tag.authors[0]['authorID'], equals('user3'));
    });
  });
}
