// filepath: lib/presentation/pages/practices/adapters/page_property_adapter.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../canvas/compatibility/canvas_controller_adapter.dart';
import '../../../widgets/practice/property_panels/m3_practice_property_panel_page_wrapper.dart';
import 'property_panel_adapter.dart';

/// 页面方向枚举
enum PageOrientation {
  portrait,
  landscape,
}

/// 页面属性适配器
///
/// 将 M3PagePropertyPanel 集成到 Canvas 架构中，
/// 提供页面级别的属性管理功能，包括:
/// - 页面尺寸和方向
/// - DPI设置
/// - 背景颜色
/// - 网格显示和设置
/// - 页面边距
class PagePropertyAdapter extends BasePropertyPanelAdapter {
  final CanvasControllerAdapter canvasController;
  final ValueNotifier<Map<String, dynamic>> _pagePropertiesNotifier;
  final VoidCallback? onPagePropertiesChanged;

  PagePropertyAdapter({
    required this.canvasController,
    required Map<String, dynamic> initialPageProperties,
    this.onPagePropertiesChanged,
  }) : _pagePropertiesNotifier =
            ValueNotifier(Map.from(initialPageProperties)) {
    _setupListeners();
  }

  String get adapterId => 'page_property_adapter';

  String get adapterType => 'page';

  /// 当前页面属性
  Map<String, dynamic> get pageProperties => _pagePropertiesNotifier.value;

  /// 页面属性通知器，用于监听属性变化
  ValueListenable<Map<String, dynamic>> get pagePropertiesListenable =>
      _pagePropertiesNotifier;

  @override
  List<String> get supportedElementTypes => ['page']; // 只支持页面元素

  /// 构建面板UI
  Widget buildPanel(BuildContext context) {
    debugPrint('🏗️ PagePropertyAdapter.buildPanel() called');

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _pagePropertiesNotifier,
      builder: (context, pageProperties, child) {
        debugPrint('🔄 Page properties updated: ${pageProperties.keys}');

        return M3PracticePropertyPanelPage(
          // 页面尺寸
          pageWidth: (pageProperties['pageWidth'] as num?)?.toDouble() ?? 800.0,
          pageHeight:
              (pageProperties['pageHeight'] as num?)?.toDouble() ?? 600.0,

          // 页面方向
          orientation: _parseOrientation(pageProperties['orientation']),

          // DPI设置
          dpi: (pageProperties['dpi'] as num?)?.toDouble() ?? 150.0,

          // 背景设置
          backgroundColor:
              _parseColor(pageProperties['backgroundColor']) ?? Colors.white,
          backgroundImageUrl: pageProperties['backgroundImageUrl'] as String?,

          // 网格设置
          gridVisible: pageProperties['gridVisible'] as bool? ?? false,
          gridSize: (pageProperties['gridSize'] as num?)?.toDouble() ?? 20.0,
          gridColor:
              _parseColor(pageProperties['gridColor']) ?? Colors.grey.shade300,
          snapToGrid: pageProperties['snapToGrid'] as bool? ?? false,

          // 页面边距
          pageMargin:
              (pageProperties['pageMargin'] as num?)?.toDouble() ?? 20.0,

          // 回调函数
          onPageSizeChanged: _handlePageSizeChanged,
          onOrientationChanged: _handleOrientationChanged,
          onDpiChanged: _handleDpiChanged,
          onBackgroundColorChanged: _handleBackgroundColorChanged,
          onBackgroundImageChanged: _handleBackgroundImageChanged,
          onGridVisibilityChanged: _handleGridVisibilityChanged,
          onGridSizeChanged: _handleGridSizeChanged,
          onGridColorChanged: _handleGridColorChanged,
          onSnapToGridChanged: _handleSnapToGridChanged,
          onPageMarginChanged: _handlePageMarginChanged,
        );
      },
    );
  }

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    // 页面属性面板使用自定义UI
    return buildPanel(context);
  }

  void dispose() {
    debugPrint('🧹 PagePropertyAdapter.dispose() called');
    _pagePropertiesNotifier.dispose();
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    switch (propertyName) {
      case 'pageWidth':
        return 800.0;
      case 'pageHeight':
        return 600.0;
      case 'dpi':
        return 150.0;
      case 'backgroundColor':
        return '#FFFFFF';
      case 'gridVisible':
        return false;
      case 'gridSize':
        return 20.0;
      case 'gridColor':
        return '#E0E0E0';
      case 'snapToGrid':
        return false;
      case 'pageMargin':
        return 20.0;
      default:
        return null;
    }
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    return {
      'pageWidth': const PropertyDefinition(
        name: 'pageWidth',
        displayName: '页面宽度',
        type: PropertyType.number,
        defaultValue: 800.0,
        minValue: 100.0,
      ),
      'pageHeight': const PropertyDefinition(
        name: 'pageHeight',
        displayName: '页面高度',
        type: PropertyType.number,
        defaultValue: 600.0,
        minValue: 100.0,
      ),
      'dpi': const PropertyDefinition(
        name: 'dpi',
        displayName: '分辨率',
        type: PropertyType.number,
        defaultValue: 150.0,
        minValue: 72.0,
        maxValue: 600.0,
      ),
      'backgroundColor': const PropertyDefinition(
        name: 'backgroundColor',
        displayName: '背景颜色',
        type: PropertyType.color,
        defaultValue: '#FFFFFF',
      ),
      'gridVisible': const PropertyDefinition(
        name: 'gridVisible',
        displayName: '显示网格',
        type: PropertyType.boolean,
        defaultValue: false,
      ),
      'gridSize': const PropertyDefinition(
        name: 'gridSize',
        displayName: '网格大小',
        type: PropertyType.number,
        defaultValue: 20.0,
        minValue: 5.0,
        maxValue: 100.0,
      ),
    };
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is Map<String, dynamic>) {
      return element[propertyName];
    }
    return null;
  }

  void refresh() {
    debugPrint('🔄 PagePropertyAdapter.refresh() called');

    // 从 Canvas 状态获取最新的页面属性
    if (canvasController.stateManager != null) {
      final canvasState = canvasController.stateManager;

      // 获取画布配置或页面元素中的页面属性
      // 这里假设页面属性存储在特殊的页面配置中
      final updatedProperties = _extractPagePropertiesFromCanvas(canvasState);

      if (!_mapsAreEqual(_pagePropertiesNotifier.value, updatedProperties)) {
        _pagePropertiesNotifier.value = Map.from(updatedProperties);
        debugPrint('✅ Page properties refreshed from Canvas state');
      }
    }
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is String) {
      // element 是页面ID，更新页面属性
      _updatePageProperty(propertyName, value);
      _notifyCanvasOfPageChange();
    }
  }

  void updateFromSelection(List<String> selectedElementIds) {
    debugPrint(
        '🎯 PagePropertyAdapter.updateFromSelection() called with: $selectedElementIds');

    // 页面属性适配器不依赖于选中的元素
    // 但如果选中了页面级别的元素（如背景），可以在这里处理
    if (selectedElementIds.isEmpty) {
      // 没有选中元素时，显示页面属性
      refresh();
    }
  }

  /// 颜色转字符串
  String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// 从Canvas状态提取页面属性
  Map<String, dynamic> _extractPagePropertiesFromCanvas(dynamic canvasState) {
    // 这里需要根据实际的Canvas状态结构来实现
    // 目前返回默认值，需要在实际集成时完善
    return {
      'pageWidth': 800.0,
      'pageHeight': 600.0,
      'orientation': PageOrientation.portrait.toString(),
      'dpi': 150.0,
      'backgroundColor': '#FFFFFF',
      'backgroundImageUrl': null,
      'gridVisible': false,
      'gridSize': 20.0,
      'gridColor': '#E0E0E0',
      'snapToGrid': false,
      'pageMargin': 20.0,
    };
  }

  /// 处理背景颜色变化
  void _handleBackgroundColorChanged(Color color) {
    debugPrint('🎨 Background color changed: $color');
    _updatePageProperty('backgroundColor', _colorToString(color));
    _notifyCanvasOfPageChange();
  }

  /// 处理背景图片变化
  void _handleBackgroundImageChanged(String? imageUrl) {
    debugPrint('🖼️ Background image changed: $imageUrl');
    _updatePageProperty('backgroundImageUrl', imageUrl);
    _notifyCanvasOfPageChange();
  }

  /// 处理DPI变化
  void _handleDpiChanged(double dpi) {
    debugPrint('📐 DPI changed: $dpi');
    _updatePageProperty('dpi', dpi);
    _notifyCanvasOfPageChange();
  }

  /// 处理网格颜色变化
  void _handleGridColorChanged(Color color) {
    debugPrint('🔲 Grid color changed: $color');
    _updatePageProperty('gridColor', _colorToString(color));
    _notifyCanvasOfPageChange();
  }

  /// 处理网格大小变化
  void _handleGridSizeChanged(double size) {
    debugPrint('📏 Grid size changed: $size');
    _updatePageProperty('gridSize', size);
    _notifyCanvasOfPageChange();
  }

  /// 处理网格可见性变化
  void _handleGridVisibilityChanged(bool visible) {
    debugPrint('👁️ Grid visibility changed: $visible');
    _updatePageProperty('gridVisible', visible);
    _notifyCanvasOfPageChange();
  }

  /// 处理方向变化
  void _handleOrientationChanged(PageOrientation orientation) {
    debugPrint('🔄 Orientation changed: $orientation');
    _updatePageProperty('orientation', orientation.toString());

    // 交换宽度和高度
    final currentWidth = _pagePropertiesNotifier.value['pageWidth'] as double;
    final currentHeight = _pagePropertiesNotifier.value['pageHeight'] as double;

    _updatePageProperty('pageWidth', currentHeight);
    _updatePageProperty('pageHeight', currentWidth);

    _notifyCanvasOfPageChange();
  }

  /// 处理页面边距变化
  void _handlePageMarginChanged(double margin) {
    debugPrint('📄 Page margin changed: $margin');
    _updatePageProperty('pageMargin', margin);
    _notifyCanvasOfPageChange();
  }

  /// 处理页面尺寸变化
  void _handlePageSizeChanged(double width, double height) {
    debugPrint('📏 Page size changed: ${width}x$height');
    _updatePageProperty('pageWidth', width);
    _updatePageProperty('pageHeight', height);
    _notifyCanvasOfPageChange();
  }

  /// 处理网格吸附变化
  void _handleSnapToGridChanged(bool snap) {
    debugPrint('🧲 Snap to grid changed: $snap');
    _updatePageProperty('snapToGrid', snap);
    _notifyCanvasOfPageChange();
  }

  /// 比较两个Map是否相等
  bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }

    return true;
  }

  /// 通知Canvas页面属性变化
  void _notifyCanvasOfPageChange() {
    debugPrint('📢 Notifying Canvas of page property changes');

    // 这里可以通过CanvasController更新Canvas配置
    // 例如更新背景色、网格设置等

    // 调用外部回调
    onPagePropertiesChanged?.call();
  }

  /// Canvas控制器变化处理
  void _onCanvasControllerChanged() {
    debugPrint('🔄 Canvas controller changed, refreshing page properties');
    refresh();
  }

  /// 解析颜色字符串
  Color? _parseColor(dynamic colorValue) {
    if (colorValue == null) return null;

    if (colorValue is Color) return colorValue;

    if (colorValue is String) {
      try {
        // 处理 #RRGGBB 格式
        String colorString = colorValue;
        if (colorString.startsWith('#')) {
          colorString = colorString.substring(1);
        }

        if (colorString.length == 6) {
          return Color(int.parse('FF$colorString', radix: 16));
        } else if (colorString.length == 8) {
          return Color(int.parse(colorString, radix: 16));
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse color: $colorValue, error: $e');
      }
    }

    return null;
  }

  /// 解析页面方向
  PageOrientation _parseOrientation(dynamic orientationValue) {
    if (orientationValue == null) return PageOrientation.portrait;

    if (orientationValue is PageOrientation) return orientationValue;

    if (orientationValue is String) {
      switch (orientationValue.toLowerCase()) {
        case 'landscape':
        case 'pageorientation.landscape':
          return PageOrientation.landscape;
        case 'portrait':
        case 'pageorientation.portrait':
        default:
          return PageOrientation.portrait;
      }
    }

    return PageOrientation.portrait;
  }

  /// 设置监听器
  void _setupListeners() {
    debugPrint('🔗 Setting up PagePropertyAdapter listeners');

    // 监听Canvas控制器变化
    canvasController.addListener(_onCanvasControllerChanged);
  }

  /// 更新页面属性
  void _updatePageProperty(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(_pagePropertiesNotifier.value);
    updated[key] = value;
    _pagePropertiesNotifier.value = updated;
    debugPrint('✅ Page property updated: $key = $value');
  }
}
