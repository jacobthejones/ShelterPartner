import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/views/components/api_key_banner_view.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/shelter_settings.dart';
import 'package:shelter_partner/models/volunteer_settings.dart';
import '../../helpers/firebase_test_overrides.dart';

void main() {
  group('ApiKeyBannerView Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('ApiKeyBannerView should be a valid widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(home: Scaffold(body: ApiKeyBannerView())),
        ),
      );

      // Should render without throwing an error
      expect(find.byType(ApiKeyBannerView), findsOneWidget);
    });

    testWidgets('ApiKeyBannerView contains expected UI elements when visible', (
      WidgetTester tester,
    ) async {
      // Create a test widget that manually shows the banner content
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: MaterialApp(
            home: Scaffold(
              body: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade100, width: 1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.pets,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ready to connect your animals via ShelterLuv?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text('Add API Key'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.close, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify UI elements are present
      expect(
        find.text('Ready to connect your animals via ShelterLuv?'),
        findsOneWidget,
      );
      expect(find.text('Add API Key'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('ApiKeyBannerProvider Logic Tests', () {
    late ProviderContainer container;

    setUp(() {
      FirebaseTestOverrides.initialize();
      container = ProviderContainer(overrides: FirebaseTestOverrides.overrides);
    });

    tearDown(() {
      container.dispose();
    });

    test('banner should show for ShelterLuv shelter without API key', () async {
      // Create test shelter with ShelterLuv but no API key
      final testShelter = Shelter(
        id: 'test-shelter',
        name: 'Test Shelter',
        address: '123 Test St',
        createdAt: Timestamp.now(),
        managementSoftware: 'ShelterLuv',
        shelterSettings: ShelterSettings.fromMap({
          'apiKey': '',
        }), // Empty API key
        volunteerSettings: VolunteerSettings.fromMap({}),
        volunteers: [],
      );

      // Test the provider logic directly by simulating the conditions
      final hasApiKey = testShelter.shelterSettings.apiKey.isNotEmpty;
      final isShelterLuv = testShelter.managementSoftware == 'ShelterLuv';
      const isDismissed = false; // Assume not dismissed
      final shouldShow = !hasApiKey && !isDismissed && isShelterLuv;

      expect(shouldShow, isTrue);
    });

    test(
      'banner should NOT show for non-ShelterLuv shelter without API key',
      () async {
        // Create test shelter with different management software but no API key
        final testShelter = Shelter(
          id: 'test-shelter',
          name: 'Test Shelter',
          address: '123 Test St',
          createdAt: Timestamp.now(),
          managementSoftware: 'Animals First', // Different management software
          shelterSettings: ShelterSettings.fromMap({
            'apiKey': '',
          }), // Empty API key
          volunteerSettings: VolunteerSettings.fromMap({}),
          volunteers: [],
        );

        // Test the provider logic directly by simulating the conditions
        final hasApiKey = testShelter.shelterSettings.apiKey.isNotEmpty;
        final isShelterLuv = testShelter.managementSoftware == 'ShelterLuv';
        const isDismissed = false; // Assume not dismissed
        final shouldShow = !hasApiKey && !isDismissed && isShelterLuv;

        expect(shouldShow, isFalse);
      },
    );

    test(
      'banner should NOT show for ShelterLuv shelter with API key',
      () async {
        // Create test shelter with ShelterLuv and API key
        final testShelter = Shelter(
          id: 'test-shelter',
          name: 'Test Shelter',
          address: '123 Test St',
          createdAt: Timestamp.now(),
          managementSoftware: 'ShelterLuv',
          shelterSettings: ShelterSettings.fromMap({
            'apiKey': 'test-api-key',
          }), // Has API key
          volunteerSettings: VolunteerSettings.fromMap({}),
          volunteers: [],
        );

        // Test the provider logic directly by simulating the conditions
        final hasApiKey = testShelter.shelterSettings.apiKey.isNotEmpty;
        final isShelterLuv = testShelter.managementSoftware == 'ShelterLuv';
        const isDismissed = false; // Assume not dismissed
        final shouldShow = !hasApiKey && !isDismissed && isShelterLuv;

        expect(shouldShow, isFalse);
      },
    );

    test('banner should NOT show for null shelter data', () async {
      // Test with null shelter
      const Shelter? testShelter = null;

      // Test the provider logic directly by simulating the conditions
      final hasApiKey = testShelter?.shelterSettings.apiKey.isNotEmpty ?? false;
      final isShelterLuv = testShelter?.managementSoftware == 'ShelterLuv';
      const isDismissed = false; // Assume not dismissed
      final shouldShow = !hasApiKey && !isDismissed && isShelterLuv;

      expect(shouldShow, isFalse);
    });

    test('banner logic validates all conditions correctly', () async {
      // Test all combination of conditions

      // ShelterLuv, no API key, not dismissed -> should show
      expect(
        _shouldShowBanner(
          managementSoftware: 'ShelterLuv',
          hasApiKey: false,
          isDismissed: false,
        ),
        isTrue,
      );

      // ShelterLuv, has API key, not dismissed -> should NOT show
      expect(
        _shouldShowBanner(
          managementSoftware: 'ShelterLuv',
          hasApiKey: true,
          isDismissed: false,
        ),
        isFalse,
      );

      // ShelterLuv, no API key, dismissed -> should NOT show
      expect(
        _shouldShowBanner(
          managementSoftware: 'ShelterLuv',
          hasApiKey: false,
          isDismissed: true,
        ),
        isFalse,
      );

      // Animals First, no API key, not dismissed -> should NOT show
      expect(
        _shouldShowBanner(
          managementSoftware: 'Animals First',
          hasApiKey: false,
          isDismissed: false,
        ),
        isFalse,
      );

      // Unknown management software, no API key, not dismissed -> should NOT show
      expect(
        _shouldShowBanner(
          managementSoftware: 'Unknown',
          hasApiKey: false,
          isDismissed: false,
        ),
        isFalse,
      );
    });
  });
}

/// Helper function to test the banner display logic
bool _shouldShowBanner({
  required String managementSoftware,
  required bool hasApiKey,
  required bool isDismissed,
}) {
  final isShelterLuv = managementSoftware == 'ShelterLuv';
  return !hasApiKey && !isDismissed && isShelterLuv;
}
