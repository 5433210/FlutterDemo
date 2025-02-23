import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';
import '../section_header.dart';

class FilterPanel extends StatelessWidget {
  final List<FilterSection> sections;
  final VoidCallback? onReset;

  const FilterPanel({
    super.key,
    required this.sections,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '筛选',
            actions: [
              if (onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: AppSizes.iconSmall),
                  label: const Text('重置'),
                ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: sections.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => sections[index],
            ),
          ),
        ],
      ),
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
