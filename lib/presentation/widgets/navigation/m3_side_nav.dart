import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../intents/navigation_intents.dart';

/// Material 3 风格的侧边导航栏
class M3NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;
  final VoidCallback onToggleExtended;

  const M3NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
    required this.onToggleExtended,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // 定义导航项
    final navItems = [
      _NavItem(
        index: 0,
        icon: Icons.image_outlined,
        selectedIcon: Icons.image,
        label: l10n.work,
      ),
      _NavItem(
        index: 1,
        icon: Icons.font_download_outlined,
        selectedIcon: Icons.font_download,
        label: l10n.characterCollection,
      ),
      _NavItem(
        index: 2,
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        label: l10n.practices,
      ),
      _NavItem(
        index: 3,
        icon: Icons.photo_library_outlined,
        selectedIcon: Icons.photo_library,
        label: l10n.libraryManagement,
      ),
      _NavItem(
        index: 4,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];

    // 创快捷键绑定
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
            const ActivateTabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
            const ActivateTabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3):
            const ActivateTabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4):
            const ActivateTabIntent(3),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit5):
            const ActivateTabIntent(4),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyN):
            const ToggleNavigationIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateTabIntent: CallbackAction<ActivateTabIntent>(
            onInvoke: (intent) {
              onDestinationSelected(intent.index);
              return null;
            },
          ),
          ToggleNavigationIntent: CallbackAction<ToggleNavigationIntent>(
            onInvoke: (intent) {
              onToggleExtended();
              return null;
            },
          ),
        },
        // 使用自定义的可滚动导航栏实现
        child: Container(
          width: extended ? 130 : 72,
          color: colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 展开/折叠按钮
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Tooltip(
                  message: extended
                      ? l10n.navCollapseSidebar
                      : l10n.navExpandSidebar,
                  child: IconButton(
                    icon: Icon(
                      extended ? Icons.chevron_left : Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleExtended,
                    focusNode: FocusNode(skipTraversal: false), // 允许键盘焦点
                  ),
                ),
              ),
              // 导航项列表（可滚动）
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: navItems.map((item) {
                      final isSelected = item.index == selectedIndex;
                      return _buildNavItem(
                        context: context,
                        item: item,
                        isSelected: isSelected,
                        extended: extended,
                        onTap: () => onDestinationSelected(item.index),
                        colorScheme: colorScheme,
                        theme: theme,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建导航项UI
  Widget _buildNavItem({
    required BuildContext context,
    required _NavItem item,
    required bool isSelected,
    required bool extended,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: extended ? 150 : 72,
        height: 40,
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (extended)
              Flexible(
                child: Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 导航项数据类
class _NavItem {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
