import 'package:demo/domain/enums/work_style.dart';
import 'package:demo/domain/enums/work_tool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'performance_utils.dart';
import 'test_work_import_view_model.dart';

Future<void> dropdownTest(
  WidgetTester tester,
  PerformanceProfiler profiler,
  TestWorkImportViewModel viewModel,
) async {
  for (int i = 0; i < 5; i++) {
    await tester.tap(find.text('画风'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(WorkStyle.other.name).last);
    await tester.pumpAndSettle();
    expect(viewModel.style, equals(WorkStyle.other));

    await tester.tap(find.text('创作工具'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(WorkTool.other.name).last);
    await tester.pumpAndSettle();
    expect(viewModel.tool, equals(WorkTool.other));
  }
}

Future<void> longInputTest(
  WidgetTester tester,
  PerformanceProfiler profiler,
  TestWorkImportViewModel viewModel,
) async {
  final titleField = find.widgetWithText(TextFormField, '标题 *');
  final remarkField = find.widgetWithText(TextFormField, '备注');

  // Test very long title
  final longTitle = 'A' * 1000;
  await tester.enterText(titleField, longTitle);
  expect(viewModel.title, equals(longTitle));
  await tester.pump();

  // Test long remark with special characters
  final longRemark = List.generate(100, (i) => '测试备注$i\n').join();
  await tester.enterText(remarkField, longRemark);
  expect(viewModel.remark, equals(longRemark));
  await tester.pump();
}

Future<void> rapidFieldSwitchingTest(
  WidgetTester tester,
  PerformanceProfiler profiler,
  TestWorkImportViewModel viewModel,
) async {
  final titleField = find.widgetWithText(TextFormField, '标题 *');
  final authorField = find.widgetWithText(TextFormField, '作者');
  final remarkField = find.widgetWithText(TextFormField, '备注');

  for (int i = 0; i < 50; i++) {
    await tester.tap(titleField);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(authorField);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(remarkField);
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> rapidInputTest(
  WidgetTester tester,
  PerformanceProfiler profiler,
  TestWorkImportViewModel viewModel,
) async {
  final titleField = find.widgetWithText(TextFormField, '标题 *');
  final authorField = find.widgetWithText(TextFormField, '作者');
  final remarkField = find.widgetWithText(TextFormField, '备注');

  for (int i = 0; i < 20; i++) {
    await tester.enterText(titleField, '测试标题 $i');
    expect(viewModel.title, equals('测试标题 $i'));

    await tester.enterText(authorField, '测试作者 $i');
    expect(viewModel.author, equals('测试作者 $i'));

    await tester.enterText(remarkField, '测试备注 $i');
    expect(viewModel.remark, equals('测试备注 $i'));

    await tester.pump();
  }
}

Future<void> rapidSubmissionTest(
  WidgetTester tester,
  PerformanceProfiler profiler,
  TestWorkImportViewModel viewModel,
) async {
  final titleField = find.widgetWithText(TextFormField, '标题 *');
  final submitButton = find.text('导入');

  await tester.enterText(titleField, '测试标题');
  await tester.pump();

  for (int i = 0; i < 20; i++) {
    await tester.tap(submitButton);
    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

Future<void> validationTest(
  WidgetTester tester,
  PerformanceProfiler profiler,
  TestWorkImportViewModel viewModel,
) async {
  final titleField = find.widgetWithText(TextFormField, '标题 *');
  final submitButton = find.text('导入');

  for (int i = 0; i < 10; i++) {
    await tester.enterText(titleField, '');
    await tester.pump();
    await tester.tap(submitButton);
    await tester.pump();
    expect(viewModel.canSubmit, isFalse);

    await tester.enterText(titleField, '测试标题');
    await tester.pump();
    expect(viewModel.canSubmit, isTrue);
  }
}
