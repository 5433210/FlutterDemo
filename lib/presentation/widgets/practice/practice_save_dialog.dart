import 'package:flutter/material.dart';

/// 字帖覆盖确认对话框
class PracticeOverwriteConfirmDialog extends StatelessWidget {
  /// 要覆盖的字帖标题
  final String title;

  const PracticeOverwriteConfirmDialog({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('字帖已存在'),
      content: Text('已存在标题为"$title"的字帖，是否覆盖保存？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('覆盖'),
        ),
      ],
    );
  }
}

/// 字帖保存对话框
/// 用于输入字帖标题
class PracticeSaveDialog extends StatefulWidget {
  /// 初始标题
  final String? initialTitle;

  /// 标题提示文本
  final String hintText;

  /// 对话框标题
  final String title;

  /// 确认按钮文本
  final String confirmText;

  /// 构造函数
  const PracticeSaveDialog({
    Key? key,
    this.initialTitle,
    this.hintText = '请输入字帖标题',
    this.title = '保存字帖',
    this.confirmText = '保存',
  }) : super(key: key);

  @override
  State<PracticeSaveDialog> createState() => _PracticeSaveDialogState();
}

class _PracticeSaveDialogState extends State<PracticeSaveDialog> {
  late final TextEditingController _titleController;
  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: _isValid ? (_) => _confirm() : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isValid ? _confirm : null,
          child: Text(widget.confirmText),
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
    _titleController = TextEditingController(text: widget.initialTitle);
    _isValid = widget.initialTitle?.isNotEmpty ?? false;

    // 监听输入变化以验证
    _titleController.addListener(_validateInput);
  }

  /// 确认操作
  void _confirm() {
    Navigator.of(context).pop(_titleController.text.trim());
  }

  /// 验证输入
  void _validateInput() {
    final isValid = _titleController.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }
}
