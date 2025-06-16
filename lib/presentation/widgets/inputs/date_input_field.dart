import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

/// A custom date input field with consistent styling
class DateInputField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final bool enabled;
  final bool readOnly;
  final TextStyle? textStyle; // Add this parameter for consistent styling

  const DateInputField({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.textInputAction,
    this.onEditingComplete,
    this.enabled = true,
    this.readOnly = false,
    this.textStyle, // Add this parameter to the constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle ?? theme.textTheme.bodyLarge;
    final readOnlyFillColor = theme.disabledColor.withValues(alpha: 0.05);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final displayText = value != null ? dateFormat.format(value!) : '';

    // Build read-only display with consistent styling
    if (readOnly) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: readOnlyFillColor,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          displayText,
          style: effectiveTextStyle, // Use the provided text style
        ),
      );
    }

    // Build editable field
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText:
            enabled ? AppLocalizations.of(context).selectDate : null,
        border: const OutlineInputBorder(),
        suffixIcon: enabled
            ? IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              )
            : null,
      ),
      readOnly: true, // Always read-only for the text field itself
      controller: TextEditingController(text: displayText),
      style: effectiveTextStyle, // Use the provided text style
      onTap: enabled ? () => _selectDate(context) : null,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && onChanged != null) {
      onChanged!(picked);
    }
  }
}
