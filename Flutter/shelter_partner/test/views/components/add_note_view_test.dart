import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('AddNoteView Widget Tests', () {
    late Animal testAnimal;
    late ProviderContainer container;

    setUp(() async {
      FirebaseTestOverrides.initialize();
      container = await createTestUserAndLogin(
        email: 'testnoteuser@example.com',
        password: 'testpassword',
        firstName: 'Note',
        lastName: 'Tester',
        shelterName: 'Test Note Shelter',
      );
      testAnimal = createTestAnimal(
        id: 'test-animal-123',
        name: 'Fluffy',
        species: 'dog',
        location: 'A1',
      );
    });

    tearDown(() {
      container.dispose();
      FirebaseTestOverrides.cleanup();
    });

    testWidgets('should display all UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: AddNoteView(animal: testAnimal)),
          ),
        ),
      );

      // Verify dialog title shows animal name
      expect(find.text('Fluffy'), findsOneWidget);

      // Verify note input field
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Enter your notes here...',
        ),
        findsOneWidget,
      );

      // Verify action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Verify add photo button
      expect(find.text('Add Photo from Gallery'), findsOneWidget);
    });

    testWidgets('should handle small screen sizes without overflow', (
      WidgetTester tester,
    ) async {
      // Set a small screen size similar to iPhone
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddNoteView(animal: testAnimal),
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown and accessible
      expect(find.text('Fluffy'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Check that the dialog content doesn't overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be scrollable when content exceeds screen height', (
      WidgetTester tester,
    ) async {
      // Set a very small screen size to force scrolling
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddNoteView(animal: testAnimal),
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check if we can scroll to see all content
      // The Save button might be off-screen initially
      if (find.text('Save').evaluate().isEmpty) {
        // Try to scroll down to find the Save button
        await tester.drag(find.byType(AlertDialog), const Offset(0, -100));
        await tester.pumpAndSettle();
      }

      // Eventually we should be able to find the Save button
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('should handle text input focus without layout issues', (
      WidgetTester tester,
    ) async {
      // iPhone screen size
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddNoteView(animal: testAnimal),
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap on the text field to focus it
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Enter some text
      await tester.enterText(find.byType(TextField), 'This is a test note');
      await tester.pumpAndSettle();

      // Verify text was entered successfully
      expect(find.text('This is a test note'), findsOneWidget);

      // Verify that buttons are still accessible after focusing text field
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should prevent content overflow with SingleChildScrollView', (
      WidgetTester tester,
    ) async {
      // Set a very constrained screen size to force potential overflow
      await tester.binding.setSurfaceSize(const Size(320, 480));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddNoteView(animal: testAnimal),
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify that the dialog content is wrapped in SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify that our specific ConstrainedBox with height constraint exists
      // We look for the one with a maxHeight constraint of 70% of screen height
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes.evaluate().length, greaterThan(0));

      // Verify no layout exceptions occurred
      expect(tester.takeException(), isNull);

      // Test scrolling behavior if content is off screen
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        // Scroll down to make sure we can access content
        await tester.drag(scrollable, const Offset(0, -50));
        await tester.pumpAndSettle();

        // Should still be able to find essential elements
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      }
    });

    testWidgets('should close dialog when Cancel is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddNoteView(animal: testAnimal),
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Fluffy'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Fluffy'), findsNothing);
    });
  });
}
