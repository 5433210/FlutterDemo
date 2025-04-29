import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../presentation/intents/navigation_intents.dart';
import '../../../presentation/pages/characters/m3_character_management_page.dart';
import '../../../presentation/pages/practices/practice_edit_page.dart';
import '../../../presentation/pages/practices/practice_list_page.dart';
import '../../../presentation/pages/settings/settings_page.dart';
import '../../../presentation/pages/works/m3_character_collection_page.dart';
import '../../../presentation/pages/works/m3_work_browse_page.dart';
import '../../../presentation/pages/works/m3_work_detail_page.dart';
import '../../../presentation/widgets/navigation/m3_side_nav.dart';
import '../../../presentation/widgets/window/m3_title_bar.dart';
import '../../../routes/app_routes.dart';

class M3MainWindow extends StatefulWidget {
  const M3MainWindow({super.key});

  @override
  State<M3MainWindow> createState() => _M3MainWindowState();
}

class _M3MainWindowState extends State<M3MainWindow>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isNavigationExtended = false;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // 导航快捷键
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
            const ActivateTabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
            const ActivateTabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3):
            const ActivateTabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4):
            const ActivateTabIntent(3),

        // 侧边栏快捷键
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyN):
            const ToggleNavigationIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateTabIntent: CallbackAction<ActivateTabIntent>(
            onInvoke: (intent) => setState(() => _selectedIndex = intent.index),
          ),
          ToggleNavigationIntent: CallbackAction<ToggleNavigationIntent>(
            onInvoke: (intent) =>
                setState(() => _isNavigationExtended = !_isNavigationExtended),
          ),
        },
        child: Scaffold(
          body: Column(
            children: [
              // 标题栏
              const M3TitleBar(),

              // 内容区域
              Expanded(
                child: Row(
                  children: [
                    // 侧边导航栏
                    M3NavigationSidebar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      extended: _isNavigationExtended,
                      onToggleExtended: () {
                        setState(() {
                          _isNavigationExtended = !_isNavigationExtended;
                        });
                      },
                    ),

                    // 内容区域
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    // 保持与原MainWindow相同的内容构建逻辑
    switch (_selectedIndex) {
      case 0:
        return Navigator(
          key: ValueKey('work_navigator_$_selectedIndex'),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.workDetail &&
                settings.arguments != null) {
              final workId = settings.arguments as String;
              return MaterialPageRoute<bool>(
                builder: (context) => M3WorkDetailPage(workId: workId),
              );
            }
            if (settings.name == AppRoutes.characterCollection &&
                settings.arguments != null) {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute<bool>(
                builder: (context) => M3CharacterCollectionPage(
                  workId: args['workId']!,
                  initialPageId: args['pageId']!,
                  initialCharacterId: args['characterId'],
                ),
              );
            }
            // Default to work browse page
            return MaterialPageRoute(
              builder: (context) => const M3WorkBrowsePage(),
            );
          },
        );
      case 1:
        return const M3CharacterManagementPage();
      case 2:
        return Navigator(
          key: ValueKey('practice_navigator_$_selectedIndex'),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.practiceEdit) {
              String practiceId;
              if (settings.arguments != null) {
                practiceId = settings.arguments as String;
              } else {
                practiceId = '';
              }

              return MaterialPageRoute<bool>(
                builder: (context) => PracticeEditPage(
                  practiceId: practiceId,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const PracticeListPage(),
            );
          },
        );
      case 3:
        return const SettingsPage();
      default:
        return const Center(child: Text('Page not implemented'));
    }
  }
}
