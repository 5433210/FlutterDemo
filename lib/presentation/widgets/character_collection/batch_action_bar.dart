import 'package:flutter/material.dart';

class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const BatchActionBar({
    Key? key,
    required this.selectedCount,
    required this.onExport,
    required this.onDelete,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 选中计数
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '已选择 $selectedCount 个字符',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // 导出按钮
          _BatchActionButton(
            icon: Icons.download,
            label: '导出',
            onPressed: onExport,
          ),

          const SizedBox(width: 8),

          // 删除按钮
          _BatchActionButton(
            icon: Icons.delete,
            label: '删除',
            color: Colors.red,
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),

          const SizedBox(width: 16),

          // 取消选择按钮
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('取消选择'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除这 $selectedCount 个字符吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _BatchActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _BatchActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: color,
      ),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
