import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInputField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateFormat format;
  final bool isRequired;
  final String? Function(DateTime?)? validator;

  DateInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    DateFormat? format,
    this.isRequired = false,
    this.validator,
  }) : format = format ?? DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<DateTime>(
      initialValue: value,
      validator: validator ?? (isRequired ? _requiredValidator : null),
      builder: (FormFieldState<DateTime> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: GestureDetector(
            onTap: () => _showDatePicker(context, field),
            child: Text(
              value != null ? format.format(value!) : '选择日期',
              style: value != null
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
            ),
          ),
        );
      },
    );
  }

  String? _requiredValidator(DateTime? value) {
    if (value == null) {
      return '请选择$label';
    }
    return null;
  }

  Future<void> _showDatePicker(
      BuildContext context, FormFieldState<DateTime> field) async {
    final initialDate = value ?? DateTime.now();
    final firstDate = DateTime(1000); // 支持古代作品
    final lastDate = DateTime.now().add(const Duration(days: 365)); // 允许未来一年

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != value) {
      field.didChange(picked);
      onChanged(picked);
    }
  }
}
