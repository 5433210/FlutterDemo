import 'package:flutter/material.dart';

/// 字帖保存对话框
/// 用于输入字帖标题
class PracticeSaveDialog extends StatefulWidget {
  /// 初始标题
  final String? initialTitle;

  /// 是否为另存为操作
  final bool isSaveAs;

  /// 检查标题是否存在的回调
  final Future<bool> Function(String title)? checkTitleExists;

  const PracticeSaveDialog({
    super.key,
    this.initialTitle,
    this.isSaveAs = false,
    this.checkTitleExists,
  });

  @override
  State<PracticeSaveDialog> createState() => _PracticeSaveDialogState();
}

class _PracticeSaveDialogState extends State<PracticeSaveDialog> {
  late final TextEditingController _titleController;
  String? _errorText;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.isSaveAs ? '另存为' : '保存字帖';

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '字帖标题',
              hintText: '请输入字帖标题',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (_) {
              // 清除错误提示
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            if (await _validateTitle()) {
              Navigator.of(context).pop(_titleController.text.trim());
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  /// 验证标题
  Future<bool> _validateTitle() async {
    final title = _titleController.text.trim();

    // 检查标题是否为空
    if (title.isEmpty) {
      setState(() {
        _errorText = '标题不能为空';
      });
      return false;
    }

    // 检查标题是否已存在
    if (widget.checkTitleExists != null) {
      setState(() {
        _isChecking = true;
        _errorText = null;
      });

      try {
        final exists = await widget.checkTitleExists!(title);

        // 如果是另存为操作，标题已存在且非本身的标题，显示错误
        if (exists && (widget.isSaveAs || title != widget.initialTitle)) {
          setState(() {
            _errorText = '已存在相同标题的字帖，请使用其他标题';
          });
          return false;
        }

        return true;
      } finally {
        setState(() {
          _isChecking = false;
        });
      }
    }

    return true;
  }
}
