import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../practice_edit_controller.dart';

/// 页面渲染器
/// 用于渲染单个页面并捕获图像数据
class PageRenderer {
  /// 控制器
  final PracticeEditController controller;

  /// 页面渲染完成的回调
  final Function(int pageIndex, Uint8List? imageData)? onPageRendered;

  /// 构造函数
  PageRenderer(this.controller, {this.onPageRendered});

  /// 渲染所有页面
  /// 返回页面图像数据列表
  Future<List<Uint8List>> renderAllPages({
    Function(int current, int total)? onProgress,
    double pixelRatio = 1.0,
  }) async {
    final List<Uint8List> pageImages = [];
    final int totalPages = controller.state.pages.length;

    EditPageLogger.editPageInfo(
      '开始渲染所有页面',
      data: {
        'totalPages': totalPages,
        'pixelRatio': pixelRatio,
      },
    );

    // 保存当前页面索引，以便渲染完成后恢复
    final int originalPageIndex = controller.state.currentPageIndex;

    try {
      // 临时启用预览模式
      final bool wasPreviewMode = controller.state.isPreviewMode;
      if (!wasPreviewMode) {
        controller.togglePreviewMode(true);
      }

      // 渲染每个页面
      for (int i = 0; i < totalPages; i++) {
        // 切换到当前页面
        controller.setCurrentPage(i);

        // 通知进度
        onProgress?.call(i + 1, totalPages);

        // 等待页面渲染完成
        await Future.delayed(const Duration(milliseconds: 200));

        // 捕获页面图像
        final image = await _captureCurrentPage(pixelRatio: pixelRatio);

        if (image != null) {
          pageImages.add(image);
          // 通知页面渲染完成
          onPageRendered?.call(i, image);
        } else {
          EditPageLogger.rendererError(
            '页面图像捕获失败',
            data: {
              'pageNumber': i + 1,
              'pageIndex': i,
            },
          );
          // 通知页面渲染失败
          onPageRendered?.call(i, null);
        }
      }

      // 恢复原始页面索引
      controller.setCurrentPage(originalPageIndex);

      // 恢复预览模式
      if (!wasPreviewMode) {
        controller.togglePreviewMode(false);
      }

      EditPageLogger.editPageInfo(
        '所有页面渲染完成',
        data: {
          'successfulPages': pageImages.length,
          'totalPages': totalPages,
          'successRate': '${(pageImages.length / totalPages * 100).toStringAsFixed(1)}%',
        },
      );
      return pageImages;
    } catch (e, stack) {
      EditPageLogger.rendererError(
        '渲染页面时发生错误',
        error: e,
        stackTrace: stack,
        data: {
          'totalPages': totalPages,
          'renderedPages': pageImages.length,
        },
      );

      // 恢复原始页面索引
      controller.setCurrentPage(originalPageIndex);

      return pageImages;
    }
  }

  /// 渲染单个页面
  Future<Uint8List?> renderSinglePage(int pageIndex,
      {double pixelRatio = 1.0}) async {
    try {

      // 检查页面索引是否有效
      if (pageIndex < 0 || pageIndex >= controller.state.pages.length) {
        EditPageLogger.rendererError(
          '无效的页面索引',
          data: {
            'pageIndex': pageIndex,
            'totalPages': controller.state.pages.length,
          },
        );
        return null;
      }

      // 使用一个标志变量记录当前预览模式状态，以便在完成后还原
      final wasInPreviewMode = controller.state.isPreviewMode;

      // 如果不是预览模式，则创建一个延迟任务切换到预览模式
      if (!wasInPreviewMode) {
        // 使用Future延迟执行预览模式切换，避免在构建过程中调用setState
        await Future.microtask(() => controller.togglePreviewMode(true));
      }

      try {
        // 等待UI更新完成
        await Future.delayed(const Duration(milliseconds: 100));

        // 保存当前页面索引
        final int originalPageIndex = controller.state.currentPageIndex;

        // 切换到要渲染的页面
        controller.setCurrentPage(pageIndex);

        // 等待UI更新完成
        await Future.delayed(const Duration(milliseconds: 200));

        // 捕获页面图像
        final Uint8List? bytes =
            await _captureCurrentPage(pixelRatio: pixelRatio);

        // 恢复原始页面索引
        controller.setCurrentPage(originalPageIndex);

        // 如果我们改变了预览模式，恢复原始状态
        if (!wasInPreviewMode) {
          await Future.microtask(() => controller.togglePreviewMode(false));
        }

        if (bytes == null) {
          EditPageLogger.rendererError(
            '无法捕获页面图像',
            data: {
              'pageIndex': pageIndex,
            },
          );
          return null;
        }
        return bytes;
      } catch (e, stack) {
        EditPageLogger.rendererError(
          '渲染页面时发生错误',
          error: e,
          stackTrace: stack,
          data: {
            'pageIndex': pageIndex,
          },
        );

        // 如果我们改变了预览模式，恢复原始状态
        if (!wasInPreviewMode) {
          await Future.microtask(() => controller.togglePreviewMode(false));
        }

        return null;
      }
    } catch (e, stack) {
      EditPageLogger.rendererError(
        '渲染单个页面时发生错误',
        error: e,
        stackTrace: stack,
        data: {
          'pageIndex': pageIndex,
        },
      );
      return null;
    }
  }

  /// 捕获当前页面
  Future<Uint8List?> _captureCurrentPage({double pixelRatio = 1.0}) async {
    try {
      // 获取当前页面的 GlobalKey
      final GlobalKey? canvasKey = controller.canvasKey;

      if (canvasKey == null) {
        EditPageLogger.rendererError('canvasKey 为 null');
        return null;
      }

      // 检查 key 是否有效
      if (canvasKey.currentContext == null) {
        EditPageLogger.rendererError('无法获取 currentContext，key 可能无效');
        return null;
      }

      final RenderObject? renderObject =
          canvasKey.currentContext!.findRenderObject();

      if (renderObject == null) {
        EditPageLogger.rendererError('无法找到 RenderObject');
        return null;
      }

      if (renderObject is! RenderRepaintBoundary) {
        EditPageLogger.rendererError(
          'RenderObject 不是 RenderRepaintBoundary',
          data: {
            'renderObjectType': renderObject.runtimeType.toString(),
          },
        );
        return null;
      }

      final RenderRepaintBoundary boundary = renderObject;

      // 捕获为图片
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        EditPageLogger.rendererError(
          '无法获取图片数据',
          data: {
            'imageSize': '${image.width}x${image.height}',
          },
        );
        return null;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      return bytes;
    } catch (e, stack) {
      EditPageLogger.rendererError(
        '捕获当前页面失败',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
