import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 确保导入 shared_preferences
import 'package:window_manager/window_manager.dart';

import 'application/providers/service_providers.dart'; // 导入 service_providers
import 'infrastructure/logging/logging.dart';
import 'infrastructure/persistence/sqlite/sqlite_database.dart';
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

  try {
    // 初始化窗口管理器
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    // 设置窗口
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

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

    // 设置全局错误处理
    AppErrorHandler.initialize();

    AppLogger.info('Application starting', tag: 'App');

    // 初始化 SharedPreferences (关键步骤)
    final prefs = await SharedPreferences.getInstance();

    // 启动应用，提供 SharedPreferences 实例
    runApp(
      ProviderScope(
        //observers: kReleaseMode ? [] : [ProviderLogger()],
        overrides: [
          // 覆盖 sharedPreferencesProvider
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    // Ensure error is logged even during initialization
    if (AppLogger.hasHandlers) {
      AppLogger.fatal(
        'Failed to start application',
        error: e,
        stackTrace: stack,
        tag: 'App',
      );
    } else {
      // Fallback if logger not initialized
      debugPrint('FATAL ERROR: Failed to start application: $e');
      debugPrint('$stack');
    }

    // Show a basic error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('应用启动失败: $e'),
        ),
      ),
    ));
  }
}

// Create providers that will be initialized once the app starts
final _initializedProvider = FutureProvider<void>((ref) async {
  // This contains all initialization that might interact with providers
  await SqliteDatabase.initializePlatform();
});

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to initialization provider to ensure everything is set up
    final initialization = ref.watch(_initializedProvider);

    return initialization.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('初始化失败: $error'),
          ),
        ),
      ),
      data: (_) => MaterialApp(
        title: '书法集字',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const MainWindow(),
        onGenerateRoute: _generateRoute,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh'),
          Locale('en'),
        ],
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
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

    // Unknown routes return to home
    return MaterialPageRoute(
      builder: (context) => const MainWindow(),
    );
  }
}

/// Riverpod logger for debug mode
class ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<dynamic> provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider $provider was initialized with $value',
      tag: 'Riverpod',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<dynamic> provider,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider $provider was disposed',
      tag: 'Riverpod',
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (previousValue != newValue) {
      AppLogger.debug(
        'Provider $provider updated from $previousValue to $newValue',
        tag: 'Riverpod',
      );
    }
  }
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
