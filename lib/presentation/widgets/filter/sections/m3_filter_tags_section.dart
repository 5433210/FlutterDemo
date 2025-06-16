import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的标签筛选部分组件
class M3FilterTagsSection extends StatefulWidget {
  /// 当前选中的标签列表
  final List<String> selectedTags;

  /// 推荐的常用标签列表
  final List<String> commonTags;

  /// 标签变化时的回调
  final ValueChanged<List<String>> onTagsChanged;

  /// 构造函数
  const M3FilterTagsSection({
    super.key,
    required this.selectedTags,
    required this.commonTags,
    required this.onTagsChanged,
  });

  @override
  State<M3FilterTagsSection> createState() => _M3FilterTagsSectionState();
}

class _M3FilterTagsSectionState extends State<M3FilterTagsSection> {
  final TextEditingController _tagController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tags,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),

        // 常用标签
        if (widget.commonTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.commonTags.map((tag) {
              final isSelected = widget.selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  _handleTagToggle(tag, selected);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
        ],

        // 自定义标签输入
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.addTag,
            hintText: l10n.tagsAddHint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCustomTag,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _addTag(value);
            }
          },
        ),

        // 已选标签
        if (widget.selectedTags.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingMedium),
          Text(
            l10n.tagsSelected,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
                deleteIcon: const Icon(Icons.close, size: 14),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addCustomTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty) {
      _addTag(tag);
      _tagController.clear();
    }
  }

  void _addTag(String tag) {
    if (!widget.selectedTags.contains(tag)) {
      final newTags = List<String>.from(widget.selectedTags)..add(tag);
      widget.onTagsChanged(newTags);
    }
  }

  void _handleTagToggle(String tag, bool selected) {
    if (selected) {
      _addTag(tag);
    } else {
      _removeTag(tag);
    }
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.selectedTags)
      ..removeWhere((t) => t == tag);
    widget.onTagsChanged(newTags);
  }
}
