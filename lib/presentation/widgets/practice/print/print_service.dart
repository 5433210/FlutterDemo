import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../export/page_renderer.dart';
import '../practice_edit_controller.dart';

/// 打印服务
class PrintService {
  /// 捕获页面为图片
  static Future<List<Uint8List>> capturePages(
      PracticeEditController controller) async {
    debugPrint('开始捕获页面: 页面数=${controller.state.pages.length}');

    try {
      // 创建页面渲染器
      final pageRenderer = PageRenderer(controller);

      // 渲染所有页面
      final pageImages = await pageRenderer.renderAllPages(
        onProgress: (current, total) {
          debugPrint('渲染进度: $current/$total');
        },
      );

      if (pageImages.isEmpty) {
        debugPrint('错误: 未能渲染任何页面');
        return [];
      }

      debugPrint('成功渲染 ${pageImages.length} 个页面');
      return pageImages;
    } catch (e, stack) {
      debugPrint('捕获页面失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return [];
    }
  }

  /// 捕获Widget为图片
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      debugPrint('开始捕获Widget: key=${key.toString()}');

      // 检查key是否有效
      if (key.currentContext == null) {
        debugPrint('无法获取currentContext，key可能无效');
        return null;
      }

      final RenderObject? renderObject = key.currentContext!.findRenderObject();
      debugPrint('找到RenderObject: ${renderObject.runtimeType}');

      if (renderObject == null) {
        debugPrint('无法找到RenderObject');
        return null;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
            'RenderObject不是RenderRepaintBoundary: ${renderObject.runtimeType}');
        return null;
      }

      final RenderRepaintBoundary boundary = renderObject;

      // 捕获为图片
      debugPrint('开始捕获图片...');
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
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
      debugPrint('捕获Widget失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }
}
