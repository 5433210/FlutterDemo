/// Canvas属性面板通用组件 - Phase 2.2
///
/// 职责：
/// 1. 提供通用的属性编辑组件
/// 2. 统一的UI风格和交互
/// 3. 性能优化的输入组件
/// 4. 批量编辑支持
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../property_panel.dart';

/// 批量编辑状态指示器
class BatchEditIndicator extends StatelessWidget {
  final bool isActive;
  final int itemCount;
  final VoidCallback? onClear;

  const BatchEditIndicator({
    super.key,
    required this.isActive,
    required this.itemCount,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit,
            size: 16,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '批量编辑 ($itemCount 项)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onClear,
              child: Icon(
                Icons.close,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 属性卡片容器
class PropertyCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final PropertyPanelStyle style;
  final bool isExpanded;
  final VoidCallback? onExpandChanged;
  final List<Widget>? actions;

  const PropertyCard({
    super.key,
    this.title,
    required this.child,
    this.style = PropertyPanelStyle.modern,
    this.isExpanded = true,
    this.onExpandChanged,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (style) {
      case PropertyPanelStyle.modern:
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: _buildContent(context),
        );
      case PropertyPanelStyle.compact:
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: _buildContent(context),
        );
      case PropertyPanelStyle.classic:
        return Card(
          elevation: 2,
          child: _buildContent(context),
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (title == null) {
      return Padding(
        padding: _getPadding(),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          InkWell(
            onTap: onExpandChanged,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: style == PropertyPanelStyle.compact ? 12 : 16,
                vertical: style == PropertyPanelStyle.compact ? 8 : 12,
              ),
              child: Row(
                children: [
                  if (onExpandChanged != null)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  if (onExpandChanged != null) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        if (isExpanded)
          Padding(
            padding: _getPadding(),
            child: child,
          ),
      ],
    );
  }

  EdgeInsets _getPadding() {
    switch (style) {
      case PropertyPanelStyle.modern:
        return const EdgeInsets.fromLTRB(16, 0, 16, 16);
      case PropertyPanelStyle.compact:
        return const EdgeInsets.fromLTRB(12, 0, 12, 12);
      case PropertyPanelStyle.classic:
        return const EdgeInsets.all(16);
    }
  }
}

/// 颜色选择字段
class PropertyColorField extends StatelessWidget {
  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;
  final bool enabled;

  const PropertyColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: enabled ? () => _showColorPicker(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: value,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? colorScheme.outline
                    : colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child:
                enabled ? const Icon(Icons.palette, color: Colors.white) : null,
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    // TODO: 实现颜色选择器
    // 这里可以集成第三方颜色选择器包
  }
}

/// 下拉选择字段
class PropertyDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T)? itemBuilder;
  final bool enabled;

  const PropertyDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder?.call(item) ?? item.toString()),
            );
          }).toList(),
          onChanged: enabled
              ? (T? newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                }
              : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

/// 数字输入字段 - 支持批量编辑和性能优化
class PropertyNumberField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double? min;
  final double? max;
  final String? suffix;
  final int? decimalPlaces;
  final bool enabled;

  const PropertyNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.suffix,
    this.decimalPlaces = 1,
    this.enabled = true,
  });

  @override
  State<PropertyNumberField> createState() => _PropertyNumberFieldState();
}

/// 属性分组
class PropertySection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final PropertyPanelStyle style;
  final bool isExpanded;
  final VoidCallback? onExpandChanged;

  const PropertySection({
    super.key,
    required this.title,
    required this.children,
    this.style = PropertyPanelStyle.modern,
    this.isExpanded = true,
    this.onExpandChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyCard(
      title: title,
      style: style,
      isExpanded: isExpanded,
      onExpandChanged: onExpandChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// 滑块控制字段
class PropertySlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String? suffix;
  final bool showValue;
  final bool enabled;

  const PropertySlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.suffix,
    this.showValue = true,
    this.enabled = true,
  });

  @override
  State<PropertySlider> createState() => _PropertySliderState();
}

/// 开关控制字段
class PropertySwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;
  final bool enabled;

  const PropertySwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (description != null)
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: colorScheme.primary,
        ),
      ],
    );
  }
}

/// 文本输入字段
class PropertyTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool enabled;
  final int? maxLines;

  const PropertyTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<PropertyTextField> createState() => _PropertyTextFieldState();
}

class _PropertyNumberFieldState extends State<PropertyNumberField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  double? _pendingValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?[\d.]*')),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixText: widget.suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
          ),
          onChanged: _onTextChanged,
          onSubmitted: (_) => _commitValue(),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(PropertyNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _updateController();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _updateController();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitValue();
      }
    });
  }

  void _commitValue() {
    if (_pendingValue != null) {
      var value = _pendingValue!;

      // 应用范围限制
      if (widget.min != null) value = value.clamp(widget.min!, double.infinity);
      if (widget.max != null)
        value = value.clamp(double.negativeInfinity, widget.max!);

      widget.onChanged(value);
      _pendingValue = null;
    }
  }

  void _onTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null) {
      _pendingValue = parsed;

      // 防抖处理
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _commitValue();
      });
    }
  }

  void _updateController() {
    final text = widget.decimalPlaces == 0
        ? widget.value.round().toString()
        : widget.value.toStringAsFixed(widget.decimalPlaces!);

    if (_controller.text != text) {
      _controller.text = text;
    }
  }
}

class _PropertySliderState extends State<PropertySlider> {
  Timer? _debounceTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.showValue)
              Text(
                '${widget.value.toStringAsFixed(1)}${widget.suffix ?? ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        Slider(
          value: widget.value.clamp(widget.min, widget.max),
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          onChanged: widget.enabled ? _onChanged : null,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.outline.withOpacity(0.3),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(double value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      widget.onChanged(value);
    });
  }
}

class _PropertyTextFieldState extends State<PropertyTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
          ),
          onChanged: _onTextChanged,
          onSubmitted: widget.onChanged,
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(PropertyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onChanged(_controller.text);
      }
    });
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(text);
    });
  }
}
