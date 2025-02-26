import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'infrastructure/persistence/sqlite/sqlite_database.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'presentation/pages/characters/character_list_page.dart';
import 'presentation/pages/practices/practice_detail_page.dart';
import 'presentation/pages/practices/practice_edit_page.dart';
import 'presentation/pages/practices/practice_list_page.dart';
import 'presentation/pages/settings/settings_page.dart';
import 'presentation/pages/works/work_browse_page.dart';
import 'presentation/pages/works/work_detail_page.dart';
import 'presentation/widgets/navigation/side_nav.dart';
import 'presentation/widgets/window/title_bar.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 先初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 2. 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 3. 配置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800), // 设置初始窗口大小
    minimumSize: Size(800, 600), // 设置最小窗口大小
    center: true, // 窗口居中显示
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // 4. 应用窗口配置
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 5. 初始化其他服务
  await SqliteDatabase.initializePlatform();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '书法集字',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const MainWindow(),
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case AppRoutes.home:
            return MaterialPageRoute(
              builder: (context) => const MainWindow(),
            );

          case AppRoutes.workBrowse:
            return MaterialPageRoute(
              builder: (context) => const WorkBrowsePage(),
            );

          case AppRoutes.workDetail:
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => WorkDetailPage(workId: args),
              );
            }
            break;

          case AppRoutes.characterList:
            return MaterialPageRoute(
              builder: (context) => const CharacterListPage(),
            );

          case AppRoutes.characterDetail:
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => CharacterDetailPage(
                  charId: args,
                  onBack: () => Navigator.of(context).pop(),
                ),
              );
            }
            break;

          case AppRoutes.practiceList:
            return MaterialPageRoute(
              builder: (context) => const PracticeListPage(),
            );

          case AppRoutes.practiceEdit:
            return MaterialPageRoute(
              builder: (context) => PracticeEditPage(
                practiceId: args as String?,
              ),
            );

          case AppRoutes.practiceDetail:
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => PracticeDetailPage(
                  practiceId: args,
                ),
              );
            }
            break;

          case AppRoutes.settings:
            return MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            );
        }

        // 未知路由返回首页
        return MaterialPageRoute(
          builder: (context) => const MainWindow(),
        );
      },
      // 添加本地化支持
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
    );
  }
}

class _MainWindowState extends State<MainWindow> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                SideNavigation(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const WorkBrowsePage();
      case 1:
        return const CharacterListPage();
      case 2:
        return const PracticeListPage();
      case 3:
        return const SettingsPage();
      default:
        return const Center(child: Text('页面未实现'));
    }
  }
}
