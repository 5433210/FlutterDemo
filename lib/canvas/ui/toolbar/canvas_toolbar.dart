/// Canvas工具栏组件 - 主工具栏
///
/// 职责：
/// 1. 显示工具按钮
/// 2. 处理工具选择事件
/// 3. 集成新的Canvas系统
/// 4. 提供现代化的UI体验
library;

import 'package:flutter/material.dart';

import '../../compatibility/canvas_state_adapter.dart';
import '../../core/canvas_state_manager.dart' as core;
import 'tool_state_manager.dart';
import 'widgets/tool_button.dart';
import 'widgets/tool_group.dart';

/// Canvas工具栏组件
class CanvasToolbar extends StatefulWidget {
  /// Canvas状态管理器 - 支持新旧两种状态管理器
  final dynamic stateManager;

  /// 工具状态管理器
  final ToolStateManager toolStateManager;

  /// 工具选择回调
  final Function(ToolType)? onToolSelected;

  /// 元素拖拽开始回调
  final Function(BuildContext, String)? onDragElementStart;

  /// 是否显示高级工具
  final bool showAdvancedTools;

  /// 工具栏方向
  final Axis direction;

  /// 工具栏样式
  final ToolbarStyle style;

  const CanvasToolbar({
    super.key,
    required this.stateManager,
    required this.toolStateManager,
    this.onToolSelected,
    this.onDragElementStart,
    this.showAdvancedTools = false,
    this.direction = Axis.horizontal,
    this.style = ToolbarStyle.modern,
  }) : assert(
          stateManager is core.CanvasStateManager ||
              stateManager is CanvasStateManagerAdapter,
          'stateManager must be a CanvasStateManager or CanvasStateManagerAdapter',
        );

  @override
  State<CanvasToolbar> createState() => _CanvasToolbarState();
}

/// 可拖拽的工具按钮
class DraggableToolButton extends StatelessWidget {
  final ToolType toolType;
  final bool isSelected;
  final VoidCallback onPressed;
  final Function(BuildContext, String)? onDragElementStart;
  final ToolbarStyle style;

  const DraggableToolButton({
    super.key,
    required this.toolType,
    required this.isSelected,
    required this.onPressed,
    this.onDragElementStart,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final child = ToolButton(
      toolType: toolType,
      isSelected: isSelected,
      onPressed: onPressed,
      style: style,
    );

    if (onDragElementStart == null) {
      return child;
    }

    return Draggable<String>(
      data: toolType.value,
      onDragStarted: () {
        onDragElementStart!(context, toolType.value);
      },
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            _getToolIcon(toolType),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 24.0,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      child: child,
    );
  }

  IconData _getToolIcon(ToolType toolType) {
    switch (toolType) {
      case ToolType.select:
        return Icons.select_all;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.image:
        return Icons.image;
      case ToolType.collection:
        return Icons.grid_on;
      case ToolType.move:
        return Icons.open_with;
      case ToolType.resize:
        return Icons.crop_free;
      case ToolType.rotate:
        return Icons.rotate_90_degrees_ccw;
      case ToolType.pan:
        return Icons.pan_tool;
      case ToolType.zoom:
        return Icons.zoom_in;
    }
  }
}

class _CanvasToolbarState extends State<CanvasToolbar> {
  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.horizontal
        ? _buildHorizontalToolbar()
        : _buildVerticalToolbar();
  }

  @override
  void dispose() {
    widget.toolStateManager.removeListener(_onToolStateChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.toolStateManager.addListener(_onToolStateChanged);
  }

  Widget _buildAdvancedToolGroup() {
    return ToolGroup(
      title: '高级工具',
      direction: widget.direction,
      children: [
        ToolButton(
          toolType: ToolType.move,
          isSelected: widget.toolStateManager.currentTool == ToolType.move,
          onPressed: () => _selectTool(ToolType.move),
          style: widget.style,
        ),
        ToolButton(
          toolType: ToolType.resize,
          isSelected: widget.toolStateManager.currentTool == ToolType.resize,
          onPressed: () => _selectTool(ToolType.resize),
          style: widget.style,
        ),
        ToolButton(
          toolType: ToolType.rotate,
          isSelected: widget.toolStateManager.currentTool == ToolType.rotate,
          onPressed: () => _selectTool(ToolType.rotate),
          style: widget.style,
        ),
      ],
    );
  }

  Widget _buildBasicToolGroup() {
    return ToolGroup(
      title: '基础工具',
      direction: widget.direction,
      children: [
        ToolButton(
          toolType: ToolType.select,
          isSelected: widget.toolStateManager.currentTool == ToolType.select,
          onPressed: () => _selectTool(ToolType.select),
          style: widget.style,
        ),
        ToolButton(
          toolType: ToolType.pan,
          isSelected: widget.toolStateManager.currentTool == ToolType.pan,
          onPressed: () => _selectTool(ToolType.pan),
          style: widget.style,
        ),
        ToolButton(
          toolType: ToolType.zoom,
          isSelected: widget.toolStateManager.currentTool == ToolType.zoom,
          onPressed: () => _selectTool(ToolType.zoom),
          style: widget.style,
        ),
      ],
    );
  }

  Widget _buildCreationToolGroup() {
    return ToolGroup(
      title: '创建元素',
      direction: widget.direction,
      children: [
        DraggableToolButton(
          toolType: ToolType.text,
          isSelected: widget.toolStateManager.currentTool == ToolType.text,
          onPressed: () => _selectTool(ToolType.text),
          onDragElementStart: widget.onDragElementStart,
          style: widget.style,
        ),
        DraggableToolButton(
          toolType: ToolType.image,
          isSelected: widget.toolStateManager.currentTool == ToolType.image,
          onPressed: () => _selectTool(ToolType.image),
          onDragElementStart: widget.onDragElementStart,
          style: widget.style,
        ),
        DraggableToolButton(
          toolType: ToolType.collection,
          isSelected:
              widget.toolStateManager.currentTool == ToolType.collection,
          onPressed: () => _selectTool(ToolType.collection),
          onDragElementStart: widget.onDragElementStart,
          style: widget.style,
        ),
      ],
    );
  }

  Widget _buildHorizontalDivider() {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 1,
      color: theme.colorScheme.outlineVariant,
    );
  }

  Widget _buildHorizontalToolbar() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildToolGroups(),
        ),
      ),
    );
  }

  List<Widget> _buildToolGroups() {
    final groups = <Widget>[];

    // 基础工具组
    groups.add(_buildBasicToolGroup());

    if (widget.direction == Axis.horizontal) {
      groups.add(const SizedBox(width: 16));
      groups.add(_buildVerticalDivider());
      groups.add(const SizedBox(width: 16));
    } else {
      groups.add(const SizedBox(height: 16));
      groups.add(_buildHorizontalDivider());
      groups.add(const SizedBox(height: 16));
    }

    // 元素创建工具组
    groups.add(_buildCreationToolGroup());

    // 高级工具组（如果启用）
    if (widget.showAdvancedTools) {
      if (widget.direction == Axis.horizontal) {
        groups.add(const SizedBox(width: 16));
        groups.add(_buildVerticalDivider());
        groups.add(const SizedBox(width: 16));
      } else {
        groups.add(const SizedBox(height: 16));
        groups.add(_buildHorizontalDivider());
        groups.add(const SizedBox(height: 16));
      }

      groups.add(_buildAdvancedToolGroup());
    }

    return groups;
  }

  Widget _buildVerticalDivider() {
    final theme = Theme.of(context);
    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant,
    );
  }

  Widget _buildVerticalToolbar() {
    final theme = Theme.of(context);

    return Container(
      width: 64,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildToolGroups(),
        ),
      ),
    );
  }

  void _onToolStateChanged() {
    setState(() {});
  }

  void _selectTool(ToolType toolType) {
    widget.toolStateManager.setTool(toolType);
    widget.onToolSelected?.call(toolType);
  }
}
