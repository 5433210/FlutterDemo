import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool?> showSaveConfirmationDialog(
  BuildContext context, {
  required String character,
  Widget? previewWidget,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // 防止误触背景关闭
    useRootNavigator: false, // 使用最近的导航器以提高性能
    builder: (context) => SaveConfirmationDialog(
      character: character,
      showPreview: previewWidget != null,
      previewWidget: previewWidget,
      onConfirm: () async {
        // 立即关闭对话框
        Navigator.of(context).pop(true);
      },
      onCancel: () {
        Navigator.of(context).pop(false);
      },
    ),
  );
}

class SaveConfirmationDialog extends StatefulWidget {
  final String character;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showPreview;
  final Widget? previewWidget;

  const SaveConfirmationDialog({
    super.key,
    required this.character,
    required this.onConfirm,
    required this.onCancel,
    this.showPreview = false,
    this.previewWidget,
  });

  @override
  State<SaveConfirmationDialog> createState() => _SaveConfirmationDialogState();
}

class _SaveConfirmationDialogState extends State<SaveConfirmationDialog> {
  // 创建一个专用的FocusNode
  final FocusNode _dialogFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _dialogFocusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        _handleKeyEvent(event);
      },
      child: AlertDialog(
        title: const Text('确认保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要保存汉字"${widget.character}"吗？'),
            const SizedBox(height: 8),
            const Text('提示: 按 Enter 确认，Esc 取消',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (widget.showPreview && widget.previewWidget != null) ...[
              const SizedBox(height: 16),
              const Text('预览效果：'),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                height: 200,
                child: widget.previewWidget!,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: widget.onConfirm,
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 释放资源
    _dialogFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 在初始化后强制聚焦到对话框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dialogFocusNode.requestFocus();
      }
    });
  }

  // 处理键盘事件的方法
  bool _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        widget.onConfirm();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onCancel();
        return true;
      }
    }
    return false;
  }
}
