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

    // 创建快捷键绑定
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
        child: NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          extended: extended,
          backgroundColor: colorScheme.surface,
          useIndicator: true,
          minWidth: 72, // 设置最小宽度以确保点击区域足够大
          minExtendedWidth: 200, // 设置展开时的最小宽度
          indicatorColor: colorScheme.secondaryContainer,
          selectedIconTheme: IconThemeData(
            color: colorScheme.onSecondaryContainer,
          ),
          unselectedIconTheme: IconThemeData(
            color: colorScheme.onSurfaceVariant,
          ),
          selectedLabelTextStyle: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          unselectedLabelTextStyle: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          leading: Tooltip(
            message: extended ? l10n.navCollapseSidebar : l10n.navExpandSidebar,
            child: IconButton(
              icon: Icon(extended ? Icons.chevron_left : Icons.chevron_right),
              onPressed: onToggleExtended,
              focusNode: FocusNode(skipTraversal: false), // 允许键盘焦点
            ),
          ),
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.image_outlined),
              selectedIcon: const Icon(Icons.image),
              label: Text(l10n.works),
              padding: const EdgeInsets.all(8), // 增加点击区域
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.font_download_outlined),
              selectedIcon: const Icon(Icons.font_download),
              label: Text(l10n.characters),
              padding: const EdgeInsets.all(8),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.article_outlined),
              selectedIcon: const Icon(Icons.article),
              label: Text(l10n.practices),
              padding: const EdgeInsets.all(8),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.photo_library_outlined),
              selectedIcon: const Icon(Icons.photo_library),
              label: Text(l10n.libraryManagement),
              padding: const EdgeInsets.all(8),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: Text(l10n.settings),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ),
    );
  }
}
