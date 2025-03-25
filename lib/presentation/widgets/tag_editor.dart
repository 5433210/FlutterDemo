import 'package:flutter/material.dart';

class TagEditor extends StatefulWidget {
  final List<String> tags;
  final List<String> suggestedTags;
  final Function(List<String>) onTagsChanged;
  final Color? chipColor;
  final Color? textColor;
  final bool readOnly;

  const TagEditor({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.suggestedTags = const [],
    this.chipColor,
    this.textColor,
    this.readOnly = false,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show tag input when not in read-only mode
        if (!widget.readOnly) ...[
          // 标签输入
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: '输入标签后按Enter添加',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          _addTag(_controller.text);
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    _addTag(value);
                    _focusNode.requestFocus(); // 保持焦点
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],

        // Current tags display - always shown
        if (_tags.isEmpty && widget.readOnly)
          Text(
            '暂无标签',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(
                  tag,
                  style: TextStyle(color: widget.textColor),
                ),
                backgroundColor: widget.chipColor,
                // Only show delete icon when not in read-only mode
                deleteIcon:
                    widget.readOnly ? null : const Icon(Icons.close, size: 16),
                onDeleted: widget.readOnly ? null : () => _removeTag(tag),
              );
            }).toList(),
          ),

        // Only show suggested tags when not in read-only mode and there are suggestions
        if (!widget.readOnly && widget.suggestedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('建议标签:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // 建议标签
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
  void didUpdateWidget(covariant TagEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags) {
      setState(() {
        _tags = List.from(widget.tags);
      });
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
    if (widget.readOnly)
      return; // Safety check - don't add tags in readonly mode

    tag = tag.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _controller.clear();
      });
      widget.onTagsChanged(_tags);
    }
  }

  void _removeTag(String tag) {
    if (widget.readOnly)
      return; // Safety check - don't remove tags in readonly mode

    setState(() {
      _tags.remove(tag);
    });
    widget.onTagsChanged(_tags);
  }
}
