import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'infrastructure/logging/logging.dart';
import 'infrastructure/persistence/sqlite/sqlite_database.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'presentation/pages/characters/character_list_page.dart';
import 'presentation/pages/practices/practice_detail_page.dart';
import 'presentation/pages/practices/practice_edit_page.dart';
import 'presentation/pages/practices/practice_list_page.dart';
import 'presentation/pages/settings/settings_page.dart';
import 'presentation/pages/works/work_browse_page.dart';
import 'presentation/pages/works/work_detail_page.dart';
import 'presentation/providers/work_browse_provider.dart';
import 'presentation/widgets/navigation/side_nav.dart';
import 'presentation/widgets/window/title_bar.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化日志系统
    final appDocDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDocDir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    await AppLogger.init(
      minLevel: kReleaseMode ? LogLevel.warning : LogLevel.debug,
      enableConsole: true,
      enableFile: true,
      filePath: '${logDir.path}/app.log',
      maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
      maxFiles: 10,
    );

    // 设置全局异常处理
    AppErrorHandler.initialize();

    AppLogger.info('Application starting', tag: 'App');

    // 初始化依赖
    await initializeDependencies();

    // 启动应用
    runApp(
      ProviderScope(
        observers: kReleaseMode ? [] : [ProviderLogger()],
        overrides: [
          sharedPreferencesProvider
              .overrideWithValue(await SharedPreferences.getInstance()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    // 确保即使在初始化过程中出现异常也能记录日志
    if (AppLogger.hasHandlers) {
      AppLogger.fatal(
        'Failed to start application',
        error: e,
        stackTrace: stack,
        tag: 'App',
      );
    } else {
      // 日志系统尚未初始化的备用方案
      debugPrint('FATAL ERROR: Failed to start application: $e');
      debugPrint('$stack');
    }

    // 显示一个基本的错误屏幕
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('应用启动失败: $e'),
        ),
      ),
    ));
  }
}

Future<void> initializeDependencies() async {
  try {
    AppLogger.debug('Starting dependency initialization', tag: 'Setup');

    // 1. 先初始化 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    AppLogger.debug('SharedPreferences initialized', tag: 'Setup');

    // 2. 初始化窗口管理器
    await windowManager.ensureInitialized();
    AppLogger.debug('Window manager initialized', tag: 'Setup');

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
    AppLogger.debug('Window configured and shown', tag: 'Setup');

    // 5. 初始化数据库
    await SqliteDatabase.initializePlatform();
    AppLogger.debug('Database platform initialized', tag: 'Setup');

    AppLogger.info('All dependencies initialized successfully', tag: 'Setup');
  } catch (e, stack) {
    AppLogger.error('Failed to initialize dependencies',
        tag: 'Setup', error: e, stackTrace: stack);
    rethrow;
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MainWindowState extends State<MainWindow> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 标题栏 - 这里保留不变
          const TitleBar(),

          // 内容区域 - 包括侧边导航栏和右侧内容
          Expanded(
            child: Row(
              children: [
                // 侧边导航栏 - 始终显示
                SideNavigation(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),

                // 内容区域 - 动态变化的部分
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

  Widget _buildContent() {
    // 这里根据选中的标签页返回不同的内容
    switch (_selectedIndex) {
      case 0:
        return Navigator(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.workDetail &&
                settings.arguments != null) {
              final workId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => WorkDetailPage(workId: workId),
              );
            }
            // 默认返回作品浏览页
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
        return const Center(child: Text('页面未实现'));
    }
  }
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Riverpod 2.0+ 语法
      final container = ProviderScope.containerOf(context);
      container.read(workBrowseProvider.notifier).loadWorks();
    }
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
}
