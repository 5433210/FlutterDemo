/// Canvas属性面板系统 - Phase 2.2
///
/// 职责：
/// 1. 统一的属性编辑接口
/// 2. 实时属性同步
/// 3. 批量编辑支持
/// 4. 性能优化的属性绑定
library;

import 'package:flutter/material.dart';

import '../../core/canvas_state_manager.dart';
import 'property_panel_controller.dart';
import 'widgets/element_property_panel.dart';
import 'widgets/multi_selection_property_panel.dart';
import 'widgets/page_property_panel.dart';

/// Canvas属性面板主组件
class CanvasPropertyPanel extends StatefulWidget {
  final CanvasStateManager stateManager;
  final PropertyPanelController? controller;
  final PropertyPanelStyle style;
  final Function(String, Map<String, dynamic>)? onElementPropertyChanged;
  final Function(Map<String, dynamic>)? onPagePropertyChanged;

  const CanvasPropertyPanel({
    super.key,
    required this.stateManager,
    this.controller,
    this.style = PropertyPanelStyle.modern,
    this.onElementPropertyChanged,
    this.onPagePropertyChanged,
  });

  @override
  State<CanvasPropertyPanel> createState() => _CanvasPropertyPanelState();
}

/// 属性变更事件
class PropertyChangeEvent {
  final String targetId;
  final String targetType; // 'element', 'layer', 'page'
  final Map<String, dynamic> properties;
  final Map<String, dynamic>? previousProperties;
  final DateTime timestamp;

  const PropertyChangeEvent({
    required this.targetId,
    required this.targetType,
    required this.properties,
    this.previousProperties,
    required this.timestamp,
  });
}

/// 属性面板配置
class PropertyPanelConfig {
  final bool showAdvancedProperties;
  final bool enableBatchEditing;
  final bool enableRealTimeUpdate;
  final Duration debounceDelay;
  final bool showPropertyHistory;

  const PropertyPanelConfig({
    this.showAdvancedProperties = true,
    this.enableBatchEditing = true,
    this.enableRealTimeUpdate = true,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.showPropertyHistory = false,
  });
}

/// 属性面板样式枚举
enum PropertyPanelStyle {
  /// 现代样式 - 卡片布局
  modern,

  /// 紧凑样式 - 列表布局
  compact,

  /// 经典样式 - 分组布局
  classic,
}

/// 属性面板主题
class PropertyPanelTheme {
  final Color backgroundColor;
  final Color cardColor;
  final Color primaryColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;

  const PropertyPanelTheme({
    required this.backgroundColor,
    required this.cardColor,
    required this.primaryColor,
    required this.textColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  factory PropertyPanelTheme.fromColorScheme(ColorScheme colorScheme) {
    return PropertyPanelTheme(
      backgroundColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerHigh,
      primaryColor: colorScheme.primary,
      textColor: colorScheme.onSurface,
    );
  }
}

class _CanvasPropertyPanelState extends State<CanvasPropertyPanel> {
  late PropertyPanelController _controller;

  @override
  Widget build(BuildContext context) {
    return _buildPropertyPanelContent();
  }

  @override
  void dispose() {
    widget.stateManager.removeListener(_onStateChanged);

    // 只有自己创建的控制器才需要释放
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        PropertyPanelController(
          stateManager: widget.stateManager,
        );

    // 监听状态变化
    widget.stateManager.addListener(_onStateChanged);
  }

  /// 构建属性面板内容
  Widget _buildPropertyPanelContent() {
    final selectedIds = widget.stateManager.selectionState.selectedIds;

    // 多选状态
    if (selectedIds.length > 1) {
      return MultiSelectionPropertyPanel(
        stateManager: widget.stateManager,
        controller: _controller,
        selectedElementIds: selectedIds.toList(),
        style: widget.style,
        onPropertyChanged: _onElementPropertyChanged,
      );
    }

    // 单个元素选中
    if (selectedIds.length == 1) {
      final element =
          widget.stateManager.elementState.getElementById(selectedIds.first);
      if (element != null) {
        return ElementPropertyPanel(
          stateManager: widget.stateManager,
          controller: _controller,
          element: element,
          style: widget.style,
          onPropertyChanged: _onElementPropertyChanged,
        );
      }
    }

    // 默认显示页面属性
    return PagePropertyPanel(
      stateManager: widget.stateManager,
      controller: _controller,
      style: widget.style,
      onPropertyChanged: _onPagePropertyChanged,
    );
  }

  /// 元素属性变更处理
  void _onElementPropertyChanged(
      String elementId, Map<String, dynamic> properties) {
    // 批量更新属性
    _controller.updateElementProperties(elementId, properties);

    // 回调通知
    widget.onElementPropertyChanged?.call(elementId, properties);
  }

  /// 页面属性变更处理
  void _onPagePropertyChanged(Map<String, dynamic> properties) {
    // 回调通知
    widget.onPagePropertyChanged?.call(properties);
  }

  /// 状态变更处理
  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
