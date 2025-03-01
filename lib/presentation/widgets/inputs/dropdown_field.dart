import 'package:flutter/material.dart';

class DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isRequired;
  final String? Function(T?)? validator;
  final String? hintText;

  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.validator,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<T>(
      initialValue: value,
      validator: validator ?? (isRequired ? _requiredValidator : null),
      builder: (FormFieldState<T> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
          ),
          isEmpty: value == null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              hint: hintText != null ? Text(hintText!) : null,
              onChanged: (newValue) {
                field.didChange(newValue);
                onChanged(newValue);
              },
              items: items,
            ),
          ),
        );
      },
    );
  }

  String? _requiredValidator(T? value) {
    if (value == null) {
      return '请选择$label';
    }
    return null;
  }
}
