import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 图片操作确认对话框（当有字符提取时）
class ImageOperationConfirmDialog extends StatelessWidget {
  final String operation; // 操作类型：'rotation' 或 'deletion'
  final int characterCount; // 已提取的字符数量
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ImageOperationConfirmDialog({
    super.key,
    required this.operation,
    required this.characterCount,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    final String operationName = operation == 'rotation' ? '旋转' : '删除';
    final IconData operationIcon = operation == 'rotation' 
        ? Icons.rotate_right 
        : Icons.delete_outline;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.primary,
        size: 32,
      ),
      title: Text('$operationName图片确认'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '此图片已提取了 $characterCount 个字符。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '$operationName此图片将会删除对应的所有已提取字符，此操作不可撤销。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '确定要继续吗？',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          icon: Icon(operationIcon),
          label: Text('确定$operationName'),
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
        ),
      ],
    );
  }

  /// 显示旋转确认对话框
  static Future<bool?> showRotationConfirm(
    BuildContext context,
    int characterCount,
    VoidCallback onConfirm,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ImageOperationConfirmDialog(
        operation: 'rotation',
        characterCount: characterCount,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 显示删除确认对话框
  static Future<bool?> showDeletionConfirm(
    BuildContext context,
    int characterCount,
    VoidCallback onConfirm,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ImageOperationConfirmDialog(
        operation: 'deletion',
        characterCount: characterCount,
        onConfirm: onConfirm,
      ),
    );
  }
}