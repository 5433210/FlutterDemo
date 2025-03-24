import 'package:demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkImportForm Integration Tests', () {
    testWidgets('completes full form submission flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog (adjust based on your app's navigation)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form fields
      await _fillFormFields(tester);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();

      // Verify navigation after success
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('handles validation and correction', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('请输入作品标题'), findsOneWidget);

      // Correct the error
      await tester.enterText(
          find.widgetWithText(TextFormField, '标题 *'), '测试标题');
      await tester.pumpAndSettle();

      // Verify error is cleared
      expect(find.text('请输入作品标题'), findsNothing);
    });

    testWidgets('handles network error and retry', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form fields
      await _fillFormFields(tester);
      await tester.pumpAndSettle();

      // Trigger error state (implementation dependent)
      // This might require mocking network failure

      // Verify error message
      expect(find.byType(SnackBar), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
    });

    testWidgets('preserves form state during device rotation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form fields
      await _fillFormFields(tester);
      await tester.pumpAndSettle();

      // Simulate rotation to landscape
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpAndSettle();

      // Verify form data is preserved
      expect(find.text('测试标题'), findsOneWidget);
      expect(find.text('测试作者'), findsOneWidget);
      expect(find.text('测试备注'), findsOneWidget);
    });

    testWidgets('keyboard navigation works correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Test keyboard shortcuts
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify title field has suffix text indicating focus
      expect(find.text('Ctrl+T'), findsOneWidget);

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify author field has suffix text indicating focus
      expect(find.text('Ctrl+A'), findsOneWidget);
    });

    testWidgets('handles accessibility requirements', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify semantic labels
      final SemanticsHandle handle = tester.ensureSemantics();

      // Test title field
      expect(
        tester.getSemantics(find.widgetWithText(TextFormField, '标题 *')),
        matchesSemantics(
          label: '标题 *',
          isTextField: true,
          isEnabled: true,
          isFocusable: true,
          textDirection: TextDirection.ltr,
        ),
      );

      // Test author field
      expect(
        tester.getSemantics(find.widgetWithText(TextFormField, '作者')),
        matchesSemantics(
          label: '作者',
          isTextField: true,
          isEnabled: true,
          isFocusable: true,
          textDirection: TextDirection.ltr,
        ),
      );

      // Test error state accessibility
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();

      // Verify error text is accessible
      final errorText = find.text('请输入作品标题');
      expect(
        tester.getSemantics(errorText),
        matchesSemantics(
          label: '请输入作品标题',
          isEnabled: true,
          textDirection: TextDirection.ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('supports focus traversal', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to import dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final SemanticsHandle handle = tester.ensureSemantics();

      // Test focus movement
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify focus on first field
      expect(
        tester.getSemantics(find.byType(TextField).first),
        matchesSemantics(
          isFocused: true,
          isTextField: true,
          isEnabled: true,
          isFocusable: true,
          textDirection: TextDirection.ltr,
        ),
      );

      handle.dispose();
    });
  });
}

Future<void> _fillFormFields(WidgetTester tester) async {
  // Fill title
  await tester.enterText(find.widgetWithText(TextFormField, '标题 *'), '测试标题');
  await tester.pump();

  // Fill author
  await tester.enterText(find.widgetWithText(TextFormField, '作者'), '测试作者');
  await tester.pump();

  // Select style
  await tester.tap(find.text('画风'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('other').last);
  await tester.pumpAndSettle();

  // Select tool
  await tester.tap(find.text('创作工具'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('other').last);
  await tester.pumpAndSettle();

  // Set date (using today)
  final dateField = find.byType(TextField).at(2);
  await tester.tap(dateField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('确定'));
  await tester.pumpAndSettle();

  // Fill remark
  await tester.enterText(find.widgetWithText(TextFormField, '备注'), '测试备注');
  await tester.pump();
}
