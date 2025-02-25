import 'package:flutter/material.dart';

class FilterChipGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const FilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: option == selected,
              onSelected: (value) => onSelected(value ? option : null),
            );
          }).toList(),
        ),
      ],
    );
  }
}
