import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class FilterPanel extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final dynamic selectedValue;
  final ValueChanged<dynamic> onSelected;

  const FilterPanel({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.s),
        Wrap(
          spacing: AppSizes.s,
          runSpacing: AppSizes.xs,
          children: items.map((item) {
            final bool isSelected = item == selectedValue;
            return FilterChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const FilterSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          child,
        ],
      ),
    );
  }
}
