import 'package:flutter/material.dart';

class DropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final Widget Function(T)? itemBuilder;
  final String? hint;
  final bool isExpanded;
  final bool isDense;

  const DropdownField({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.itemBuilder,
    this.hint,
    this.isExpanded = true,
    this.isDense = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder?.call(item) ?? Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      hint: hint != null ? Text(hint!) : null,
      isExpanded: isExpanded,
      isDense: isDense,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}