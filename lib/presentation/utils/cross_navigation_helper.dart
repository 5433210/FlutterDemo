import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/navigation/navigation_history_item.dart';
import '../providers/navigation/global_navigation_provider.dart';

/// 处理跨区域返回导航
class CrossNavigationHelper {
  /// 获取当前导航位置的可读描述
  static String getNavigationDescription(BuildContext context, int sectionIndex,
      {String? routePath}) {
    final sectionName = sectionNames[sectionIndex] ?? '未知区域';
    if (routePath == null || routePath == '/') {
      return sectionName;
    }
    return '$sectionName > ${_getReadableRouteName(routePath)}';
  }

  /// 处理返回按钮点击
  /// 如果当前导航区域有可返回的页面，则返回
  /// 如果当前导航区域没有可返回的页面，则显示对话框询问用户是否要返回到之前的功能区
  static Future<void> handleBackNavigation(
    BuildContext context,
    WidgetRef ref, {
    bool showDialog = true,
  }) async {
    // 尝试在当前导航区域内返回
    final canPop = await Navigator.of(context, rootNavigator: false).maybePop();

    // 如果当前导航区域无法返回，尝试返回到上一个功能区
    if (!canPop) {
      // 获取最近的历史记录
      final navNotifier = ref.read(globalNavigationProvider.notifier);
      final recentHistory = navNotifier.getRecentHistory(limit: 3);

      if (recentHistory.isEmpty) {
        // 没有历史记录，显示提示
        if (showDialog && context.mounted) {
          await _showNoHistoryDialog(context);
        }
        return;
      }

      if (showDialog && context.mounted) {
        // 有历史记录，显示导航选项
        final selectedIndex = await _showNavigationOptionsDialog(
          context,
          recentHistory,
        );
        if (selectedIndex != null && context.mounted) {
          // 用户选择了特定的历史项
          final selectedItem = recentHistory[selectedIndex];
          await navNotifier.navigateToHistoryItem(selectedItem);
        }
      } else {
        // 直接返回，不显示对话框
        await navNotifier.navigateBack();
      }
    }
  }

  /// 将路由路径转换为可读的名称
  static String _getReadableRouteName(String routePath) {
    // 移除开头的斜杠
    var name = routePath.startsWith('/') ? routePath.substring(1) : routePath;
    // 将下划线替换为空格
    name = name.replaceAll('_', ' ');
    // 将每个单词首字母大写
    name = name.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return word;
    }).join(' ');
    return name;
  }

  /// 获取功能区图标
  static IconData _getSectionIcon(int sectionIndex) {
    switch (sectionIndex) {
      case 0:
        return Icons.image_outlined;
      case 1:
        return Icons.text_fields_outlined;
      case 2:
        return Icons.article_outlined;
      case 3:
        return Icons.photo_library_outlined;
      case 4:
        return Icons.settings_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// 显示导航选项对话框
  static Future<int?> _showNavigationOptionsDialog(
    BuildContext context,
    List<NavigationHistoryItem> history,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('返回到之前的页面'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '您想返回到以下哪个页面？',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(history.length, (index) {
              final item = history[index];
              final sectionName = sectionNames[item.sectionIndex] ?? '未知区域';
              final subtitle = item.routePath != null
                  ? _getReadableRouteName(item.routePath!)
                  : null;

              return ListTile(
                leading: Icon(
                  _getSectionIcon(item.sectionIndex),
                  color: colorScheme.primary,
                ),
                title: Text(
                  sectionName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: subtitle != null
                    ? Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                tileColor: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () {
                  // 返回选中的历史项索引
                  Navigator.of(context).pop(index);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示无历史记录对话框
  static Future<void> _showNoHistoryDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('无法返回'),
        content: const Text('已经到达当前功能区的最开始页面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
