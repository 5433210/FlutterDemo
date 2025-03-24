import 'package:demo/application/services/work/work_service.dart';
import 'package:demo/infrastructure/image/image_processor.dart';
import 'package:demo/presentation/dialogs/work_import/components/form/work_import_form.dart';
import 'package:demo/presentation/viewmodels/states/work_import_state.dart';
import 'package:demo/presentation/viewmodels/work_import_view_model.dart';
import 'package:demo/presentation/widgets/inputs/date_input_field.dart';
import 'package:demo/presentation/widgets/inputs/dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockWorkImportViewModel mockViewModel;
  late WorkImportState initialState;

  setUp(() {
    mockViewModel = MockWorkImportViewModel();
    initialState = const WorkImportState();
  });

  Widget buildTestWidget({WorkImportState? state}) {
    return MaterialApp(
      home: Scaffold(
        body: WorkImportForm(
          state: state ?? initialState,
          viewModel: mockViewModel,
        ),
      ),
    );
  }

  group('Form Help Text', () {
    testWidgets('shows field help text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('作品的主要标题，将显示在作品列表中'), findsOneWidget);
      expect(find.text('可选，作品的创作者'), findsOneWidget);
      expect(find.text('作品的主要画风类型'), findsOneWidget);
      expect(find.text('创作本作品使用的主要工具'), findsOneWidget);
      expect(find.text('作品的完成日期'), findsOneWidget);
      expect(find.text('可选，关于作品的其他说明'), findsOneWidget);
    });

    testWidgets('shows help icons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.byIcon(Icons.brush_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notes_outlined), findsOneWidget);
    });
  });

  group('Error Animations', () {
    testWidgets('animates error messages', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Trigger validation by interacting with title field
      await tester.enterText(find.widgetWithText(TextFormField, '标题 *'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Check for error animation widgets
      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);

      // Verify animation completion
      await tester.pumpAndSettle();
      expect(find.text('请输入作品标题'), findsOneWidget);
    });

    testWidgets('shows character counters', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter text in title field
      await tester.enterText(find.widgetWithText(TextFormField, '标题 *'), '测试');
      await tester.pump();

      // Verify counter updates
      expect(find.text('2/100'), findsOneWidget);

      // Enter long text
      await tester.enterText(
        find.widgetWithText(TextFormField, '标题 *'),
        List.filled(101, '测').join(),
      );
      await tester.pump();

      // Verify error animation
      expect(find.byType(SlideTransition), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('标题不能超过100个字符'), findsOneWidget);
    });
  });

  group('Error Handling', () {
    testWidgets('shows snackbar on submission error', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Fill required fields
      await tester.enterText(
          find.widgetWithText(TextFormField, '标题 *'), '测试标题');
      await tester.pump();

      // Trigger submission with keyboard
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Verify snackbar with retry
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);

      // Test retry action
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates future dates', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Try to set future date
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final dateField = find.byType(DateInputField);
      await tester.tap(dateField);
      await tester.pumpAndSettle();

      // Manually trigger date change
      final dateInput = tester.widget<DateInputField>(dateField);
      dateInput.onChanged.call(futureDate);
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('创作日期不能超过当前日期'), findsOneWidget);
    });
  });

  group('Keyboard Navigation', () {
    testWidgets('shows keyboard shortcuts help section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('键盘快捷键:'), findsOneWidget);
      expect(
        find.text('Ctrl+T: 标题  Ctrl+A: 作者  Ctrl+R: 备注\n'
            'Enter: 确认  Tab: 下一项  Shift+Tab: 上一项'),
        findsOneWidget,
      );
    });

    testWidgets('handles keyboard shortcuts', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Test Ctrl+T
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('Ctrl+T'), findsOneWidget);

      // Test Ctrl+A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('Ctrl+A'), findsOneWidget);

      // Test Ctrl+R
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('Ctrl+R'), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('has correct semantic labels', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.bySemanticsLabel('标题'), findsOneWidget);
      expect(find.bySemanticsLabel('作者'), findsOneWidget);
      expect(find.bySemanticsLabel('画风'), findsOneWidget);
      expect(find.bySemanticsLabel('创作工具'), findsOneWidget);
      expect(find.bySemanticsLabel('创作日期'), findsOneWidget);
      expect(find.bySemanticsLabel('备注'), findsOneWidget);
    });

    testWidgets('maintains focus order', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Get all focusable fields
      final fields = tester.widgetList<Widget>(
        find.byWidgetPredicate((widget) =>
            widget is TextFormField ||
            widget is DropdownField ||
            widget is DateInputField),
      );

      // Verify expected number of fields
      expect(fields.length, equals(6));

      // Tab through all fields
      for (var i = 0; i < fields.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
    });

    testWidgets('shows error messages to screen readers', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Trigger validation
      await tester.enterText(find.widgetWithText(TextFormField, '标题 *'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp('.*请输入作品标题.*')),
        findsOneWidget,
      );
    });
  });
}

class MockImageProcessor implements ImageProcessor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWorkImportViewModel extends WorkImportViewModel {
  final setTitleCalls = <String>[];
  final setAuthorCalls = <String>[];
  final setStyleCalls = <String>[];
  final setToolCalls = <String>[];
  final setDateCalls = <DateTime>[];
  final setRemarkCalls = <String>[];

  MockWorkImportViewModel() : super(MockWorkService(), MockImageProcessor());

  @override
  void setAuthor(String? author) => setAuthorCalls.add(author ?? '');

  @override
  void setCreationDate(DateTime? date) =>
      setDateCalls.add(date ?? DateTime.now());

  @override
  void setRemark(String? remark) => setRemarkCalls.add(remark ?? '');

  @override
  void setStyle(String? styleStr) => setStyleCalls.add(styleStr ?? '');

  @override
  void setTitle(String? title) => setTitleCalls.add(title ?? '');

  @override
  void setTool(String? toolStr) => setToolCalls.add(toolStr ?? '');
}

class MockWorkService implements WorkService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
