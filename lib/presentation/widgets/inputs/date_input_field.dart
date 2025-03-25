import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInputField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateFormat? format;
  final bool isRequired;
  final String? Function(DateTime?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final bool enabled;
  final bool readOnly; // 新增只读模式参数

  const DateInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.format,
    this.isRequired = false,
    this.validator,
    this.textInputAction,
    this.onEditingComplete,
    this.enabled = true,
    this.readOnly = false, // 默认非只读
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  late final DateFormat _format;
  final _textController = TextEditingController(); // 用于只读模式显示日期的控制器

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        widget.value != null ? _format.format(widget.value!) : '';

    // 更新控制器文本
    if (_textController.text != formattedDate) {
      _textController.text = formattedDate;
    }

    final readOnlyFillColor = theme.disabledColor.withOpacity(0.05);

    // 只读模式使用TextFormField
    if (widget.readOnly) {
      return TextFormField(
        controller: _textController,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(
            Icons.calendar_today,
            size: 20,
            color: theme.disabledColor,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          filled: true,
          fillColor: readOnlyFillColor,
          // 不显示提示文本
          hintText: null,
        ),
        enabled: true, // 启用但不可编辑
        readOnly: true,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color), // 使用普通文本颜色
      );
    }

    // 互动模式
    return FormField<DateTime>(
      initialValue: widget.value,
      validator:
          widget.validator ?? (widget.isRequired ? _requiredValidator : null),
      builder: (FormFieldState<DateTime> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap:
                  widget.enabled ? () => _showDatePicker(context, field) : null,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.label,
                  errorText: field.errorText,
                  border: const OutlineInputBorder(),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: widget.enabled
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                ),
                isEmpty: formattedDate.isEmpty,
                child: Text(
                  formattedDate.isEmpty ? '' : formattedDate,
                  style: widget.enabled
                      ? null
                      : TextStyle(color: theme.disabledColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateTextController();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _textController.dispose(); // 释放控制器资源
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _format = widget.format ?? DateFormat('yyyy-MM-dd');
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  String? _requiredValidator(DateTime? value) {
    if (widget.isRequired && value == null) {
      return '请选择${widget.label}';
    }
    return null;
  }

  Future<void> _showDatePicker(
      BuildContext context, FormFieldState<DateTime> field) async {
    if (!widget.enabled || widget.onChanged == null) return;

    final initialDate = widget.value ?? DateTime.now();
    final firstDate = DateTime(1000); // 支持古代作品
    final lastDate = DateTime.now().add(const Duration(days: 365)); // 允许未来一年

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != widget.value) {
      field.didChange(picked);
      widget.onChanged!(picked);
    }

    // 选择完日期后继续 Tab 导航
    if (widget.onEditingComplete != null) {
      widget.onEditingComplete!();
    }
  }

  void _updateTextController() {
    final formattedDate =
        widget.value != null ? _format.format(widget.value!) : '';
    if (_textController.text != formattedDate) {
      _textController.text = formattedDate;
    }
  }
}
