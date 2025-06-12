import 'package:flutter/material.dart';

import '../alignment/alignment.dart';

/// 对齐模式选择器组件
///
/// 提供用户界面控件来切换不同的对齐模式：
/// - 无对齐模式：禁用所有自动对齐功能
/// - 网格对齐模式：元素对齐到网格点
/// - 参考线对齐模式：元素对齐到其他元素的参考线
class AlignmentModeSelector extends StatefulWidget {
  /// 当前选中的对齐模式
  final AlignmentMode currentMode;

  /// 对齐模式变化回调
  final ValueChanged<AlignmentMode> onModeChanged;

  /// 是否显示文本标签（默认为false，只显示图标）
  final bool showLabels;

  /// 组件方向（默认为水平）
  final Axis direction;

  const AlignmentModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.showLabels = false,
    this.direction = Axis.horizontal,
  });

  @override
  State<AlignmentModeSelector> createState() => _AlignmentModeSelectorState();
}

/// 快捷对齐模式切换按钮
///
/// 提供简单的图标按钮来快速切换对齐模式
class AlignmentModeToggle extends StatelessWidget {
  /// 当前对齐模式
  final AlignmentMode currentMode;

  /// 模式变化回调
  final ValueChanged<AlignmentMode> onModeChanged;

  /// 按钮大小
  final double? size;

  const AlignmentModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleMode,
      icon: Icon(_getCurrentIcon()),
      iconSize: size,
      tooltip: _getCurrentTooltip(),
    );
  }

  /// 获取当前模式的图标
  IconData _getCurrentIcon() {
    switch (currentMode) {
      case AlignmentMode.none:
        return Icons.clear;
      case AlignmentMode.grid:
        return Icons.grid_on;
      case AlignmentMode.guideLine:
        return Icons.straighten;
    }
  }

  /// 获取当前模式的提示文本
  String _getCurrentTooltip() {
    switch (currentMode) {
      case AlignmentMode.none:
        return '当前: 无对齐 (点击切换到网格对齐)';
      case AlignmentMode.grid:
        return '当前: 网格对齐 (点击切换到参考线对齐)';
      case AlignmentMode.guideLine:
        return '当前: 参考线对齐 (点击切换到无对齐)';
    }
  }

  /// 切换到下一个模式
  void _toggleMode() {
    const modes = AlignmentMode.values;
    final currentIndex = modes.indexOf(currentMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    onModeChanged(modes[nextIndex]);
  }
}

class _AlignmentModeSelectorState extends State<AlignmentModeSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.direction == Axis.horizontal) {
      return _buildHorizontalSelector();
    } else {
      return _buildVerticalSelector();
    }
  }

  /// 构建带标签的按钮
  Widget _buildButtonWithLabel(AlignmentMode mode, bool isSelected) {
    final theme = Theme.of(context);
    final color =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    if (widget.direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getModeIcon(mode), size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            _getModeLabel(mode),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getModeIcon(mode), size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            _getModeLabel(mode),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      );
    }
  }

  /// 构建水平布局的选择器
  Widget _buildHorizontalSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          AlignmentMode.values.map((mode) => _buildModeButton(mode)).toList(),
    );
  }

  /// 构建只有图标的按钮
  Widget _buildIconOnly(AlignmentMode mode, bool isSelected) {
    final theme = Theme.of(context);
    final color =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Icon(_getModeIcon(mode), size: 20, color: color);
  }

  /// 构建单个模式按钮
  Widget _buildModeButton(AlignmentMode mode) {
    final isSelected = widget.currentMode == mode;
    final theme = Theme.of(context);

    return Tooltip(
      message: _getModeTooltip(mode),
      child: InkWell(
        onTap: () => _handleModeChange(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary)
                : null,
          ),
          child: widget.showLabels
              ? _buildButtonWithLabel(mode, isSelected)
              : _buildIconOnly(mode, isSelected),
        ),
      ),
    );
  }

  /// 构建垂直布局的选择器
  Widget _buildVerticalSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          AlignmentMode.values.map((mode) => _buildModeButton(mode)).toList(),
    );
  }

  /// 获取模式图标
  IconData _getModeIcon(AlignmentMode mode) {
    switch (mode) {
      case AlignmentMode.none:
        return Icons.clear;
      case AlignmentMode.grid:
        return Icons.grid_on;
      case AlignmentMode.guideLine:
        return Icons.straighten;
    }
  }

  /// 获取模式标签
  String _getModeLabel(AlignmentMode mode) {
    switch (mode) {
      case AlignmentMode.none:
        return '无对齐';
      case AlignmentMode.grid:
        return '网格对齐';
      case AlignmentMode.guideLine:
        return '参考线对齐';
    }
  }

  /// 获取模式提示文本
  String _getModeTooltip(AlignmentMode mode) {
    switch (mode) {
      case AlignmentMode.none:
        return '禁用自动对齐';
      case AlignmentMode.grid:
        return '对齐到网格点';
      case AlignmentMode.guideLine:
        return '对齐到元素参考线';
    }
  }

  /// 处理模式变化
  void _handleModeChange(AlignmentMode mode) {
    if (widget.currentMode != mode) {
      widget.onModeChanged(mode);
    }
  }
}
