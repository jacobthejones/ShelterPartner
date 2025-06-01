import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/enrichment_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('EnrichmentPage Golden Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('enrichment_page_default', (WidgetTester tester) async {
      // Arrange: Create test user and shelter, get shared container
      final container = await createTestUserAndLogin(
        email: 'enrichmentuser@example.com',
        password: 'testpassword',
        firstName: 'Enrichment',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      // Get the correct shelterId from the logged-in user
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId as String;
      expect(shelterId, isNotEmpty);

      // Remove existing animals, demo animals have some random elements
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Add test animals to Firestore using the correct shelterId
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog1')
          .set(createTestAnimalData(id: 'dog1', name: 'Sammy'));
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog2')
          .set(createTestAnimalData(
              id: 'dog2', name: 'Max', symbolColor: 'yellow'));
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog3')
          .set(
              createTestAnimalData(id: 'dog3', name: 'Buddy', inKennel: false));
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EnrichmentPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert: Golden test ('Additional Options'collapsed)
      await expectLater(
        find.byType(EnrichmentPage),
        matchesGoldenFile('goldens/enrichment_page.png'),
      );

      // Expand the 'Additional Options' ExpansionTile
      final additionalOptionsFinder =
          find.widgetWithText(ExpansionTile, 'Additional Options');
      expect(additionalOptionsFinder, findsOneWidget);
      await tester.tap(additionalOptionsFinder);
      await tester.pumpAndSettle();

      // Assert: Golden test ('Additional Options' expanded)
      await expectLater(
        find.byType(EnrichmentPage),
        matchesGoldenFile(
            'goldens/enrichment_page_additional_options_expanded.png'),
      );
    });
  });
}
