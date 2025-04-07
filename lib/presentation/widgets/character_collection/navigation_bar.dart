import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';

class CharacterNavigationBar extends ConsumerWidget {
  final String workId;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const CharacterNavigationBar({
    Key? key,
    required this.workId,
    required this.onBack,
    this.onHelp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collectionState = ref.watch(characterCollectionProvider);

    // 计算状态信息文本
    String statusText = '';
    if (collectionState.processing) {
      statusText = '处理中...';
    } else if (collectionState.error != null) {
      statusText = '错误：${collectionState.error}';
    } else if (collectionState.selectedIds.isNotEmpty) {
      statusText = '已选择 ${collectionState.selectedIds.length} 个字符';
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
            onPressed: () {
              onBack();
            },
          ),

          const SizedBox(width: 16),

          // 标题
          Text(
            '集字功能',
            style: theme.textTheme.titleLarge,
          ),

          // 状态文本（条件显示）
          if (statusText.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: collectionState.error != null
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: collectionState.error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],

          const Spacer(),

          // 帮助按钮
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '帮助',
            onPressed: onHelp ?? _showHelpDialog,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    // 显示帮助对话框，具体实现可以添加在此处
  }

  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBack();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('放弃更改'),
          ),
        ],
      ),
    );
  }
}
