import 'package:demo/domain/enums/work_style.dart';
import 'package:demo/domain/enums/work_tool.dart';
import 'package:demo/presentation/widgets/forms/work_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkForm', () {
    testWidgets('renders all fields when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkForm(
              title: 'Test Form',
              initialTitle: 'Test Title',
              initialAuthor: 'Test Author',
              initialStyle: WorkStyle.regular,
              initialTool: WorkTool.brush,
              initialCreationDate: DateTime(2023, 1, 1),
              initialRemark: 'Test Remark',
            ),
          ),
        ),
      );

      // Check if all fields are rendered
      expect(find.text('Test Form'), findsOneWidget);
      expect(find.text('标题 *'), findsOneWidget);
      expect(find.text('作者'), findsOneWidget);
      expect(find.text('画风'), findsOneWidget);
      expect(find.text('创作工具'), findsOneWidget);
      expect(find.text('创作日期'), findsOneWidget);
      expect(find.text('备注'), findsOneWidget);

      // Check if initial values are set
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      expect(find.text('Test Remark'), findsOneWidget);
    });

    testWidgets('only shows visible fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkForm(
              initialTitle: 'Test Title',
              visibleFields: {WorkFormField.title, WorkFormField.author},
            ),
          ),
        ),
      );

      // Check visible fields
      expect(find.text('标题 *'), findsOneWidget);
      expect(find.text('作者'), findsOneWidget);

      // Check hidden fields
      expect(find.text('画风'), findsNothing);
      expect(find.text('创作工具'), findsNothing);
      expect(find.text('创作日期'), findsNothing);
      expect(find.text('备注'), findsNothing);
    });

    testWidgets('calls callbacks when values change',
        (WidgetTester tester) async {
      String? titleValue;
      String? authorValue;
      WorkStyle? styleValue;
      WorkTool? toolValue;
      DateTime? dateValue;
      String? remarkValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkForm(
              initialTitle: '',
              onTitleChanged: (value) => titleValue = value,
              onAuthorChanged: (value) => authorValue = value,
              onStyleChanged: (value) => styleValue = value,
              onToolChanged: (value) => toolValue = value,
              onCreationDateChanged: (value) => dateValue = value,
              onRemarkChanged: (value) => remarkValue = value,
            ),
          ),
        ),
      );

      // Test title change
      await tester.enterText(
          find.widgetWithText(TextFormField, '标题 *'), 'New Title');
      expect(titleValue, 'New Title');

      // Test author change
      await tester.enterText(
          find.widgetWithText(TextFormField, '作者'), 'New Author');
      expect(authorValue, 'New Author');

      // Test remark change
      await tester.enterText(
          find.widgetWithText(TextFormField, '备注'), 'New Remark');
      expect(remarkValue, 'New Remark');
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkForm(
              formKey: formKey,
              initialTitle: '',
              requiredFields: {WorkFormField.title},
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      // No error shown yet because user hasn't interacted
      expect(find.text('请输入作品标题'), findsNothing);

      // Using a direct approach to validate the form
      // In a real app, validation would happen when user submits
      formKey.currentState!.validate();
      await tester.pump();

      // Enter and clear text to trigger field interaction
      await tester.enterText(
          find.widgetWithText(TextFormField, '标题 *'), 'temp');
      await tester.enterText(find.widgetWithText(TextFormField, '标题 *'), '');
      await tester.pump();

      formKey.currentState!.validate();
      await tester.pump();

      // Now error should be shown
      expect(find.text('请输入作品标题'), findsOneWidget);

      // Enter a valid title
      await tester.enterText(
          find.widgetWithText(TextFormField, '标题 *'), 'Valid Title');
      await tester.pump();

      formKey.currentState!.validate();
      await tester.pump();

      // Error should be gone
      expect(find.text('请输入作品标题'), findsNothing);
    });

    testWidgets('supports keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkForm(
              initialTitle: '',
              showKeyboardShortcuts: true,
            ),
          ),
        ),
      );

      // Check keyboard shortcuts section
      expect(find.text('键盘快捷键:'), findsOneWidget);
      expect(
        find.text('Ctrl+T: 标题  Ctrl+A: 作者  Ctrl+R: 备注\n'
            'Enter: 确认  Tab: 下一项  Shift+Tab: 上一项'),
        findsOneWidget,
      );
    });

    testWidgets('supports custom fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkForm(
              initialTitle: '',
              customFieldBuilders: {
                'customField': (context) => const Text('Custom Field'),
              },
              insertPositions: {
                WorkFormField.title: ['customField'],
              },
            ),
          ),
        ),
      );

      // Check custom field is rendered
      expect(find.text('Custom Field'), findsOneWidget);
    });
  });
}
