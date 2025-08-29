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
import 'pages/initialization/initialization_screen.dart';
import 'pages/practices/m3_practice_edit_page.dart';
import 'pages/practices/m3_practice_list_page.dart';
import 'pages/settings/m3_settings_page.dart';
import 'pages/works/m3_character_collection_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info('开始构建MyApp', tag: 'UI');

    // Listen to initialization provider to ensure everything is set up
    final initialization = ref.watch(appInitializationProvider);
    AppLogger.info('应用初始化状态', tag: 'UI', data: {
      'state': initialization.toString(),
    });

    // 监听功能标志
    final featureFlags = ref.watch(featureFlagsProvider);
    AppLogger.debug('功能标志状态', tag: 'UI', data: {
      'useMaterial3UI': featureFlags.useMaterial3UI,
    });

    // 记录系统语言信息
    final platformLocale = Platform.localeName.toLowerCase();
    AppLogger.info('应用启动时的系统语言信息', tag: 'Localization', data: {
      'platformLocaleName': Platform.localeName,
      'debugPrint_platformLocale': platformLocale,
    });

    debugPrint('【系统语言】操作系统语言检测: $platformLocale');

    // 预先检测系统语言并创建对应的 Locale
    Locale? detectedSystemLocale;
    if (platformLocale.startsWith('zh') ||
        platformLocale.contains('_cn') ||
        platformLocale.contains('_hans')) {
      detectedSystemLocale = const Locale('zh');
      debugPrint('【系统语言】检测到中文系统语言，设置为: zh');
    } else if (platformLocale.startsWith('en')) {
      detectedSystemLocale = const Locale('en');
      debugPrint('【系统语言】检测到英文系统语言，设置为: en');
    } else if (platformLocale.startsWith('ja')) {
      detectedSystemLocale = const Locale('ja');
      debugPrint('【系统语言】检测到日语系统语言，设置为: ja');
    } else if (platformLocale.startsWith('ko')) {
      detectedSystemLocale = const Locale('ko');
      debugPrint('【系统语言】检测到韩语系统语言，设置为: ko');
    } else {
      // 默认使用中文
      detectedSystemLocale = const Locale('zh');
      debugPrint('【系统语言】未检测到支持的系统语言，默认使用中文');
    }

    AppLogger.info('初始化状态分支判断前', tag: 'UI', data: {
      'state': initialization.toString(),
    });

    return initialization.when(
      loading: () {
        AppLogger.info('应用处于加载状态，显示初始化屏幕', tag: 'UI');
        
        // 尝试从SharedPreferences直接读取用户语言偏好
        return FutureBuilder<Locale?>(
          future: _getUserLanguagePreference(),
          builder: (context, snapshot) {
            Locale? initLocale;
            
            if (snapshot.hasData && snapshot.data != null) {
              // 如果有用户设置的语言，使用用户设置
              initLocale = snapshot.data;
              AppLogger.debug('初始化屏幕使用用户设置语言', tag: 'UI', data: {
                'userLocale': initLocale?.languageCode ?? 'null',
              });
            } else {
              // 否则使用检测到的系统语言
              initLocale = detectedSystemLocale;
              AppLogger.debug('初始化屏幕使用系统语言', tag: 'UI', data: {
                'systemLocale': initLocale?.languageCode ?? 'null',
              });
            }
            
            return MaterialApp(
              home: const InitializationScreen(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: initLocale,
            );
          },
        );
      },
      error: (error, stack) {
        AppLogger.error('应用初始化失败', error: error, stackTrace: stack, tag: 'UI');
        
        // 尝试从SharedPreferences直接读取用户语言偏好
        return FutureBuilder<Locale?>(
          future: _getUserLanguagePreference(),
          builder: (context, snapshot) {
            Locale? initLocale;
            
            if (snapshot.hasData && snapshot.data != null) {
              // 如果有用户设置的语言，使用用户设置
              initLocale = snapshot.data;
            } else {
              // 否则使用检测到的系统语言
              initLocale = detectedSystemLocale;
            }
            
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
                      l10n?.initializationFailed(error.toString()) ??
                          'Initialization failed: $error',
                      style: const TextStyle(color: Colors.red),
                    );
                  }),
                ),
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: initLocale,
            );
          },
        );
      },
      data: (_) {
        AppLogger.info('应用初始化成功，开始构建主界面', tag: 'UI');

        // 获取用户语言设置
        final userLanguage =
            ref.watch(settingsProvider.select((s) => s.language));
        AppLogger.debug('用户语言设置', tag: 'UI', data: {
          'userLanguage': userLanguage.toString(),
        });
        debugPrint('【系统语言】当前用户语言设置: $userLanguage');

        // 确定最终使用的 Locale - 重要：使用 watch 而非 read 以确保设置变更时重建
        final Locale? finalLocale = userLanguage == AppLanguage.system
            ? detectedSystemLocale // 如果是跟随系统，使用检测到的系统区域设置
            : userLanguage.toLocale(); // 否则使用用户选择的语言

        debugPrint('【系统语言】最终使用的语言: ${finalLocale?.languageCode ?? "null"}');

        // 获取当前语言环境的字符串表示
        final currentLocale = finalLocale?.languageCode;
        AppLogger.debug('最终使用的语言', tag: 'UI', data: {
          'finalLocale': finalLocale?.languageCode ?? 'null',
        });

        // 创建MaterialApp
        AppLogger.info('开始创建MaterialApp', tag: 'UI');
        final app = MaterialApp(
          title: switch (userLanguage) {
            AppLanguage.en => 'Character As Gem',
            AppLanguage.ja => '字字珠玉', // 日语：字字珠玉
            AppLanguage.ko => '字字珠玑', // 韩语：字字珠玑
            AppLanguage.zhTw => '字字珠璣', // 繁体中文
            AppLanguage.zh => '字字珠玑', // 简体中文
            _ => '字字珠玑', // 系统默认
          },
          theme: AppTheme.lightM3(locale: currentLocale), // 传递当前语言环境
          darkTheme: AppTheme.darkM3(locale: currentLocale), // 传递当前语言环境
          themeMode: ref.watch(
              settingsProvider.select((s) => s.themeMode.toFlutterThemeMode())),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) {
              AppLogger.info('构建主界面Builder', tag: 'UI');
              // 在MaterialApp初始化后更新窗口标题 - 仅在桌面平台
              final l10n = AppLocalizations.of(context);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppLogger.info('主界面首帧渲染完成回调', tag: 'UI');
                if (!kIsWeb &&
                    (Platform.isWindows ||
                        Platform.isMacOS ||
                        Platform.isLinux)) {
                  windowManager.setTitle(l10n.appTitle);
                }
              });

              AppLogger.info('返回M3MainWindow', tag: 'UI');
              return const M3MainWindow();
            },
          ),
          onGenerateRoute: (settings) =>
              _generateRoute(settings, featureFlags.useMaterial3UI),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // 直接设置 locale 值，而不是依赖回调
          locale: finalLocale,
        );

        AppLogger.info('MaterialApp创建完成', tag: 'UI');
        return app;
      },
    );
  }

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

  /// 从SharedPreferences直接获取用户语言偏好
  /// 用于初始化阶段在settingsProvider可用之前获取语言设置
  Future<Locale?> _getUserLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageString = prefs.getString('language');
      
      AppLogger.debug('从SharedPreferences读取语言设置', tag: 'UI', data: {
        'languageString': languageString ?? 'null',
      });
      
      if (languageString != null) {
        final appLanguage = AppLanguage.fromString(languageString);
        final locale = appLanguage.toLocale();
        
        AppLogger.debug('解析用户语言设置', tag: 'UI', data: {
          'appLanguage': appLanguage.toString(),
          'locale': locale?.languageCode ?? 'null',
        });
        
        return locale;
      }
    } catch (e) {
      AppLogger.warning('读取用户语言偏好失败', error: e, tag: 'UI');
    }
    
    return null;  // 返回null表示使用系统默认
  }
}
