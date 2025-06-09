import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/practice/practice_page.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// 页面操作工具类
class PageOperations {
  /// 添加元素
  static Map<String, dynamic> addElement(
      Map<String, dynamic> page, Map<String, dynamic> element) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);
    elements.add(element);

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 添加多个元素
  static Map<String, dynamic> addElements(
      Map<String, dynamic> page, List<Map<String, dynamic>> newElements) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);
    elements.addAll(newElements);

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 添加新图层
  static Map<String, dynamic> addLayer(Map<String, dynamic> page,
      {String? name}) {
    final layers =
        List<Map<String, dynamic>>.from(page['layers'] as List<dynamic>);
    final newLayerId = const Uuid().v4();

    layers.add({
      'id': newLayerId,
      'name': name ?? '图层 ${layers.length + 1}',
      'isVisible': true,
      'isLocked': false,
    });

    return {
      ...page,
      'layers': layers,
    };
  }

  /// 添加页面
  static Map<String, dynamic> addPage(
      List<Map<String, dynamic>> pages, Map<String, dynamic>? template) {
    final index = pages.isEmpty ? 0 : pages.last['index'] + 1;
    final newPage = template != null
        ? Map<String, dynamic>.from(template)
        : createDefaultPage(index);

    // 更新ID和索引
    newPage['id'] = const Uuid().v4();
    newPage['index'] = index;
    newPage['name'] = '页面 ${index + 1}';

    // 清空元素（不复制元素）
    newPage['elements'] = [];

    return newPage;
  }

  /// 创建默认页面
  static Map<String, dynamic> createDefaultPage(int index) {
    return {
      'id': const Uuid().v4(),
      'name': '页面 ${index + 1}',
      'index': index,
      'width': 595.0, // A4 宽度 (72dpi)
      'height': 842.0, // A4 高度 (72dpi)
      'background': {
        'type': 'color',
        'value': '#FFFFFF',
        'opacity': 1.0,
      },
      'margin': {
        'left': 20.0,
        'top': 20.0,
        'right': 20.0,
        'bottom': 20.0,
      },
      'elements': [],
    };
  }

  /// 创建默认页面
  static List<Map<String, dynamic>> createDefaultPages() {
    return [
      createDefaultPage(0),
    ];
  }

  /// 创建新页面
  static Map<String, dynamic> createNewPage({
    String? id,
    required Size pageSize,
    String? backgroundType,
    String? backgroundValue,
  }) {
    return {
      'id': id ?? const Uuid().v4(),
      'width': pageSize.width,
      'height': pageSize.height,
      'layers': [
        _createDefaultLayer(),
      ],
      'background': {
        'type': backgroundType ?? 'color',
        'value': backgroundValue ?? '#FFFFFF',
        'opacity': 1.0,
      },
      'elements': [],
      'settings': {
        'showGrid': true,
        'gridSize': 10,
        'snapToGrid': true,
        'snapToElements': true,
      },
    };
  }

  /// 创建页面缩略图数据
  static Map<String, dynamic> createPageThumbnail(Map<String, dynamic> page,
      {double scale = 0.2}) {
    final pageWidth = (page['width'] as num).toDouble();
    final pageHeight = (page['height'] as num).toDouble();

    return {
      'id': page['id'],
      'width': pageWidth * scale,
      'height': pageHeight * scale,
      'elements': (page['elements'] as List<dynamic>).map((element) {
        final Map<String, dynamic> scaledElement =
            Map<String, dynamic>.from(element as Map<String, dynamic>);
        scaledElement['x'] = (element['x'] as num).toDouble() * scale;
        scaledElement['y'] = (element['y'] as num).toDouble() * scale;
        scaledElement['width'] = (element['width'] as num).toDouble() * scale;
        scaledElement['height'] = (element['height'] as num).toDouble() * scale;
        return scaledElement;
      }).toList(),
      'background': page['background'],
    };
  }

  /// 删除元素
  static Map<String, dynamic> deleteElement(
      Map<String, dynamic> page, String elementId) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);
    elements.removeWhere((element) => element['id'] == elementId);

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 删除多个元素
  static Map<String, dynamic> deleteElements(
      Map<String, dynamic> page, List<String> elementIds) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);
    elements.removeWhere((element) => elementIds.contains(element['id']));

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 删除图层
  static Map<String, dynamic> deleteLayer(
      Map<String, dynamic> page, String layerId) {
    final layers =
        List<Map<String, dynamic>>.from(page['layers'] as List<dynamic>);

    // 确保至少保留一个图层
    if (layers.length <= 1) {
      return page;
    }

    layers.removeWhere((layer) => layer['id'] == layerId);

    // 删除该图层上的所有元素
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);
    elements.removeWhere((element) => element['layerId'] == layerId);

    return {
      ...page,
      'layers': layers,
      'elements': elements,
    };
  }

  /// 删除页面
  static void deletePage(List<Map<String, dynamic>> pages, int index) {
    // 确保索引有效
    if (index < 0 || index >= pages.length) {
      EditPageLogger.editPageWarning('尝试删除无效索引的页面', 
        data: {'index': index, 'pagesLength': pages.length});
      return;
    }

    // 获取要删除的页面的内部索引值
    final pageIndex = pages[index]['index'] as int? ?? index;

    // 移除指定位置的页面（按数组位置删除，而不是按页面的index属性）
    pages.removeAt(index);

    // 重新编号剩余页面
    for (int i = 0; i < pages.length; i++) {
      final currentIndex = pages[i]['index'] as int? ?? i;
      if (currentIndex > pageIndex) {
        // 调整此页面的索引
        pages[i]['index'] = currentIndex - 1;
        pages[i]['name'] = '页面 ${pages[i]['index'] + 1}';
      }
    }
  }

  /// 获取页面背景颜色
  static Color getPageBackgroundColor(Map<String, dynamic> page) {
    // 默认值
    const defaultColor = '#FFFFFF';
    const defaultOpacity = 1.0;

    // 只使用新格式的背景属性
    if (page.containsKey('background') && page['background'] is Map) {
      final background = page['background'] as Map<String, dynamic>;
      final type = background['type'] as String? ?? 'color';
      final value = background['value'] as String? ?? defaultColor;
      final opacity =
          (background['opacity'] as num?)?.toDouble() ?? defaultOpacity;

      if (type == 'color' && value.isNotEmpty) {
        try {
          // 解析颜色
          String hexColor = value.replaceAll('#', '');

          // 确保颜色格式正确
          if (hexColor.length < 6) {
            hexColor = hexColor.padRight(6, 'F');
          } else if (hexColor.length > 6) {
            hexColor = hexColor.substring(0, 6);
          }

          // 添加完全不透明的 alpha 通道
          hexColor = 'FF$hexColor';

          // 创建基础颜色
          final int colorValue = int.parse(hexColor, radix: 16);
          final Color baseColor = Color(colorValue);

          // 应用透明度
          final int alpha = (opacity * 255).round();
          final Color finalColor = baseColor.withAlpha(alpha);

          return finalColor;
        } catch (e) {
          EditPageLogger.editPageError('解析颜色失败', error: e);
          // 创建带透明度的白色
          final int alpha = (opacity * 255).round();
          return Colors.white.withAlpha(alpha);
        }
      }
    }

    // 向后兼容：如果没有新格式，尝试使用旧格式（但这种情况应该越来越少）
    final backgroundColor = page['backgroundColor'] as String? ?? defaultColor;
    final backgroundOpacity =
        (page['backgroundOpacity'] as num?)?.toDouble() ?? defaultOpacity;

    try {
      // 解析颜色
      String hexColor = backgroundColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // 添加完全不透明的 alpha 通道
      }

      // 创建基础颜色
      final int colorValue = int.parse(hexColor, radix: 16);
      final Color baseColor = Color(colorValue);

      // 应用透明度
      final int alpha = (backgroundOpacity * 255).round();
      final Color finalColor = baseColor.withAlpha(alpha);

      return finalColor;
    } catch (e) {
      EditPageLogger.editPageError('解析旧格式颜色失败', error: e);
      // 创建带透明度的白色
      final int alpha = (backgroundOpacity * 255).round();
      return Colors.white.withAlpha(alpha);
    }
  }

  /// 根据索引获取页面
  static Map<String, dynamic>? getPageByIndex(
      List<Map<String, dynamic>> pages, int index) {
    try {
      return pages.firstWhere((page) => page['index'] == index);
    } catch (e) {
      return null;
    }
  }

  /// 将Map转换为PracticePage
  static PracticePage mapToPracticePage(Map<String, dynamic> map) {
    try {
      // 创建临时的基本PracticePage对象
      return PracticePage(
        id: map['id'] as String? ?? 'default',
        name: map['name'] as String? ?? '',
        index: (map['index'] as int?) ?? 0,
        width: (map['width'] as num?)?.toDouble() ?? 210.0,
        height: (map['height'] as num?)?.toDouble() ?? 297.0,
        backgroundType: map['backgroundType'] as String? ?? 'color',
        backgroundImage: map['backgroundImage'] as String?,
        backgroundColor: map['backgroundColor'] as String? ?? '#FFFFFF',
        backgroundTexture: map['backgroundTexture'] as String?,
        backgroundOpacity:
            (map['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (e) {
      EditPageLogger.editPageError('转换页面失败', error: e);
      return PracticePage.defaultPage();
    }
  }

  /// 移动页面中的元素
  static Map<String, dynamic> moveElements(Map<String, dynamic> page,
      List<String> elementIds, double dx, double dy) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);

    for (int i = 0; i < elements.length; i++) {
      if (elementIds.contains(elements[i]['id'])) {
        final element = elements[i];
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();

        element['x'] = x + dx;
        element['y'] = y + dy;
      }
    }

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 重命名图层
  static Map<String, dynamic> renameLayer(
      Map<String, dynamic> page, String layerId, String newName) {
    final layers =
        List<Map<String, dynamic>>.from(page['layers'] as List<dynamic>);

    for (int i = 0; i < layers.length; i++) {
      if (layers[i]['id'] == layerId) {
        layers[i] = {
          ...layers[i],
          'name': newName,
        };
        break;
      }
    }

    return {
      ...page,
      'layers': layers,
    };
  }

  /// 重新排序图层
  static Map<String, dynamic> reorderLayers(
      Map<String, dynamic> page, int oldIndex, int newIndex) {
    final layers =
        List<Map<String, dynamic>>.from(page['layers'] as List<dynamic>);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = layers.removeAt(oldIndex);
    layers.insert(newIndex, item);

    return {
      ...page,
      'layers': layers,
    };
  }

  /// 调整页面中元素的大小
  static Map<String, dynamic> resizeElement(
    Map<String, dynamic> page,
    String elementId,
    double newWidth,
    double newHeight,
    double newX,
    double newY,
  ) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);

    for (int i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == elementId) {
        final element = elements[i];

        element['width'] = max(1.0, newWidth);
        element['height'] = max(1.0, newHeight);
        element['x'] = newX;
        element['y'] = newY;

        break;
      }
    }

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 旋转页面中的元素
  static Map<String, dynamic> rotateElement(
      Map<String, dynamic> page, String elementId, double angle) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);

    for (int i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == elementId) {
        final element = elements[i];
        final currentRotation = (element['rotation'] as num).toDouble();

        // 规范化角度到0-360
        double newRotation = (currentRotation + angle) % 360;
        if (newRotation < 0) {
          newRotation += 360;
        }

        element['rotation'] = newRotation;
        break;
      }
    }

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 设置图层锁定状态
  static Map<String, dynamic> setLayerLock(
      Map<String, dynamic> page, String layerId, bool isLocked) {
    final layers =
        List<Map<String, dynamic>>.from(page['layers'] as List<dynamic>);

    for (int i = 0; i < layers.length; i++) {
      if (layers[i]['id'] == layerId) {
        layers[i] = {
          ...layers[i],
          'isLocked': isLocked,
        };
        break;
      }
    }

    return {
      ...page,
      'layers': layers,
    };
  }

  /// 设置图层可见性
  static Map<String, dynamic> setLayerVisibility(
      Map<String, dynamic> page, String layerId, bool isVisible) {
    final layers =
        List<Map<String, dynamic>>.from(page['layers'] as List<dynamic>);

    for (int i = 0; i < layers.length; i++) {
      if (layers[i]['id'] == layerId) {
        layers[i] = {
          ...layers[i],
          'isVisible': isVisible,
        };
        break;
      }
    }

    return {
      ...page,
      'layers': layers,
    };
  }

  /// 更新页面背景
  static Map<String, dynamic> updateBackground(
    Map<String, dynamic> page,
    String backgroundType,
    String backgroundValue, {
    double? opacity,
  }) {
    // 获取当前的透明度，如果没有提供新的透明度
    final currentOpacity = opacity ??
        (page.containsKey('background') &&
                (page['background'] as Map<String, dynamic>)
                    .containsKey('opacity')
            ? (page['background'] as Map<String, dynamic>)['opacity'] as double
            : (page['backgroundOpacity'] as num?)?.toDouble() ?? 1.0);

    return {
      ...page,
      'background': {
        'type': backgroundType,
        'value': backgroundValue,
        'opacity': currentOpacity,
      },
      // 同时更新旧格式属性，确保兼容性
      'backgroundType': backgroundType,
      'backgroundColor': backgroundValue,
      'backgroundOpacity': currentOpacity,
    };
  }

  /// 更新元素
  static Map<String, dynamic> updateElement(Map<String, dynamic> page,
      String elementId, Map<String, dynamic> properties) {
    final elements =
        List<Map<String, dynamic>>.from(page['elements'] as List<dynamic>);

    for (int i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == elementId) {
        final element = elements[i];

        // 更新元素属性
        for (final entry in properties.entries) {
          if (entry.key != 'content') {
            element[entry.key] = entry.value;
          }
        }

        // 更新内容属性
        if (properties.containsKey('content')) {
          final contentUpdates = properties['content'] as Map<String, dynamic>;
          final content = element['content'] as Map<String, dynamic>;

          for (final entry in contentUpdates.entries) {
            content[entry.key] = entry.value;
          }
        }

        break;
      }
    }

    return {
      ...page,
      'elements': elements,
    };
  }

  /// 更新页面属性
  static void updatePageProperties(
      Map<String, dynamic> page, Map<String, dynamic> properties) {
    properties.forEach((key, value) {
      if (key != 'id' && key != 'index') {
        page[key] = value;
      }
    });
  }

  /// 更新页面设置
  static Map<String, dynamic> updatePageSettings(
    Map<String, dynamic> page,
    Map<String, dynamic> settings,
  ) {
    final currentSettings =
        Map<String, dynamic>.from(page['settings'] as Map<String, dynamic>);
    currentSettings.addAll(settings);

    return {
      ...page,
      'settings': currentSettings,
    };
  }

  /// 创建默认图层
  static Map<String, dynamic> _createDefaultLayer() {
    return {
      'id': const Uuid().v4(),
      'name': '默认图层',
      'isVisible': true,
      'isLocked': false,
    };
  }
}
