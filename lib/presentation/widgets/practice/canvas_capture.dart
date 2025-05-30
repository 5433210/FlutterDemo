import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 画布捕获工具
///
/// 用于捕获 Flutter 组件的图像
class CanvasCapture {
  /// 捕获预览模式下的字帖页面
  ///
  /// [page] 页面数据
  /// [width] 缩略图宽度
  /// [height] 缩略图高度
  /// [title] 标题
  static Future<Uint8List?> capturePracticePage(
    Map<String, dynamic> page, {
    double width = 300.0,
    double height = 400.0,
    String? title,
  }) async {
    try {
      // 获取页面属性
      final pageWidth = (page['width'] as num?)?.toDouble() ?? 210.0;
      final pageHeight = (page['height'] as num?)?.toDouble() ?? 297.0;
      final backgroundColor =
          _parseColor(page['backgroundColor'] as String? ?? '#FFFFFF');

      // 计算缩放比例
      final scaleX = width / pageWidth;
      final scaleY = height / pageHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // 创建预览组件
      final previewWidget = Container(
        width: width,
        height: height,
        color: backgroundColor,
        child: Stack(
          children: [
            // 页面内容
            Positioned.fill(
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: _buildPageContent(page),
              ),
            ),

            // 标题
            if (title != null && title.isNotEmpty)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(178),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

      // 捕获组件图像
      return await captureWidget(
        previewWidget,
        wait: 100, // 等待 100 毫秒，确保组件已完全渲染
      );
    } catch (e, stack) {
      debugPrint('捕获字帖页面失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }

  /// 捕获组件图像
  ///
  /// [widget] 要捕获的组件
  /// [pixelRatio] 像素比例，默认为设备像素比例
  /// [wait] 捕获前等待的时间（毫秒），用于确保组件已完全渲染
  static Future<Uint8List?> captureWidget(
    Widget widget, {
    double? pixelRatio,
    int wait = 20,
  }) async {
    try {
      // 创建一个 RepaintBoundary
      final repaintBoundary = RepaintBoundary(
        child: widget,
      );

      // 创建一个 BuildContext
      final context = await _createContext(repaintBoundary);

      // 检查 context 是否有效
      if (!context.mounted) {
        debugPrint('Context is no longer mounted');
        return null;
      }

      // 获取 RenderRepaintBoundary before any async gaps
      final renderObject = context.findRenderObject() as RenderRepaintBoundary;

      // 等待组件渲染完成
      if (wait > 0) {
        await Future.delayed(Duration(milliseconds: wait));
      }

      // 检查 context 是否仍然有效
      if (!context.mounted) {
        debugPrint('Context is no longer mounted');
        return null;
      }

      // 捕获图像
      final image = await renderObject.toImage(
        pixelRatio: pixelRatio ??
            PlatformDispatcher.instance.views.first.devicePixelRatio,
      );

      // 转换为 PNG 格式
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      return null;
    } catch (e, stack) {
      debugPrint('捕获组件图像失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }

  /// 构建集字元素
  static Widget _buildCollectionElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>?;
    if (content == null) return const SizedBox.shrink();

    final characters = content['characters'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
    final fontColor = _parseColor(content['fontColor'] as String? ?? '#000000');
    final backgroundColor = content['backgroundColor'] != null
        ? _parseColor(content['backgroundColor'] as String)
        : null;

    return Container(
      color: backgroundColor,
      child: Center(
        child: Text(
          characters,
          style: TextStyle(
            color: fontColor,
            fontSize: fontSize,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 构建组合元素
  static Widget _buildGroupElement(Map<String, dynamic> element) {
    final children = element['children'] as List<dynamic>? ?? [];
    if (children.isEmpty) return const SizedBox.shrink();

    // 创建子元素组件列表
    final childWidgets = <Widget>[];

    for (final child in children) {
      final type = child['type'] as String;
      final x = (child['x'] as num).toDouble();
      final y = (child['y'] as num).toDouble();
      final width = (child['width'] as num).toDouble();
      final height = (child['height'] as num).toDouble();
      final rotation = (child['rotation'] as num?)?.toDouble() ?? 0.0;
      final opacity = (child['opacity'] as num?)?.toDouble() ?? 1.0;

      // 创建子元素组件
      Widget childWidget;

      switch (type) {
        case 'text':
          childWidget = _buildTextElement(child);
          break;
        case 'image':
          childWidget = _buildImageElement(child);
          break;
        case 'collection':
          childWidget = _buildCollectionElement(child);
          break;
        default:
          continue;
      }

      // 应用位置、大小、旋转和透明度
      childWidget = Positioned(
        left: x,
        top: y,
        width: width,
        height: height,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: rotation * 3.1415926 / 180,
            child: childWidget,
          ),
        ),
      );

      childWidgets.add(childWidget);
    }

    return Stack(children: childWidgets);
  }

  /// 构建图片元素
  static Widget _buildImageElement(Map<String, dynamic> element) {
    // 简化实现，显示占位符
    return Container(
      color: Colors.grey.withAlpha(128),
      child: const Center(
        child: Icon(Icons.image, color: Colors.white),
      ),
    );
  }

  /// 构建页面内容
  static Widget _buildPageContent(Map<String, dynamic> page) {
    // 获取页面元素
    final elements = page['elements'] as List<dynamic>? ?? [];

    // 获取页面图层
    final layers = page['layers'] as List<dynamic>? ?? [];

    // 创建元素组件列表
    final elementWidgets = <Widget>[];

    // 按图层顺序渲染元素
    for (final layer in layers) {
      final layerId = layer['id'] as String;
      final isVisible = layer['isVisible'] != false; // 默认可见

      if (!isVisible) continue;

      // 获取该图层的元素
      final layerElements =
          elements.where((e) => e['layerId'] == layerId).toList();

      // 渲染元素
      for (final element in layerElements) {
        final isHidden = element['hidden'] == true;
        if (isHidden) continue;

        final type = element['type'] as String;
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();
        final width = (element['width'] as num).toDouble();
        final height = (element['height'] as num).toDouble();
        final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
        final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

        // 创建元素组件
        Widget elementWidget;

        switch (type) {
          case 'text':
            elementWidget = _buildTextElement(element);
            break;
          case 'image':
            elementWidget = _buildImageElement(element);
            break;
          case 'collection':
            elementWidget = _buildCollectionElement(element);
            break;
          case 'group':
            elementWidget = _buildGroupElement(element);
            break;
          default:
            continue;
        }

        // 应用位置、大小、旋转和透明度
        elementWidget = Positioned(
          left: x,
          top: y,
          width: width,
          height: height,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation * 3.1415926 / 180,
              child: elementWidget,
            ),
          ),
        );

        elementWidgets.add(elementWidget);
      }
    }

    return Stack(children: elementWidgets);
  }

  /// 构建文本元素
  static Widget _buildTextElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>?;
    if (content == null) return const SizedBox.shrink();

    final text = content['text'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontColor = _parseColor(content['fontColor'] as String? ?? '#000000');
    final backgroundColor = content['backgroundColor'] != null
        ? _parseColor(content['backgroundColor'] as String)
        : null;
    final alignment = content['textAlign'] as String? ?? 'left';
    final fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final fontWeight = content['fontWeight'] as String? ?? 'normal';
    final fontStyle = content['fontStyle'] as String? ?? 'normal';

    // 解析字重
    FontWeight parsedWeight;
    if (fontWeight == 'bold') {
      parsedWeight = FontWeight.bold; // w700
    } else if (fontWeight == 'normal') {
      parsedWeight = FontWeight.normal; // w400
    } else if (fontWeight.startsWith('w')) {
      // 处理 w100-w900 格式
      final weightValue = int.tryParse(fontWeight.substring(1));
      if (weightValue != null) {
        switch (weightValue) {
          case 100:
            parsedWeight = FontWeight.w100;
            break;
          case 200:
            parsedWeight = FontWeight.w200;
            break;
          case 300:
            parsedWeight = FontWeight.w300;
            break;
          case 400:
            parsedWeight = FontWeight.w400;
            break;
          case 500:
            parsedWeight = FontWeight.w500;
            break;
          case 600:
            parsedWeight = FontWeight.w600;
            break;
          case 700:
            parsedWeight = FontWeight.w700;
            break;
          case 800:
            parsedWeight = FontWeight.w800;
            break;
          case 900:
            parsedWeight = FontWeight.w900;
            break;
          default:
            parsedWeight = FontWeight.normal;
        }
      } else {
        parsedWeight = FontWeight.normal;
      }
    } else {
      parsedWeight = FontWeight.normal;
    }

    return Container(
      color: backgroundColor,
      child: Text(
        text,
        style: TextStyle(
          color: fontColor,
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: parsedWeight,
          fontStyle:
              fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        ),
        textAlign: _getTextAlign(alignment),
      ),
    );
  }

  /// 创建一个临时的 BuildContext
  static Future<BuildContext> _createContext(Widget widget) async {
    final completer = Completer<BuildContext>();

    // 创建一个临时的 Overlay
    final overlayEntry = OverlayEntry(
      builder: (context) {
        // 在下一帧完成后获取 BuildContext
        WidgetsBinding.instance.addPostFrameCallback((_) {
          completer.complete(context);
        });

        // 返回一个不可见的组件
        return Opacity(
          opacity: 0.0,
          child: widget,
        );
      },
    );

    // 添加到 Overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the current overlay key or add to root
      final renderElement = WidgetsBinding.instance.rootElement;
      if (renderElement != null) {
        // Find the overlay from the render element
        final overlayState = Overlay.maybeOf(renderElement);
        if (overlayState != null) {
          overlayState.insert(overlayEntry);
        }
      }
    });

    // 等待 BuildContext
    final context = await completer.future;

    // 移除 Overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayEntry.remove();
    });

    return context;
  }

  /// 获取文本对齐方式
  static TextAlign _getTextAlign(String alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  /// 解析颜色字符串
  static Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      String hexColor = colorStr.substring(1);
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // 添加透明度
      }
      return Color(int.parse(hexColor, radix: 16));
    }
    return Colors.white; // 默认颜色
  }
}
