import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

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
    
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      backgroundColor: colorScheme.surface,
      useIndicator: true,
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
      leading: IconButton(
        icon: Icon(extended ? Icons.chevron_left : Icons.chevron_right),
        onPressed: onToggleExtended,
        tooltip: extended ? '收起侧边栏' : '展开侧边栏',
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.image_outlined),
          selectedIcon: Icon(Icons.image),
          label: Text('作品'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.font_download_outlined),
          selectedIcon: Icon(Icons.font_download),
          label: Text('集字'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: Text('字帖'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
}
