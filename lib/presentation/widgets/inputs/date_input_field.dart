import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateInputField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateFormat? format;
  final bool isRequired;
  final String? Function(DateTime?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;

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
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  late final DateFormat _format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<DateTime>(
      initialValue: widget.value,
      validator:
          widget.validator ?? (widget.isRequired ? _requiredValidator : null),
      builder: (FormFieldState<DateTime> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: field.errorText,
            suffixText: _hasFocus ? 'Enter 选择' : null,
            suffixIcon: Icon(
              Icons.calendar_today,
              color: _hasFocus ? theme.colorScheme.primary : null,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            filled: _hasFocus,
            fillColor: _hasFocus
                ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                : null,
          ),
          isEmpty: widget.value == null,
          isFocused: _hasFocus,
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space)) {
                _showDatePicker(context, field);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.tab) {
                if (widget.onEditingComplete != null) {
                  widget.onEditingComplete!();
                }
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: () => _showDatePicker(context, field),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DefaultTextStyle(
                  style: widget.value != null
                      ? theme.textTheme.bodyMedium!
                      : theme.textTheme.bodyMedium!.copyWith(
                          color: theme.hintColor,
                        ),
                  child: Text(
                    widget.value != null
                        ? _format.format(widget.value!)
                        : '选择日期',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
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
      widget.onChanged(picked);
    }

    // 选择完日期后继续 Tab 导航
    if (widget.onEditingComplete != null) {
      widget.onEditingComplete!();
    }
  }
}
