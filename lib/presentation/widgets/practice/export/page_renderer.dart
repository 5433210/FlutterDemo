import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

    debugPrint('开始渲染所有页面: 总页数=$totalPages');

    // 保存当前页面索引，以便渲染完成后恢复
    final int originalPageIndex = controller.state.currentPageIndex;

    try {
      // 临时启用预览模式
      final bool wasPreviewMode = controller.state.isPreviewMode;
      if (!wasPreviewMode) {
        debugPrint('临时启用预览模式');
        controller.togglePreviewMode(true);
      }

      // 渲染每个页面
      for (int i = 0; i < totalPages; i++) {
        debugPrint('渲染页面 ${i + 1}/$totalPages');

        // 切换到当前页面
        controller.setCurrentPage(i);

        // 通知进度
        onProgress?.call(i + 1, totalPages);

        // 等待页面渲染完成
        await Future.delayed(const Duration(milliseconds: 200));

        // 捕获页面图像
        final image = await _captureCurrentPage(pixelRatio: pixelRatio);

        if (image != null) {
          debugPrint('成功捕获页面 ${i + 1} 图像: ${image.length} 字节');
          pageImages.add(image);

          // 通知页面渲染完成
          onPageRendered?.call(i, image);
        } else {
          debugPrint('无法捕获页面 ${i + 1} 图像');

          // 通知页面渲染失败
          onPageRendered?.call(i, null);
        }
      }

      // 恢复原始页面索引
      controller.setCurrentPage(originalPageIndex);

      // 恢复预览模式
      if (!wasPreviewMode) {
        debugPrint('恢复原始预览模式状态');
        controller.togglePreviewMode(false);
      }

      debugPrint('所有页面渲染完成: 成功渲染 ${pageImages.length}/$totalPages 页');
      return pageImages;
    } catch (e, stack) {
      debugPrint('渲染页面时发生错误: $e');
      debugPrint('堆栈跟踪: $stack');

      // 恢复原始页面索引
      controller.setCurrentPage(originalPageIndex);

      return pageImages;
    }
  }

  /// 捕获当前页面
  Future<Uint8List?> _captureCurrentPage({double pixelRatio = 1.0}) async {
    try {
      // 获取当前页面的 GlobalKey
      final GlobalKey? canvasKey = controller.canvasKey;

      if (canvasKey == null) {
        debugPrint('错误: canvasKey 为 null');
        return null;
      }

      // 检查 key 是否有效
      if (canvasKey.currentContext == null) {
        debugPrint('无法获取 currentContext，key 可能无效');
        return null;
      }

      final RenderObject? renderObject =
          canvasKey.currentContext!.findRenderObject();

      if (renderObject == null) {
        debugPrint('无法找到 RenderObject');
        return null;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
            'RenderObject 不是 RenderRepaintBoundary: ${renderObject.runtimeType}');
        return null;
      }

      final RenderRepaintBoundary boundary = renderObject;

      // 捕获为图片
      debugPrint('开始捕获图片，像素比例: $pixelRatio...');
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      debugPrint('图片捕获成功: ${image.width}x${image.height}');

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('无法获取图片数据');
        return null;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      debugPrint('图片数据获取成功: ${bytes.length} 字节');

      return bytes;
    } catch (e, stack) {
      debugPrint('捕获当前页面失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }
}
