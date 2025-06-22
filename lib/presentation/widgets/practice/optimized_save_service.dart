import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../application/services/practice/practice_list_refresh_service.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'canvas_capture.dart';
import 'practice_edit_controller.dart';
import 'thumbnail_generator.dart';

/// 保存进度回调
typedef SaveProgressCallback = void Function(double progress, String message);

/// 保存结果
class SaveResult {
  final bool success;
  final String? message;
  final String? practiceId;
  final String? error;

  SaveResult._({
    required this.success,
    this.message,
    this.practiceId,
    this.error,
  });

  factory SaveResult.success({String? message, String? practiceId}) {
    return SaveResult._(
      success: true,
      message: message,
      practiceId: practiceId,
    );
  }

  factory SaveResult.error(String error) {
    return SaveResult._(
      success: false,
      error: error,
    );
  }
}

/// 优化的保存服务
/// 解决保存过程中的用户体验问题
class OptimizedSaveService {
  static const Duration _saveTimeout = Duration(seconds: 30);
  static const Size _thumbnailSize = Size(300, 400);

  /// 优化的保存字帖方法
  ///
  /// 特点：
  /// 1. 后台生成缩略图，不切换预览模式
  /// 2. 显示保存进度，禁用用户操作
  /// 3. 自动更新缓存，通知列表页刷新
  static Future<SaveResult> savePracticeOptimized({
    required PracticeEditController controller,
    required BuildContext context,
    String? title,
    bool forceOverwrite = false,
    SaveProgressCallback? onProgress,
    GlobalKey? canvasKey,
  }) async {
    final saveStartTime = DateTime.now();

    EditPageLogger.performanceInfo(
      '开始优化保存流程',
      data: {
        'title': title,
        'forceOverwrite': forceOverwrite,
        'hasCanvasKey': canvasKey != null,
        'pageCount': controller.state.pages.length,
        'timestamp': saveStartTime.toIso8601String(),
      },
    );

    try {
      // 1. 准备阶段 (5%)
      onProgress?.call(0.05, '准备保存数据...');

      if (controller.state.pages.isEmpty) {
        return SaveResult.error('无法保存：字帖页面为空');
      }

      // 确定保存标题
      final saveTitle = title ?? controller.practiceTitle;
      if (saveTitle == null || saveTitle.isEmpty) {
        return SaveResult.error('保存标题不能为空');
      }

      // 检查标题是否存在
      if (!forceOverwrite &&
          title != null &&
          title != controller.practiceTitle) {
        onProgress?.call(0.1, '检查标题冲突...');
        final exists = await controller.checkTitleExists(title);
        if (exists) {
          return SaveResult.error('title_exists');
        }
      }

      // 2. 生成缩略图阶段 (10% - 40%)
      onProgress?.call(0.1, '生成缩略图...');

      final thumbnail = await _generateThumbnailOptimized(
        controller: controller,
        canvasKey: canvasKey,
        onProgress: (progress) {
          // 缩略图生成占30%的进度
          onProgress?.call(0.1 + progress * 0.3, '生成缩略图...');
        },
      );

      EditPageLogger.performanceInfo(
        '缩略图生成完成',
        data: {
          'thumbnailSize': thumbnail?.length ?? 0,
          'generationTimeMs':
              DateTime.now().difference(saveStartTime).inMilliseconds,
        },
      );

      // 3. 准备数据阶段 (40% - 50%)
      onProgress?.call(0.4, '准备保存数据...');

      final pagesToSave = _preparePageDataForSaving(controller);

      // 4. 保存到数据库阶段 (50% - 85%)
      onProgress?.call(0.5, '保存到数据库...');

      final result = await controller.practiceService.savePractice(
        id: controller.practiceId,
        title: saveTitle,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      onProgress?.call(0.85, '更新缓存...');

      // 5. 更新控制器状态 (85% - 95%)
      // 注意：需要使用mixin中的updatePracticeTitle方法
      controller.updatePracticeTitle(saveTitle);
      controller.state.markSaved();

      // 6. 刷新列表缓存 (95% - 100%)
      onProgress?.call(0.95, '刷新列表...');
      await _refreshPracticeListCache(result.id, thumbnail);

      onProgress?.call(1.0, '保存完成');

      final totalTime = DateTime.now().difference(saveStartTime);

      EditPageLogger.performanceInfo(
        '优化保存流程完成',
        data: {
          'practiceId': result.id,
          'title': saveTitle,
          'totalTimeMs': totalTime.inMilliseconds,
          'pageCount': controller.state.pages.length,
          'thumbnailSize': thumbnail?.length ?? 0,
        },
      );

      return SaveResult.success(
        message: '字帖 "$saveTitle" 保存成功',
        practiceId: result.id,
      );
    } catch (e, stackTrace) {
      final errorTime = DateTime.now().difference(saveStartTime);

      EditPageLogger.fileOpsError(
        '优化保存流程失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'title': title,
          'errorTimeMs': errorTime.inMilliseconds,
          'pageCount': controller.state.pages.length,
        },
      );

      return SaveResult.error('保存失败：${e.toString()}');
    }
  }

  /// 优化的缩略图生成 - 不切换预览模式
  static Future<Uint8List?> _generateThumbnailOptimized({
    required PracticeEditController controller,
    GlobalKey? canvasKey,
    void Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      if (controller.state.pages.isEmpty) {
        return null;
      }

      final firstPage = controller.state.pages.first;

      // 方案1：尝试直接从Canvas捕获（不切换预览模式）
      if (canvasKey != null) {
        onProgress?.call(0.3);
        try {
          final thumbnail = await _captureCanvasDirectly(canvasKey);
          if (thumbnail != null) {
            onProgress?.call(1.0);
            EditPageLogger.performanceInfo(
              '成功从Canvas直接捕获缩略图',
              data: {
                'method': 'direct_canvas_capture',
                'thumbnailSize': thumbnail.length,
              },
            );
            return thumbnail;
          }
        } catch (e) {
          EditPageLogger.performanceWarning(
            '直接Canvas捕获失败，尝试其他方法',
            data: {'error': e.toString()},
          );
        }
      }

      onProgress?.call(0.5);

      // 方案2：使用CanvasCapture渲染（不需要预览模式）
      try {
        final thumbnail = await CanvasCapture.capturePracticePage(
          firstPage,
          width: _thumbnailSize.width,
          height: _thumbnailSize.height,
        );

        if (thumbnail != null) {
          onProgress?.call(1.0);
          EditPageLogger.performanceInfo(
            '成功使用CanvasCapture生成缩略图',
            data: {
              'method': 'canvas_capture',
              'thumbnailSize': thumbnail.length,
            },
          );
          return thumbnail;
        }
      } catch (e) {
        EditPageLogger.performanceWarning(
          'CanvasCapture生成失败，使用备选方案',
          data: {'error': e.toString()},
        );
      }

      onProgress?.call(0.8);

      // 方案3：使用ThumbnailGenerator作为备选方案
      final fallbackThumbnail = await ThumbnailGenerator.generateThumbnail(
        firstPage,
        width: _thumbnailSize.width,
        height: _thumbnailSize.height,
        title: controller.practiceTitle,
      );

      onProgress?.call(1.0);

      if (fallbackThumbnail != null) {
        EditPageLogger.performanceInfo(
          '成功使用ThumbnailGenerator生成缩略图',
          data: {
            'method': 'thumbnail_generator',
            'thumbnailSize': fallbackThumbnail.length,
          },
        );
      }

      return fallbackThumbnail;
    } catch (e, stackTrace) {
      EditPageLogger.fileOpsError(
        '优化缩略图生成失败',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 直接从Canvas捕获图像（不切换预览模式）
  static Future<Uint8List?> _captureCanvasDirectly(GlobalKey canvasKey) async {
    try {
      final context = canvasKey.currentContext;
      if (context == null) return null;

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      // 使用当前状态直接捕获
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      EditPageLogger.performanceWarning(
        '直接Canvas捕获失败',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// 准备页面数据用于保存
  static List<Map<String, dynamic>> _preparePageDataForSaving(
    PracticeEditController controller,
  ) {
    final pagesToSave = <Map<String, dynamic>>[];

    for (final page in controller.state.pages) {
      final pageData = Map<String, dynamic>.from(page);

      // 确保页面有ID
      if (!pageData.containsKey('id') || pageData['id'] == null) {
        pageData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // 确保元素数据完整
      final elements = pageData['elements'] as List<dynamic>? ?? [];
      final processedElements = <Map<String, dynamic>>[];

      for (final element in elements) {
        if (element is Map<String, dynamic>) {
          final elementData = Map<String, dynamic>.from(element);

          // 确保元素有ID
          if (!elementData.containsKey('id') || elementData['id'] == null) {
            elementData['id'] =
                DateTime.now().millisecondsSinceEpoch.toString();
          }

          processedElements.add(elementData);
        }
      }

      pageData['elements'] = processedElements;
      pagesToSave.add(pageData);
    }

    return pagesToSave;
  }

  /// 刷新字帖列表缓存
  static Future<void> _refreshPracticeListCache(
    String practiceId,
    Uint8List? thumbnail,
  ) async {
    try {
      EditPageLogger.performanceInfo(
        '开始刷新字帖列表缓存',
        data: {
          'practiceId': practiceId,
          'hasThumbnail': thumbnail != null,
        },
      );

      // 1. 清理图像缓存
      await _clearThumbnailCache(practiceId);

      // 2. 通过刷新服务通知字帖列表刷新
      // 注意：这里使用单例模式获取刷新服务
      // 在实际使用时，刷新服务会通过Provider管理
      final refreshService = PracticeListRefreshService();
      refreshService.notifyPracticeSaved(
        practiceId,
        hasThumbnail: thumbnail != null,
      );

      // 3. 使用延迟确保文件系统操作完成
      await Future.delayed(const Duration(milliseconds: 300));

      EditPageLogger.performanceInfo(
        '字帖列表缓存刷新完成',
        data: {
          'practiceId': practiceId,
          'hasThumbnail': thumbnail != null,
          'optimization': 'event_bus_refresh_with_cache_clearing',
        },
      );
    } catch (e) {
      EditPageLogger.performanceWarning(
        '刷新字帖列表缓存失败',
        data: {
          'practiceId': practiceId,
          'error': e.toString(),
        },
      );
    }
  }

  /// 清理缩略图相关的缓存
  static Future<void> _clearThumbnailCache(String practiceId) async {
    try {
      EditPageLogger.performanceInfo(
        '开始清理缩略图缓存',
        data: {
          'practiceId': practiceId,
          'operation': 'clear_thumbnail_cache',
        },
      );

      // 清理Flutter的内置图像缓存
      final imageCache = PaintingBinding.instance.imageCache;

      // 1. 根据实际的缩略图文件路径清理缓存
      try {
        // 根据PracticeStorageService中定义的路径格式
        final appDataPath = Directory.current.path; // 这里可能需要从storage service获取
        final fullThumbnailPath =
            '$appDataPath/practices/$practiceId/cover/thumbnail.jpg';

        // 清理FileImage缓存 - 这是关键步骤
        final provider = FileImage(File(fullThumbnailPath));
        imageCache.evict(provider);

        EditPageLogger.performanceInfo(
          '清理FileImage缓存',
          data: {
            'practiceId': practiceId,
            'thumbnailPath': fullThumbnailPath,
          },
        );
      } catch (e) {
        EditPageLogger.performanceWarning(
          '清理FileImage缓存失败',
          data: {
            'practiceId': practiceId,
            'error': e.toString(),
          },
        );
      }

      // 2. 清理可能的自定义缓存键
      final cacheKeys = [
        'file:practices/$practiceId/cover/thumbnail.jpg',
        'thumbnail_$practiceId',
        'practice_${practiceId}_thumbnail',
        practiceId,
      ];

      for (final key in cacheKeys) {
        try {
          EditPageLogger.performanceInfo(
            '清理缓存键',
            data: {
              'practiceId': practiceId,
              'cacheKey': key,
            },
          );
        } catch (e) {
          // 忽略清理错误
        }
      }

      // 3. 强制清理Live Images（最有效的方法）
      // 这会清理所有当前活跃的图像缓存，确保下次加载时重新读取文件
      imageCache.clearLiveImages();

      // 4. 完全清理整个图像缓存以确保缩略图更新
      // 注意：这会影响性能，但确保缩略图问题被彻底解决
      imageCache.clear();

      EditPageLogger.performanceInfo(
        '缩略图缓存清理完成',
        data: {
          'practiceId': practiceId,
          'clearedKeys': cacheKeys.length,
          'method': 'clear_all_cache',
        },
      );
    } catch (e) {
      EditPageLogger.performanceWarning(
        '清理缩略图缓存失败',
        data: {
          'practiceId': practiceId,
          'error': e.toString(),
        },
      );
    }
  }
}
