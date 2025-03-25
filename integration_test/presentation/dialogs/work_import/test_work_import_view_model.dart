import 'dart:io';

import 'package:demo/domain/enums/work_style.dart';
import 'package:demo/domain/enums/work_tool.dart';
import 'package:demo/presentation/viewmodels/states/work_import_state.dart';
import 'package:demo/presentation/viewmodels/work_import_view_model.dart';

import 'mock_services/mock_image_processor.dart';
import 'mock_services/mock_work_service.dart';

class TestWorkImportViewModel extends WorkImportViewModel {
  // 存储 mock 服务实例以便于测试访问和控制
  final MockWorkService mockWorkService;
  final MockImageProcessor mockImageProcessor;

  bool shouldSucceedImport = true;
  bool shouldSucceedAdd = true;

  /// 创建默认实例，每个服务都是新创建的
  factory TestWorkImportViewModel() {
    final workService = MockWorkService();
    final imageProcessor = MockImageProcessor();
    return TestWorkImportViewModel._internal(workService, imageProcessor);
  }

  /// 使用提供的 mock 服务创建实例
  TestWorkImportViewModel._internal(
    this.mockWorkService,
    this.mockImageProcessor,
  ) : super(mockWorkService, mockImageProcessor) {
    // 设置初始默认值
    setStyle(WorkStyle.regular);
    setTool(WorkTool.brush);
    setCreationDate(DateTime.now());
  }

  String? get author => state.author;

  @override
  bool get canSubmit =>
      state.images.isNotEmpty &&
      state.title.trim().isNotEmpty &&
      !state.isProcessing;
  DateTime? get creationDate => state.creationDate;
  String? get error => state.error;
  List<File> get images => state.images;
  bool get isProcessing => state.isProcessing;
  String? get remark => state.remark;
  int get selectedImageIndex => state.selectedImageIndex;
  WorkStyle? get style => state.style;
  // 便于测试的 getters
  String get title => state.title;
  WorkTool? get tool => state.tool;

  @override
  Future<void> addImages([List<File>? files]) async {
    if (!shouldSucceedAdd) {
      state = state.copyWith(
        error: '模拟添加图片失败',
        isProcessing: false,
      );
      return;
    }
    mockImageProcessor.shouldFail = false;
    if (files != null) {
      await super.addImages(files);
    }
  }

  @override
  Future<bool> importWork() async {
    if (!shouldSucceedImport) {
      state = state.copyWith(
        error: '模拟导入失败',
        isProcessing: false,
      );
      return false;
    }
    mockWorkService.shouldFail = false;
    return super.importWork();
  }

  @override
  void reset() {
    super.reset();
    shouldSucceedImport = true;
    shouldSucceedAdd = true;
    mockWorkService.reset();
    mockImageProcessor.reset();
    setStyle(WorkStyle.regular);
    setTool(WorkTool.brush);
    setCreationDate(DateTime.now());
  }

  void restoreState(WorkImportState newState) {
    state = newState;
  }

  // 测试辅助方法
  void simulateError(String error) {
    state = state.copyWith(error: error);
  }

  void simulateProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }
}
