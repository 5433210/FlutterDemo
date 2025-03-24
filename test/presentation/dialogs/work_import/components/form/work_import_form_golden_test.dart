import 'package:demo/application/services/work/work_service.dart';
import 'package:demo/infrastructure/image/image_processor.dart';
import 'package:demo/presentation/dialogs/work_import/components/form/work_import_form.dart';
import 'package:demo/presentation/viewmodels/states/work_import_state.dart';
import 'package:demo/presentation/viewmodels/work_import_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockWorkImportViewModel mockViewModel;

  setUpAll(() {
    mockViewModel = MockWorkImportViewModel();
  });

  Widget buildTestWidget({
    WorkImportState? state,
    ThemeData? theme,
    Size size = const Size(600, 800),
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: WorkImportForm(
              state: state ?? const WorkImportState(),
              viewModel: mockViewModel,
            ),
          ),
        ),
      ),
    );
  }

  group('WorkImportForm Visual Tests', () {
    testWidgets('renders empty form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(buildTestWidget());
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_empty.png'),
      );
    });

    testWidgets('renders filled form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      final state = WorkImportState(
        title: '测试标题',
        author: '测试作者',
        creationDate: DateTime(2024, 3, 24),
        remark: '测试备注',
      );
      await tester.pumpWidget(buildTestWidget(state: state));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_filled.png'),
      );
    });

    testWidgets('renders error state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      final state = const WorkImportState(
        error: '导入失败：网络错误',
      );
      await tester.pumpWidget(buildTestWidget(state: state));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_error.png'),
      );
    });

    testWidgets('renders validation errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(buildTestWidget());

      // Trigger validation
      await tester.enterText(find.widgetWithText(TextFormField, '标题 *'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_validation.png'),
      );
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpWidget(buildTestWidget(
        theme: ThemeData.dark(),
      ));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_dark.png'),
      );
    });

    testWidgets('renders in processing state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      final state = const WorkImportState(isProcessing: true);
      await tester.pumpWidget(buildTestWidget(state: state));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_processing.png'),
      );
    });

    testWidgets('renders in different screen sizes', (tester) async {
      // Small screen
      await tester.binding.setSurfaceSize(const Size(320, 480));
      await tester.pumpWidget(buildTestWidget(size: const Size(320, 480)));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_small.png'),
      );

      // Medium screen
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(buildTestWidget(size: const Size(768, 1024)));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_medium.png'),
      );

      // Large screen
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await tester.pumpWidget(buildTestWidget(size: const Size(1920, 1080)));
      await expectLater(
        find.byType(WorkImportForm),
        matchesGoldenFile('goldens/work_import_form_large.png'),
      );
    });
  });
}

class MockImageProcessor implements ImageProcessor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWorkImportViewModel extends WorkImportViewModel {
  MockWorkImportViewModel() : super(MockWorkService(), MockImageProcessor());

  @override
  void setAuthor(String? author) {}

  @override
  void setCreationDate(DateTime? date) {}

  @override
  void setRemark(String? remark) {}

  @override
  void setStyle(String? styleStr) {}

  @override
  void setTitle(String? title) {}

  @override
  void setTool(String? toolStr) {}
}

class MockWorkService implements WorkService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
