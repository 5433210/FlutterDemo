import 'package:flutter/material.dart';

/// 字帖标题输入对话框
class PracticeTitleDialog extends StatefulWidget {
  final String? initialTitle;
  final String title;
  final String message;
  final String confirmButtonText;

  const PracticeTitleDialog({
    super.key,
    this.initialTitle,
    this.title = '保存字帖',
    this.message = '请输入字帖标题:',
    this.confirmButtonText = '保存',
  });

  @override
  State<PracticeTitleDialog> createState() => _PracticeTitleDialogState();

  /// 显示标题输入对话框
  static Future<String?> show(
    BuildContext context, {
    String? initialTitle,
    String title = '保存字帖',
    String message = '请输入字帖标题:',
    String confirmButtonText = '保存',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => PracticeTitleDialog(
        initialTitle: initialTitle,
        title: title,
        message: message,
        confirmButtonText: confirmButtonText,
      ),
    );
  }
}

class _PracticeTitleDialogState extends State<PracticeTitleDialog> {
  late final TextEditingController _controller;
  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入标题',
            ),
            autofocus: true,
            onSubmitted: _isValid
                ? (_) => Navigator.of(context).pop(_controller.text)
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_controller.text)
              : null,
          child: Text(widget.confirmButtonText),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _isValid = _controller.text.isNotEmpty;

    _controller.addListener(() {
      final isValid = _controller.text.isNotEmpty;
      if (isValid != _isValid) {
        setState(() {
          _isValid = isValid;
        });
      }
    });
  }
}
