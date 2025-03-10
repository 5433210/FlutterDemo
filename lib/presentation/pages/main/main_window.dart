import 'package:flutter/material.dart';

import '../../../presentation/pages/characters/character_list_page.dart';
import '../../../presentation/pages/practices/practice_list_page.dart';
import '../../../presentation/pages/settings/settings_page.dart';
import '../../../presentation/pages/works/work_browse_page.dart';
import '../../../presentation/pages/works/work_detail_page.dart';
import '../../../presentation/widgets/navigation/side_nav.dart';
import '../../../presentation/widgets/window/title_bar.dart';
import '../../../routes/app_routes.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Title bar - unchanged
          const TitleBar(),

          // Content area - including side navigation bar and right content
          Expanded(
            child: Row(
              children: [
                // Side navigation - always shown
                SideNavigation(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),

                // Content area - dynamically changing part
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Widget _buildContent() {
    // Build different content based on selected tab
    switch (_selectedIndex) {
      case 0:
        return Navigator(
          key: ValueKey('work_navigator_$_selectedIndex'),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.workDetail &&
                settings.arguments != null) {
              final workId = settings.arguments as String;
              return MaterialPageRoute<bool>(
                // 指定返回值类型为bool
                builder: (context) => WorkDetailPage(workId: workId),
              );
            }
            // Default to work browse page
            return MaterialPageRoute(
              builder: (context) => const WorkBrowsePage(),
            );
          },
        );
      case 1:
        return const CharacterListPage();
      case 2:
        return const PracticeListPage();
      case 3:
        return const SettingsPage();
      default:
        return const Center(child: Text('Page not implemented'));
    }
  }
}
