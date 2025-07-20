import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelter_partner/main.dart' as app;
import 'package:shelter_partner/services/console_logger_service.dart';
import 'package:shelter_partner/views/components/animal_card_image.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';
import 'package:uuid/uuid.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final logger = ConsoleLoggerService();

  group('Dog Workflow Integration Test', () {
    testWidgets('Create new account and test long press on animal image', (
      WidgetTester tester,
    ) async {
      // Generate unique email with timestamp and short UUID
      const uuid = Uuid();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final shortUuid = uuid.v4().substring(0, 8);
      final testEmail = 'integration_test_${timestamp}_$shortUuid@example.com';
      const testPassword = 'testpassword';

      logger.info('TEST: Creating account with email: $testEmail');

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for the login page to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to signup page
      await tester.tap(find.text('Create Shelter'));
      await tester.pumpAndSettle();
      logger.info('TEST: Navigated to signup page');

      // Fill in signup form
      final textFields = find.byType(TextField);

      // First name field (first text field)
      await tester.enterText(textFields.at(0), 'Integration');

      // Last name field (second text field)
      await tester.enterText(textFields.at(1), 'Test');

      // Email field (third text field)
      await tester.enterText(textFields.at(2), testEmail);

      // Password field (fourth text field)
      await tester.enterText(textFields.at(3), testPassword);

      // Confirm password field (fifth text field)
      await tester.enterText(textFields.at(4), testPassword);

      // Shelter name field (sixth text field)
      await tester.enterText(textFields.at(5), 'Test Shelter');

      // Shelter address field (seventh text field)
      await tester.enterText(
        textFields.at(6),
        '123 Test Street, Test City, TS 12345',
      );

      await tester.pumpAndSettle();

      // Tap the Create Shelter button
      await tester.tap(find.text('Create Shelter'));
      logger.info('TEST: Tapped Create Shelter button');

      // Wait for signup to process and iterate until the AnimalCardImages are found
      bool animalCardImagesFound = false;
      int attempts = 0;
      const maxAttempts = 10;

      while (!animalCardImagesFound && attempts < maxAttempts) {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        animalCardImagesFound = find
            .byType(AnimalCardImage)
            .evaluate()
            .isNotEmpty;
        attempts++;
        logger.info(
          'TEST: Attempt $attempts: AnimalCardImages found: $animalCardImagesFound',
        );
      }

      if (!animalCardImagesFound) {
        logger.info(
          'TEST: ❌ AnimalCardImages not found after $maxAttempts attempts',
        );
        throw Exception(
          'AnimalCardImages not found after $maxAttempts attempts',
        );
      }

      logger.info(
        'TEST: AnimalCardImages found, proceeding with long press test',
      );
      await tester.pumpAndSettle();
      logger.info("TEST: taking screenshot");
      await binding.takeScreenshot('before_long_press');
      logger.info("TEST: beforeImage captured");

      // Long press on the first AnimalCardImage
      logger.info('TEST: Attempting long press on first AnimalCardImage...');
      final allImages = find.byType(AnimalCardImage);
      final firstAnimalCardImage = allImages.first;
      final gesture = await tester.startGesture(
        tester.getCenter(firstAnimalCardImage),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      logger.info('TEST: Completed long press on animal image');

      // Take screenshot after action and verify TakeOutConfirmationView appears
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('after_long_press');

      // Verify the confirmation dialog appeared
      expect(find.byType(TakeOutConfirmationView), findsOneWidget);
      logger.info('TEST: ✅ TakeOutConfirmationView displayed');

      // Long press on the first AnimalCardImage again to put animal back
      logger.info(
        'TEST: Attempting long press on first AnimalCardImage again...',
      );
      gesture.down(tester.getCenter(firstAnimalCardImage));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      logger.info('TEST: Completed long press on animal image');

      // Verify confirmation dialog is dismissed
      expect(find.byType(TakeOutConfirmationView), findsNothing);

      // Take final screenshot
      await tester.pumpAndSettle();
      await binding.takeScreenshot('after_second_long_press');

      // TODO click button to add note

      logger.info('TEST: ✅ Integration test completed');
      return;
    });
  });
}
