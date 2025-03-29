import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/providers/service_providers.dart';
import '../../../application/services/work/work_image_service.dart';
import '../../../infrastructure/logging/logger.dart';

final workImageProvider =
    StateNotifierProvider<WorkImageNotifier, WorkImageState>((ref) {
  final workImageService = ref.watch(workImageServiceProvider);
  AppLogger.debug('初始化WorkImageProvider');
  return WorkImageNotifier(workImageService);
});

class WorkImageNotifier extends StateNotifier<WorkImageState> {
  final WorkImageService _workImageService;
  final Map<String, String?> _thumbnailCache = {};

  WorkImageNotifier(this._workImageService) : super(WorkImageState.initial());

  // 切换页面
  Future<void> changePage(String pageId) async {
    if (pageId == state.currentPageId) return;

    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      // 获取页面图像
      final imageData =
          await _workImageService.getWorkPageImage(state.workId, pageId);
      if (imageData == null) {
        throw Exception('Image not found');
      }

      // 解析图像尺寸
      final imageSize = await _parseImageSize(imageData);
      AppLogger.debug('WorkImageProvider获取到图像尺寸', data: {
        'width': imageSize.width,
        'height': imageSize.height,
        'dataLength': imageData.length,
      });

      // 更新状态
      state = state.copyWith(
        currentPageId: pageId,
        imageData: imageData,
        imageWidth: imageSize.width,
        imageHeight: imageSize.height,
        loading: false,
      );
    } catch (e, stack) {
      AppLogger.error('WorkImageProvider切换页面失败', error: e, stackTrace: stack);
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _thumbnailCache.clear();
    super.dispose();
  }

  // 获取页面缩略图路径
  Future<String?> getThumbnailPath(String pageId) async {
    try {
      // 检查缓存
      if (_thumbnailCache.containsKey(pageId)) {
        return _thumbnailCache[pageId];
      }

      // 从服务获取缩略图路径
      final path = await _workImageService.getPageThumbnailPath(pageId);

      // 更新缓存
      _thumbnailCache[pageId] = path;

      return path;
    } catch (e) {
      AppLogger.error('获取缩略图路径失败', error: e, data: {'pageId': pageId});
      return null;
    }
  }

  // 加载作品图像
  Future<void> loadWorkImage(String workId, String pageId) async {
    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      // 获取作品图像
      final imageData =
          await _workImageService.getWorkPageImage(workId, pageId);
      if (imageData == null) {
        throw Exception('Image not found');
      }

      // 解析图像尺寸
      final imageSize = await _parseImageSize(imageData);
      AppLogger.debug('WorkImageProvider加载图像成功', data: {
        'width': imageSize.width,
        'height': imageSize.height,
        'dataLength': imageData.length,
      });

      // 获取所有页面ID
      final pageIds = await _workImageService.getWorkPageIds(workId);

      // 更新状态
      state = state.copyWith(
        workId: workId,
        currentPageId: pageId,
        pageIds: pageIds,
        imageData: imageData,
        imageWidth: imageSize.width,
        imageHeight: imageSize.height,
        loading: false,
      );
    } catch (e, stack) {
      AppLogger.error('WorkImageProvider加载图像失败', error: e, stackTrace: stack);
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // 切换到下一页
  Future<void> nextPage() async {
    if (state.pageIds.isEmpty) return;

    final currentIndex = state.pageIds.indexOf(state.currentPageId);
    if (currentIndex < 0 || currentIndex >= state.pageIds.length - 1) return;

    final nextPageId = state.pageIds[currentIndex + 1];
    await changePage(nextPageId);
  }

  // 切换到上一页
  Future<void> previousPage() async {
    if (state.pageIds.isEmpty) return;

    final currentIndex = state.pageIds.indexOf(state.currentPageId);
    if (currentIndex <= 0) return;

    final previousPageId = state.pageIds[currentIndex - 1];
    await changePage(previousPageId);
  }

  // 重新加载当前页面
  Future<void> reload() async {
    await loadWorkImage(state.workId, state.currentPageId);
  }

  // 解析图像尺寸
  Future<Size> _parseImageSize(Uint8List imageData) async {
    final decodedImage = img.decodeImage(imageData);
    if (decodedImage == null) {
      throw Exception('Failed to decode image data');
    }
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }
}

class WorkImageState {
  final String workId;
  final String currentPageId;
  final List<String> pageIds;
  final Uint8List? imageData;
  final double imageWidth;
  final double imageHeight;
  final bool loading;
  final String? error;

  WorkImageState({
    required this.workId,
    required this.currentPageId,
    required this.pageIds,
    this.imageData,
    required this.imageWidth,
    required this.imageHeight,
    required this.loading,
    this.error,
  });

  factory WorkImageState.initial() {
    return WorkImageState(
      workId: '',
      currentPageId: '',
      pageIds: [],
      imageData: null,
      imageWidth: 0,
      imageHeight: 0,
      loading: false,
    );
  }

  // 是否有下一页
  bool get hasNext {
    final currentIndex = pageIds.indexOf(currentPageId);
    return currentIndex >= 0 && currentIndex < pageIds.length - 1;
  }

  // 是否有上一页
  bool get hasPrevious {
    final currentIndex = pageIds.indexOf(currentPageId);
    return currentIndex > 0;
  }

  // 检查图像是否有效
  bool get hasValidImage =>
      imageData != null && imageWidth > 0 && imageHeight > 0;

  // 获取图像尺寸
  Size get imageSize => Size(imageWidth, imageHeight);

  WorkImageState copyWith({
    String? workId,
    String? currentPageId,
    List<String>? pageIds,
    Uint8List? imageData,
    double? imageWidth,
    double? imageHeight,
    bool? loading,
    String? error,
  }) {
    return WorkImageState(
      workId: workId ?? this.workId,
      currentPageId: currentPageId ?? this.currentPageId,
      pageIds: pageIds ?? this.pageIds,
      imageData: imageData ?? this.imageData,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}
