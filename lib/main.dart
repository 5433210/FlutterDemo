import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'application/config/app_config.dart';
import 'infrastructure/logging/logging.dart';
import 'infrastructure/providers/database_providers.dart';
import 'infrastructure/providers/shared_preferences_provider.dart';
import 'infrastructure/services/state_restoration_service.dart';
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
import 'utils/path_helper.dart';

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

  // 获取应用数据目录
  final appDir = await getApplicationDocumentsDirectory();
  final dbConfig = await ref.watch(databaseConfigProvider.future);
  final stateService = ref.watch(stateRestorationServiceProvider);
  final actualDataPath = await PathHelper.getAppDataPath();

  // 打印基础配置信息
  AppLogger.info(
    '应用基础配置信息:\n'
    '数据库配置:\n'
    '  - 类型: SQLite (版本 3)\n'
    '  - 数据库名称: ${dbConfig.name ?? "未配置"}\n'
    '  - 数据库文件: ${path.join(actualDataPath, dbConfig.name ?? "app.db")}\n'
    '  - 数据库目录: $actualDataPath\n'
    '  - 迁移脚本数: ${dbConfig.migrations.length ?? 0}\n'
    '\n'
    '文件存储配置:\n'
    '  - 应用系统目录: ${appDir.path}\n'
    '  - 应用数据目录: $actualDataPath\n'
    '  - 目录结构:\n'
    '    * 作品目录: ${path.join(actualDataPath, AppConfig.storageFolder, AppConfig.worksFolder)}\n'
    '    * 工作空间: ${path.join(actualDataPath, AppConfig.workspacePath)}\n'
    '      - 原始文件: ${path.join(actualDataPath, AppConfig.originalsPath)}\n'
    '      - 优化文件: ${path.join(actualDataPath, AppConfig.optimizedPath)}\n'
    '      - 缩略图: ${path.join(actualDataPath, AppConfig.thumbnailsPath)}\n'
    '\n'
    '图片处理配置:\n'
    '  - 支持的格式: ${AppConfig.supportedImageTypes.join(", ")}\n'
    '  - 文件限制:\n'
    '    * 单个文件最大: ${AppConfig.maxImageSize ~/ 1024 ~/ 1024}MB\n'
    '    * 每个作品最大图片数: ${AppConfig.maxImagesPerWork}张\n'
    '    * 最大分辨率: ${AppConfig.maxImageWidth}x${AppConfig.maxImageHeight}\n'
    '  - 图片处理参数:\n'
    '    * 优化后分辨率: ${AppConfig.optimizedImageWidth}x${AppConfig.optimizedImageHeight}\n'
    '    * 优化质量: ${AppConfig.optimizedImageQuality}%\n'
    '    * 缩略图尺寸: ${AppConfig.thumbnailSize}x${AppConfig.thumbnailSize}\n'
    '\n'
    '日志配置:\n'
    '  - 日志级别: ${kReleaseMode ? "警告" : "调试"}\n'
    '  - 处理器:\n'
    '    * 控制台: 启用\n'
    '    * 文件: 启用\n'
    '  - 文件配置:\n'
    '    * 日志目录: ${path.join(appDir.path, "logs")}\n'
    '    * 日志文件: app.log\n'
    '    * 单文件大小限制: 5MB\n'
    '    * 最大文件数: 10\n'
    '\n'
    '状态恢复服务配置:\n'
    '  - 存储类型: SharedPreferences\n'
    '  - 状态有效期: 24小时\n'
    '  - 键值前缀:\n'
    '    * 作品编辑状态: work_edit_state_\n'
    '    * 编辑时间戳: work_edit_timestamp_\n'
    '  - 浏览状态键:\n'
    '    * 状态: work_browse_state\n'
    '    * 时间戳: work_browse_timestamp\n'
    '  - 存储位置:\n'
    '    * 系统目录: ${Platform.environment['LOCALAPPDATA'] ?? Platform.environment['HOME'] ?? "未知"}\n'
    '    * 配置文件: shared_preferences.json\n'
    '    * 完整路径: ${await stateService.getPreferencesPath()}\n'
    '  - 当前状态:\n'
    '    * 配置文件大小: ${await stateService.getPreferencesFileSize()}\n'
    '    * 数据条目数: ${await stateService.getPreferencesEntryCount()}\n'
    '    * 浏览状态: ${await stateService.hasWorkBrowseState() ? "已保存" : "无"}\n'
    '    * 编辑会话: ${await stateService.checkEditSessions()}\n'
    '    * 状态存储位置: ${await stateService.getStorageLocation()}',
    tag: 'AppConfig',
  );
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
