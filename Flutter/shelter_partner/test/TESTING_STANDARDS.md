# Testing Standards for ShelterPartner Flutter App

## 1. Test File Organization
- Place all test files in the `test/` directory, mirroring the structure of the `lib/` directory.
- For each Dart file in `lib/`, create a corresponding test file in `test/` (e.g., `lib/views/auth/login_page.dart` → `test/views/auth/login_page_test.dart`).

## 2. Test Naming Conventions
- Name test files with a `_test.dart` suffix.
- Use descriptive test names that explain the behavior being tested.

## 3. Writing Tests
- Use the `flutter_test` package for widget and unit tests.
- Group related tests using the `group()` function.
- Use `setUp()` and `tearDown()` for test initialization and cleanup.
- Prefer `testWidgets()` for widget tests and `test()` for pure Dart logic.

## 4. Dependency Injection & Mocking Strategy
- **Use Riverpod's `ProviderScope.overrides` to inject test dependencies.**
  - Override providers in your test setup to supply fake or mock implementations as needed.
  - This makes dependencies explicit and test setup clear.
  - Example:
    ```dart
    final widget = ProviderScope(
      overrides: [
        ...FirebaseTestOverrides.overrides,
      ],
      child: MaterialApp(
        home: LoginPage(key: key),
      ),
    );
    ```

*See existing test files for full usage patterns.*

## 5. Golden Tests (Widget Screenshot Tests)
- Golden tests compare the rendered output of widgets to reference images ("golden files") to catch visual regressions.
- Place golden files in the `test/goldens/` directory. Name them descriptively (e.g., `enrichment_page.png`, `enrichment_page_additional_options_expanded.png`).
- To ensure real text is rendered in goldens, call `await loadAppFonts();` in a `setUpAll` block.
- To create or update golden files, run:
  ```sh
  flutter test --update-goldens path/to/your_test.dart
  ```
- To verify goldens, run:
  ```sh
  flutter test path/to/your_test.dart
  ```
- Always review updated golden images before committing to ensure changes are intentional.
- For multi-state widgets (e.g., collapsed/expanded), take separate goldens for each state by interacting with the widget in the test and calling `expectLater` with a different file name.
- Example:
  ```dart
  await expectLater(find.byType(MyWidget), matchesGoldenFile('goldens/my_widget_collapsed.png'));
  // Interact with widget (e.g., tap to expand)
  await tester.tap(find.text('Expand'));
  await tester.pumpAndSettle();
  await expectLater(find.byType(MyWidget), matchesGoldenFile('goldens/my_widget_expanded.png'));
  ```
- If you see rectangles instead of text, ensure fonts are loaded as described above. Also make sure your widgets inherit the theme's font. For example, use `Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16, color: Colors.black)` for text styles instead of creating a `TextStyle` from scratch. This ensures the font from your ThemeData is used in goldens and in the app. This is only sometimes needed, I'm not sure why. If/when we specify a single font to be used across all platforms, this should no longer be necessary.
- If the test passes locally but not in GitHub and the failure images show slight variations in the font, you may need to specify 'Roboto' as the default font for your test widget. See enrichment_page_golden_test.dart for an example.

## 6. Test Effectiveness Validation
**CRITICAL: Always verify that your tests can fail when the code they're testing is broken.**

This is essential to ensure your tests are actually testing the intended behavior and will catch regressions.

### Validation Process
After writing a test that passes, temporarily break the functionality and verify the test fails:

1. **For UI tests**: Change the text, remove UI elements, or modify widget properties
2. **For behavior tests**: Remove callbacks, change method calls, or alter logic
3. **For integration tests**: Break the data flow or remove key functionality

### Why This Matters
- **Prevents false security**: Tests that never fail provide false confidence
- **Catches test bugs**: Ensures your test setup and assertions are correct
- **Validates test scope**: Confirms you're testing the right behavior
- **Improves reliability**: Helps identify flaky or ineffective tests

## 7. Running Tests
- Run all tests with `flutter test` from the project root.
- **Before submitting code**: Ensure all tests pass AND verify that critical tests can fail when the code they test is broken.

---

## Additional Resources
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Riverpod Documentation](https://riverpod.dev/)
- [Golden Toolkit Documentation](https://pub.dev/packages/golden_toolkit)
