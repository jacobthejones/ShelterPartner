import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/views/components/survey_banner_view.dart';
import '../../helpers/firebase_test_overrides.dart';

void main() {
  group('SurveyBannerView Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('SurveyBannerView should be a valid widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(home: Scaffold(body: SurveyBannerView())),
        ),
      );

      // The widget should render without throwing exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('SurveyBannerView hides when banner is inactive', (
      WidgetTester tester,
    ) async {
      // Set up inactive banner data in fake Firestore
      await FirebaseTestOverrides.fakeFirestore
          .collection('public')
          .doc('surveyBanner')
          .set({
            'message': 'Test survey message',
            'surveyUrl': 'https://example.com/survey',
            'isActive': false,
            'expiresAt': null,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(home: Scaffold(body: SurveyBannerView())),
        ),
      );

      // Wait for the provider to load data
      await tester.pumpAndSettle();

      // The banner should not be visible
      expect(find.text('Test survey message'), findsNothing);
      expect(find.text('Take Survey →'), findsNothing);
    });

    testWidgets('SurveyBannerView hides when banner is expired', (
      WidgetTester tester,
    ) async {
      // Set up expired banner data in fake Firestore
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      await FirebaseTestOverrides.fakeFirestore
          .collection('public')
          .doc('surveyBanner')
          .set({
            'message': 'Test survey message',
            'surveyUrl': 'https://example.com/survey',
            'isActive': true,
            'expiresAt': Timestamp.fromDate(expiredDate),
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 10)),
            ),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(home: Scaffold(body: SurveyBannerView())),
        ),
      );

      // Wait for the provider to load data
      await tester.pumpAndSettle();

      // The banner should not be visible due to expiration
      expect(find.text('Test survey message'), findsNothing);
      expect(find.text('Take Survey →'), findsNothing);
    });
  });
}
