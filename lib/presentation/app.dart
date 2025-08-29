import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../application/providers/feature_flag_provider.dart';
import '../application/providers/initialization_providers.dart';
import '../domain/enums/app_language.dart';
import '../infrastructure/logging/logger.dart';
import '../l10n/app_localizations.dart';
import '../presentation/pages/main/m3_main_window.dart';
import '../presentation/pages/works/m3_work_browse_page.dart';
import '../presentation/pages/works/m3_work_detail_page.dart';
import '../presentation/providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'pages/characters/m3_character_management_page.dart';
import 'pages/initialization/initialization_screen_simplified.dart';
import 'pages/practices/m3_practice_edit_page.dart';
import 'pages/practices/m3_practice_list_page.dart';
import 'pages/settings/m3_settings_page.dart';
import 'pages/works/m3_character_collection_page.dart';

/// 应用入口类（已优化）
/// 解决重复初始化和重建问题
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // 缓存检测到的系统语言，避免重复检测
  Locale? _cachedSystemLocale;

  // 缓存用户语言偏好，避免重复读取
  Locale? _cachedUserLocale;

  // 初始化状态，避免重复处理
  bool _systemLanguageInitialized = false;
  bool _languageInitializationCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeLanguage(); // 统一处理语言初始化
  }

  /// 统一处理语言初始化：先加载用户设置，再设置系统语言作为回退
  void _initializeLanguage() async {
    AppLogger.info('开始统一语言初始化', tag: 'UI');
    debugPrint('【调试】开始统一语言初始化');

    // 先尝试同步加载用户语言偏好
    await _loadUserLanguagePreference();

    AppLogger.info('用户语言加载完成，检查结果', tag: 'UI', data: {
      'cachedUserLocale': _cachedUserLocale?.languageCode,
    });
    debugPrint('【调试】用户语言加载完成: ${_cachedUserLocale?.languageCode}');

    // 如果用户语言没有设置，再使用系统语言作为回退
    if (_cachedUserLocale == null) {
      AppLogger.info('用户语言未设置，初始化系统语言', tag: 'UI');
      debugPrint('【调试】用户语言未设置，初始化系统语言');
      _initializeSystemLanguage();
    } else {
      AppLogger.info('用户语言已设置，跳过系统语言初始化', tag: 'UI');
      debugPrint('【调试】用户语言已设置，跳过系统语言初始化');
    }

    // 标记语言初始化完成，触发UI重建
    setState(() {
      _languageInitializationCompleted = true;
    });

    AppLogger.info('语言初始化完成，UI将重建', tag: 'UI');
    debugPrint('【调试】语言初始化完成，UI将重建');
  }

  /// 一次性初始化系统语言检测
  void _initializeSystemLanguage() {
    if (_systemLanguageInitialized) return;
    _systemLanguageInitialized = true;

    AppLogger.info('开始构建MyApp', tag: 'UI');

    // 只执行一次系统语言检测
    final platformLocale = Platform.localeName.toLowerCase();
    AppLogger.info('应用启动时的系统语言信息', tag: 'Localization', data: {
      'platformLocaleName': Platform.localeName,
      'debugPrint_platformLocale': platformLocale,
    });

    debugPrint('【系统语言】操作系统语言检测: $platformLocale');

    // 缓存系统语言检测结果
    if (platformLocale.startsWith('zh') ||
        platformLocale.contains('_cn') ||
        platformLocale.contains('_hans')) {
      _cachedSystemLocale = const Locale('zh');
      debugPrint('【系统语言】检测到中文系统语言，设置为: zh');
    } else if (platformLocale.startsWith('en')) {
      _cachedSystemLocale = const Locale('en');
      debugPrint('【系统语言】检测到英文系统语言，设置为: en');
    } else if (platformLocale.startsWith('ja')) {
      _cachedSystemLocale = const Locale('ja');
      debugPrint('【系统语言】检测到日语系统语言，设置为: ja');
    } else if (platformLocale.startsWith('ko')) {
      _cachedSystemLocale = const Locale('ko');
      debugPrint('【系统语言】检测到韩语系统语言，设置为: ko');
    } else {
      _cachedSystemLocale = const Locale('zh');
      debugPrint('【系统语言】未检测到支持的系统语言，默认使用中文');
    }
  }

  /// 异步加载用户语言偏好
  Future<void> _loadUserLanguagePreference() async {
    try {
      AppLogger.info('开始加载用户语言偏好', tag: 'UI');
      debugPrint('【调试】开始加载用户语言偏好');

      final prefs = await SharedPreferences.getInstance();
      final languageString = prefs.getString('language');

      AppLogger.info('SharedPreferences读取结果', tag: 'UI', data: {
        'languageString': languageString,
        'allKeys': prefs.getKeys().toList(),
      });
      debugPrint('【调试】SharedPreferences读取结果: $languageString');
      debugPrint('【调试】所有保存的键: ${prefs.getKeys().toList()}');

      if (languageString != null) {
        final appLanguage = AppLanguage.fromString(languageString);
        final locale = appLanguage.toLocale();

        if (mounted) {
          setState(() {
            _cachedUserLocale = locale;
          });

          AppLogger.debug('初始化阶段加载用户语言设置', tag: 'UI', data: {
            'languageString': languageString,
            'appLanguage': appLanguage.toString(),
            'locale': locale?.languageCode ?? 'null',
            'willUpdateUI': true,
          });

          debugPrint('【用户语言】异步加载完成: $appLanguage -> ${locale?.languageCode}');
        }
      } else {
        AppLogger.debug('用户未设置语言偏好，将使用系统语言', tag: 'UI', data: {
          'systemLocale': _cachedSystemLocale?.languageCode ?? 'zh',
        });
        debugPrint(
            '【用户语言】未设置，使用系统语言: ${_cachedSystemLocale?.languageCode ?? 'zh'}');
      }
    } catch (e) {
      AppLogger.warning('初始化阶段读取用户语言偏好失败', error: e, tag: 'UI');
      debugPrint('【用户语言】读取失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果语言初始化还没完成，显示简单的加载页面
    if (!_languageInitializationCompleted) {
      AppLogger.info('语言初始化中，显示加载页面', tag: 'UI');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 应用Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // 如果logo加载失败，使用默认图标
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.edit_note,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('正在初始化...'),
              ],
            ),
          ),
        ),
      );
    }

    // 只在必要时监听初始化provider
    final initialization = ref.watch(appInitializationProvider);

    // 只在初始化状态变化时打印日志
    if (initialization != ref.read(appInitializationProvider)) {
      AppLogger.info('应用初始化状态变化', tag: 'UI', data: {
        'state': initialization.toString(),
      });
    }

    // 监听功能标志（缓存结果，避免重复读取）
    final featureFlags = ref.watch(featureFlagsProvider);

    return initialization.when(
      loading: () => _buildLoadingApp(),
      error: (error, stack) => _buildErrorApp(error, stack),
      data: (_) => _buildMainApp(featureFlags),
    );
  }

  /// 构建加载中的应用界面
  Widget _buildLoadingApp() {
    AppLogger.info('应用处于加载状态，显示初始化屏幕', tag: 'UI');

    return MaterialApp(
      home: const InitializationScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _getInitializationLocale(),
    );
  }

  /// 构建错误状态的应用界面
  Widget _buildErrorApp(Object error, StackTrace stack) {
    AppLogger.error('应用初始化失败', error: error, stackTrace: stack, tag: 'UI');

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(builder: (context) {
            AppLocalizations? l10n;
            try {
              l10n = AppLocalizations.of(context);
            } catch (e) {
              l10n = null;
            }
            return Text(
              l10n?.initializationError ?? 'Initialization failed',
              style: const TextStyle(color: Colors.red),
            );
          }),
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _getInitializationLocale(),
    );
  }

  /// 构建主应用界面
  Widget _buildMainApp(FeatureFlags featureFlags) {
    AppLogger.info('应用初始化成功，开始构建主界面', tag: 'UI');

    // 获取用户语言设置（使用缓存避免重复读取）
    final userLanguage = ref.watch(settingsProvider.select((s) => s.language));

    // 确定最终使用的 Locale
    final finalLocale = _getFinalLocale(userLanguage);
    final currentLocale = finalLocale?.languageCode;

    AppLogger.info('开始创建MaterialApp', tag: 'UI');

    final app = MaterialApp(
      title: _getAppTitle(userLanguage),
      theme: AppTheme.lightM3(locale: currentLocale),
      darkTheme: AppTheme.darkM3(locale: currentLocale),
      themeMode: ref.watch(
          settingsProvider.select((s) => s.themeMode.toFlutterThemeMode())),
      debugShowCheckedModeBanner: false,
      home: _buildMainWindow(),
      onGenerateRoute: (settings) =>
          _generateRoute(settings, featureFlags.useMaterial3UI),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: finalLocale,
    );

    AppLogger.info('MaterialApp创建完成', tag: 'UI');
    return app;
  }

  /// 构建主窗口
  Widget _buildMainWindow() {
    return Builder(
      builder: (context) {
        AppLogger.info('构建主界面Builder', tag: 'UI');

        // 在MaterialApp初始化后更新窗口标题 - 仅在桌面平台
        final l10n = AppLocalizations.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppLogger.info('主界面首帧渲染完成回调', tag: 'UI');
          if (!kIsWeb &&
              (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
            windowManager.setTitle(l10n.appTitle);
          }
        });

        AppLogger.info('返回M3MainWindow', tag: 'UI');
        return const M3MainWindow();
      },
    );
  }

  /// 获取初始化阶段的语言设置
  /// 优先级：用户设置 > 系统语言 > 默认中文
  Locale? _getInitializationLocale() {
    // 优先使用用户设置的语言
    if (_cachedUserLocale != null) {
      AppLogger.debug('初始化屏幕使用用户设置语言', tag: 'UI', data: {
        'userLocale': _cachedUserLocale?.languageCode ?? 'null',
        'source': 'user_preference',
      });
      debugPrint('【初始化语言】使用用户设置: ${_cachedUserLocale?.languageCode}');
      return _cachedUserLocale;
    }

    // 如果没有用户设置，使用系统语言
    if (_cachedSystemLocale != null) {
      AppLogger.debug('初始化屏幕使用系统语言', tag: 'UI', data: {
        'systemLocale': _cachedSystemLocale?.languageCode ?? 'null',
        'source': 'system_default',
      });
      debugPrint('【初始化语言】使用系统语言: ${_cachedSystemLocale?.languageCode}');
      return _cachedSystemLocale;
    }

    // 最后的回退选项
    AppLogger.debug('初始化屏幕使用默认语言', tag: 'UI', data: {
      'defaultLocale': 'zh',
      'source': 'fallback',
    });
    debugPrint('【初始化语言】使用默认语言: zh');
    return const Locale('zh');
  }

  /// 获取最终使用的语言设置
  Locale? _getFinalLocale(AppLanguage userLanguage) {
    final finalLocale = userLanguage == AppLanguage.system
        ? _cachedSystemLocale // 如果是跟随系统，使用缓存的系统区域设置
        : userLanguage.toLocale(); // 否则使用用户选择的语言

    // 只在语言设置变化时记录日志
    final currentLocaleCode = finalLocale?.languageCode;
    if (_cachedUserLocale?.languageCode != currentLocaleCode) {
      debugPrint('【系统语言】用户语言设置: $userLanguage');
      debugPrint('【系统语言】最终使用的语言: ${currentLocaleCode ?? "null"}');

      AppLogger.debug('用户语言设置', tag: 'UI', data: {
        'userLanguage': userLanguage.toString(),
      });
      AppLogger.debug('最终使用的语言', tag: 'UI', data: {
        'finalLocale': currentLocaleCode ?? 'null',
      });

      _cachedUserLocale = finalLocale;
    }

    return finalLocale;
  }

  /// 获取应用标题
  String _getAppTitle(AppLanguage userLanguage) {
    return switch (userLanguage) {
      AppLanguage.en => 'Character As Gem',
      AppLanguage.ja => '字字珠玉',
      AppLanguage.ko => '字字珠玑',
      AppLanguage.zhTw => '字字珠璣',
      AppLanguage.zh => '字字珠玑',
      _ => '字字珠玑',
    };
  }

  /// 生成路由
  Route<dynamic>? _generateRoute(RouteSettings settings, bool useMaterial3) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (context) => const M3MainWindow(),
        );

      case AppRoutes.workBrowse:
        return MaterialPageRoute(
          builder: (context) => const M3WorkBrowsePage(),
        );

      case AppRoutes.workDetail:
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (context) => M3WorkDetailPage(
                workId: args['workId']!, initialPageId: args['pageId']!),
          );
        } else if (args is String) {
          return MaterialPageRoute(
            builder: (context) => M3WorkDetailPage(workId: args),
          );
        }
        break;

      case AppRoutes.characterCollection:
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (context) => M3CharacterCollectionPage(
              workId: args['workId']!,
              initialPageId: args['pageId']!,
              initialCharacterId: args['characterId']!,
            ),
          );
        }
        break;

      case AppRoutes.characterManagement:
        return MaterialPageRoute(
          builder: (context) => const M3CharacterManagementPage(),
        );

      case AppRoutes.practiceList:
        return MaterialPageRoute(
          builder: (context) => const M3PracticeListPage(),
        );

      case AppRoutes.practiceEdit:
        return MaterialPageRoute(
          builder: (context) => M3PracticeEditPage(
            practiceId: args as String?,
          ),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (context) => const M3SettingsPage(),
        );
    }

    // Unknown routes return to home
    return MaterialPageRoute(
      builder: (context) => const M3MainWindow(),
    );
  }
}

/// 用户语言偏好缓存服务
/// 避免重复读取SharedPreferences
class UserLanguageCache {
  static Locale? _cachedLocale;
  static DateTime? _lastUpdated;
  static const Duration _cacheValidDuration = Duration(minutes: 1);

  /// 获取缓存的用户语言偏好
  static Future<Locale?> getCachedUserLanguagePreference() async {
    // 检查缓存是否有效
    if (_cachedLocale != null &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _cacheValidDuration) {
      AppLogger.debug('使用缓存的语言设置', tag: 'UI', data: {
        'cachedLocale': _cachedLocale?.languageCode ?? 'null',
      });
      return _cachedLocale;
    }

    // 缓存失效，重新读取
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageString = prefs.getString('language');

      AppLogger.debug('从SharedPreferences读取语言设置', tag: 'UI', data: {
        'languageString': languageString ?? 'null',
      });

      if (languageString != null) {
        final appLanguage = AppLanguage.fromString(languageString);
        _cachedLocale = appLanguage.toLocale();
        _lastUpdated = DateTime.now();

        AppLogger.debug('更新语言缓存', tag: 'UI', data: {
          'appLanguage': appLanguage.toString(),
          'locale': _cachedLocale?.languageCode ?? 'null',
        });

        return _cachedLocale;
      }
    } catch (e) {
      AppLogger.warning('读取用户语言偏好失败', error: e, tag: 'UI');
    }

    _cachedLocale = null;
    _lastUpdated = null;
    return null;
  }

  /// 清除缓存（在语言设置变更时调用）
  static void clearCache() {
    _cachedLocale = null;
    _lastUpdated = null;
    AppLogger.debug('清除语言缓存', tag: 'UI');
  }
}
