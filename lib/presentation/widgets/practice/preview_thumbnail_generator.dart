import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'element_renderers/collection_element_renderer.dart';
import 'element_renderers/group_element_renderer.dart';
import 'element_renderers/image_element_renderer.dart';
import 'element_renderers/text_element_renderer.dart';

/// 使用预览模式逻辑生成缩略图
class PreviewThumbnailGenerator {
  /// 生成字帖缩略图
  static Future<Uint8List?> generateThumbnail({
    required Map<String, dynamic> page,
    required String title,
  }) async {
    try {
      // 获取页面尺寸
      final pageWidth = (page['width'] as num?)?.toDouble() ?? 595.0;
      final pageHeight = (page['height'] as num?)?.toDouble() ?? 842.0;
      
      // 缩略图尺寸
      const thumbWidth = 300.0;
      const thumbHeight = 400.0;
      
      // 计算缩放比例
      final scaleX = thumbWidth / pageWidth;
      final scaleY = thumbHeight / pageHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      
      // 创建一个预览小部件
      final previewWidget = _buildPreviewWidget(page, scale, title);
      
      // 将小部件渲染为图像
      final boundary = RenderRepaintBoundary();
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: previewWidget,
        ),
      ).attachToRenderTree(BuildOwner());
      
      // 等待布局和绘制完成
      final pipelineOwner = PipelineOwner();
      boundary.attach(pipelineOwner);
      pipelineOwner.requestVisualUpdate();
      
      // 强制布局
      boundary.layout(BoxConstraints(
        maxWidth: thumbWidth,
        maxHeight: thumbHeight,
      ));
      
      // 渲染为图像
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final thumbnailData = byteData.buffer.asUint8List();
        debugPrint('生成缩略图成功: 大小 ${thumbnailData.length} 字节');
        return thumbnailData;
      }
      
      debugPrint('生成缩略图失败: byteData 为 null');
      return null;
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      return null;
    }
  }
  
  /// 构建预览小部件
  static Widget _buildPreviewWidget(Map<String, dynamic> page, double scale, String title) {
    // 获取页面背景色
    final backgroundColor = _parseColor(page['backgroundColor'] as String? ?? '#FFFFFF');
    
    return Container(
      width: 300,
      height: 400,
      color: backgroundColor,
      child: Stack(
        children: [
          // 渲染所有元素
          ..._buildElements(page, scale),
          
          // 添加标题
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.white.withOpacity(0.7),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建所有元素
  static List<Widget> _buildElements(Map<String, dynamic> page, double scale) {
    final List<Widget> elements = [];
    
    // 获取元素列表
    final elementsList = page['elements'] as List<dynamic>? ?? [];
    if (elementsList.isEmpty) return elements;
    
    // 按图层顺序排序元素
    final sortedElements = _sortElementsByLayerOrder(elementsList, page);
    
    // 构建每个元素的小部件
    for (final element in sortedElements) {
      try {
        final elementWidget = _buildElementWidget(element, scale);
        if (elementWidget != null) {
          elements.add(elementWidget);
        }
      } catch (e) {
        debugPrint('构建元素小部件失败: $e');
      }
    }
    
    return elements;
  }
  
  /// 按图层顺序排序元素
  static List<Map<String, dynamic>> _sortElementsByLayerOrder(
      List<dynamic> elements, Map<String, dynamic> page) {
    // 获取图层列表
    final layers = page['layers'] as List<dynamic>? ?? [];
    
    // 创建图层顺序映射
    final layerOrderMap = <String, int>{};
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i] as Map<String, dynamic>;
      final layerId = layer['id'] as String;
      layerOrderMap[layerId] = i;
    }
    
    // 转换元素列表并排序
    final sortedElements = List<Map<String, dynamic>>.from(elements);
    sortedElements.sort((a, b) {
      // 获取元素所属的图层
      final layerIdA = a['layerId'] as String?;
      final layerIdB = b['layerId'] as String?;
      
      // 如果两个元素在同一图层，按元素的zIndex排序
      if (layerIdA == layerIdB) {
        final zIndexA = a['zIndex'] as int? ?? 0;
        final zIndexB = b['zIndex'] as int? ?? 0;
        return zIndexA.compareTo(zIndexB);
      }
      
      // 否则按图层顺序排序
      final orderA = layerIdA != null ? layerOrderMap[layerIdA] ?? 0 : 0;
      final orderB = layerIdB != null ? layerOrderMap[layerIdB] ?? 0 : 0;
      return orderA.compareTo(orderB);
    });
    
    return sortedElements;
  }
  
  /// 构建元素小部件
  static Widget? _buildElementWidget(Map<String, dynamic> element, double scale) {
    final String elementType = element['type'] as String;
    final double x = (element['x'] as num).toDouble() * scale;
    final double y = (element['y'] as num).toDouble() * scale;
    final double width = (element['width'] as num).toDouble() * scale;
    final double height = (element['height'] as num).toDouble() * scale;
    final double rotation = (element['rotation'] as num? ?? 0.0).toDouble();
    final double opacity = (element['opacity'] as num? ?? 1.0).toDouble();
    
    // 检查元素是否隐藏
    final bool isHidden = element['isHidden'] as bool? ?? false;
    if (isHidden) return null;
    
    // 根据元素类型选择渲染器
    Widget elementWidget;
    switch (elementType) {
      case 'text':
        elementWidget = TextElementRenderer(
          element: element,
          isEditing: false,
          scale: scale,
        );
        break;
      case 'image':
        elementWidget = ImageElementRenderer(
          element: element,
          scale: scale,
        );
        break;
      case 'collection':
        elementWidget = CollectionElementRenderer(
          element: element,
          scale: scale,
        );
        break;
      case 'group':
        elementWidget = GroupElementRenderer(
          element: element,
          isSelected: false,
          scale: scale,
        );
        break;
      default:
        elementWidget = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
          ),
        );
    }
    
    // 应用位置、大小、旋转和不透明度
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: rotation * (3.14159265359 / 180), // 角度转弧度
        child: Opacity(
          opacity: opacity,
          child: elementWidget,
        ),
      ),
    );
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
