import 'dart:io';

import 'package:demo/application/services/work/work_service.dart';
import 'package:demo/infrastructure/image/image_processor.dart';
import 'package:demo/presentation/dialogs/work_import/components/preview/work_import_preview.dart';
import 'package:demo/presentation/providers/work_import_provider.dart';
import 'package:demo/presentation/viewmodels/work_import_view_model.dart';
import 'package:demo/presentation/widgets/works/enhanced_work_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockWorkImportViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockWorkImportViewModel();
  });

  group('WorkImportPreview', () {
    testWidgets('shows empty state when no images', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImportProvider.overrideWith((ref) => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkImportPreview(),
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedWorkPreview), findsOneWidget);
      expect(find.text('导入'), findsOneWidget);
    });

    testWidgets('shows loading state during import', (tester) async {
      final testFile = File('test.jpg');
      mockViewModel.state = mockViewModel.state.copyWith(
        images: [testFile],
        isProcessing: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImportProvider.overrideWith((ref) => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkImportPreview(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('处理中...'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      mockViewModel.state = mockViewModel.state.copyWith(
        error: '导入失败',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImportProvider.overrideWith((ref) => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkImportPreview(),
            ),
          ),
        ),
      );

      expect(find.text('导入失败'), findsOneWidget);
    });

    testWidgets('handles failed import', (tester) async {
      final testFile = File('test.jpg');
      mockViewModel.shouldSucceed = false;
      mockViewModel.state = mockViewModel.state.copyWith(
        images: [testFile],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImportProvider.overrideWith((ref) => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkImportPreview(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('导入'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('导入失败'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('handles image deletion with cancel', (tester) async {
      final testFile = File('test.jpg');
      mockViewModel.state = mockViewModel.state.copyWith(
        images: [testFile],
        selectedImageIndex: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImportProvider.overrideWith((ref) => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkImportPreview(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(mockViewModel.removeImageCalls, isEmpty);
    });

    testWidgets('disables confirm button when processing', (tester) async {
      final testFile = File('test.jpg');
      mockViewModel.state = mockViewModel.state.copyWith(
        images: [testFile],
        isProcessing: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImportProvider.overrideWith((ref) => mockViewModel),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkImportPreview(),
            ),
          ),
        ),
      );

      final confirmButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(confirmButton.onPressed, isNull);
    });
  });
}

class MockImageProcessor implements ImageProcessor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWorkImportViewModel extends WorkImportViewModel {
  final addImagesCalls = <List<File>?>[];

  final removeImageCalls = <int>[];
  final selectImageCalls = <int>[];
  final reorderImagesCalls = <List<int>>[];
  bool importWorkCalled = false;
  bool shouldSucceed = true;
  MockWorkImportViewModel() : super(MockWorkService(), MockImageProcessor());

  @override
  Future<void> addImages([List<File>? files = const []]) async {
    addImagesCalls.add(files?.toList());
    state = state.copyWith(isProcessing: true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!shouldSucceed) {
      state = state.copyWith(
        isProcessing: false,
        error: '添加图片失败',
      );
      return;
    }
    state = state.copyWith(
      isProcessing: false,
      images: [...state.images, ...(files ?? [])],
    );
  }

  @override
  Future<bool> importWork() async {
    importWorkCalled = true;
    state = state.copyWith(isProcessing: true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!shouldSucceed) {
      state = state.copyWith(
        isProcessing: false,
        error: '导入失败',
      );
      return false;
    }
    state = state.copyWith(isProcessing: false);
    return true;
  }

  @override
  void removeImage(int index) {
    removeImageCalls.add(index);
    state = state.copyWith(
      images: List.from(state.images)..removeAt(index),
      selectedImageIndex: index >= state.images.length - 1 ? index - 1 : index,
    );
  }

  @override
  void reorderImages(int oldIndex, int newIndex) {
    reorderImagesCalls.add([oldIndex, newIndex]);
    final images = List<File>.from(state.images);
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);
    state = state.copyWith(images: images);
  }

  @override
  void selectImage(int index) {
    selectImageCalls.add(index);
    state = state.copyWith(selectedImageIndex: index);
  }
}

class MockWorkService implements WorkService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
