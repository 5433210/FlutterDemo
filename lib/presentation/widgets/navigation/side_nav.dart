import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';

class SideNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SideNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: theme.scaffoldBackgroundColor,
      minWidth: AppSizes.navigationRailWidth,
      selectedIconTheme: IconThemeData(
        size: AppSizes.iconMedium,
        color: theme.primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        size: AppSizes.iconMedium,
        color: theme.unselectedWidgetColor,
      ),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.image),
          label: Text('作品'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.font_download),
          label: Text('集字'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.article),
          label: Text('字帖'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
}
