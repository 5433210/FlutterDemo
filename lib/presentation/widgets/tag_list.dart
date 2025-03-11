import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_text_styles.dart';

class TagList extends StatelessWidget {
  final List<String> tags;
  final int? maxLines;
  final void Function(String)? onTagTap;

  const TagList({
    super.key,
    required this.tags,
    this.maxLines,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (maxLines == 1) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildTagRow(),
      );
    }

    return Wrap(
      spacing: AppSizes.p4,
      runSpacing: AppSizes.p4,
      children: tags.map(_buildTag).toList(),
    );
  }

  Widget _buildTag(String tag) {
    return InkWell(
      onTap: onTagTap != null ? () => onTagTap!(tag) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8,
          vertical: AppSizes.p4,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.r4),
        ),
        child: Text(
          '#$tag',
          style: AppTextStyles.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTagRow() {
    return Row(
      children: [
        for (var i = 0; i < tags.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSizes.p4),
          _buildTag(tags[i]),
        ],
      ],
    );
  }
}
