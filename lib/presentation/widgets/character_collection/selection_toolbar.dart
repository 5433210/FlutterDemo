import 'package:flutter/material.dart';

class SelectionToolbar extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool enabled;

  const SelectionToolbar({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
    required this.onDelete,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: '确认 (Enter)',
              child: IconButton(
                icon: const Icon(Icons.check),
                onPressed: onConfirm,
                color: Colors.blue,
              ),
            ),
            Tooltip(
              message: '删除 (Delete)',
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red,
              ),
            ),
            Tooltip(
              message: '取消 (Esc)',
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
