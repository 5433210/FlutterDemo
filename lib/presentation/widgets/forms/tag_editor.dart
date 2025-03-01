import 'package:flutter/material.dart';

class TagEditor extends StatefulWidget {
  final List<String> tags;
  final List<String> suggestedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final Color? chipColor;
  final Color? textColor;

  const TagEditor({
    super.key,
    required this.tags,
    this.suggestedTags = const [],
    required this.onTagsChanged,
    this.chipColor,
    this.textColor,
  });

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 现有标签显示
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: widget.textColor ?? theme.colorScheme.onSurface,
                  ),
                ),
                backgroundColor: widget.chipColor ?? theme.colorScheme.surface,
                deleteIconColor:
                    widget.textColor ?? theme.colorScheme.onSurface,
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),

        const SizedBox(height: 8),

        // 添加新标签的输入框
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: '输入新标签...',
                  isDense: true,
                ),
                onSubmitted: _addTag,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_controller.text),
              tooltip: '添加标签',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 常用标签建议
        if (widget.suggestedTags.isNotEmpty) ...[
          const Text('常用标签:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.suggestedTags
                .where((tag) => !_tags.contains(tag))
                .map((tag) {
              return ActionChip(
                label: Text(tag),
                onPressed: () => _addTag(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  void didUpdateWidget(TagEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tags != widget.tags) {
      _tags = List.from(widget.tags);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  void _addTag(String tag) {
    if (tag.isEmpty) return;

    // 移除前后空格
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;

    // 检查标签是否已存在
    if (_tags.contains(trimmedTag)) return;

    setState(() {
      _tags.add(trimmedTag);
      _controller.clear();
      widget.onTagsChanged(_tags);
    });

    // 保持焦点在输入框
    _focusNode.requestFocus();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.onTagsChanged(_tags);
    });
  }
}
