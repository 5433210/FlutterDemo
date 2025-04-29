import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

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
        tooltip: extended ? l10n.navCollapseSidebar : l10n.navExpandSidebar,
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.image_outlined),
          selectedIcon: const Icon(Icons.image),
          label: Text(l10n.works),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.font_download_outlined),
          selectedIcon: const Icon(Icons.font_download),
          label: Text(l10n.characters),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.article_outlined),
          selectedIcon: const Icon(Icons.article),
          label: Text(l10n.practices),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(l10n.settings),
        ),
      ],
    );
  }
}
