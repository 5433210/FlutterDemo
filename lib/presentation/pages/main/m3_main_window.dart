import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../presentation/intents/navigation_intents.dart';
import '../../../presentation/pages/characters/m3_character_management_page.dart';
import '../../../presentation/pages/settings/m3_settings_page.dart';
import '../../../presentation/pages/works/m3_character_collection_page.dart';
import '../../../presentation/pages/works/m3_work_browse_page.dart';
import '../../../presentation/pages/works/m3_work_detail_page.dart';
import '../../../presentation/widgets/navigation/m3_side_nav.dart';
import '../../../presentation/widgets/window/m3_title_bar.dart';
import '../../../routes/app_routes.dart';
import '../library/m3_library_management_page.dart';
import '../practices/m3_practice_edit_page.dart';
import '../practices/m3_practice_list_page.dart';

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
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit5):
            const ActivateTabIntent(4),

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
        return Navigator(
          key: ValueKey('library_navigator_$_selectedIndex'),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const M3LibraryManagementPage(),
            );
          },
        );
      case 2:
        return Navigator(
          key: ValueKey('character_navigator_$_selectedIndex'),
          onGenerateRoute: (settings) {
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
            if (settings.name == AppRoutes.workDetail &&
                settings.arguments != null) {
              // 支持两种参数类型：字符串和Map
              String workId;
              if (settings.arguments is String) {
                workId = settings.arguments as String;
              } else if (settings.arguments is Map<String, String>) {
                final args = settings.arguments as Map<String, String>;
                workId = args['workId']!;
              } else {
                workId = '';
              }

              return MaterialPageRoute<bool>(
                builder: (context) => M3WorkDetailPage(
                  workId: workId,
                ),
              );
            }
            // Default to character management page
            return MaterialPageRoute(
              builder: (context) => const M3CharacterManagementPage(),
            );
          },
        );
      case 3:
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
                builder: (context) => M3PracticeEditPage(
                  practiceId: practiceId.isNotEmpty ? practiceId : null,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const M3PracticeListPage(),
            );
          },
        );
      case 4:
        return const M3SettingsPage();
      default:
        return const Center(child: Text('Page not implemented'));
    }
  }
}
