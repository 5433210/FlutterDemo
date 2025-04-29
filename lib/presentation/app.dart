import 'package:demo/presentation/pages/characters/character_management_page.dart';
import 'package:demo/presentation/pages/works/character_collection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers/feature_flag_provider.dart';
import '../application/providers/initialization_providers.dart';
import '../presentation/pages/characters/character_list_page.dart';
import '../presentation/pages/main/m3_main_window.dart';
import '../presentation/pages/main/main_window.dart';
import '../presentation/pages/practices/practice_edit_page.dart';
import '../presentation/pages/practices/practice_list_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/works/work_browse_page.dart';
import '../presentation/pages/works/work_detail_page.dart';
import '../presentation/providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'pages/initialization/initialization_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to initialization provider to ensure everything is set up
    final initialization = ref.watch(appInitializationProvider);
    // 监听功能标志
    final featureFlags = ref.watch(featureFlagsProvider);

    return initialization.when(
      loading: () => const MaterialApp(
        home: InitializationScreen(),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('初始化失败: $error'),
          ),
        ),
      ),
      data: (_) => MaterialApp(
        title: '字字珠玑',
        theme: featureFlags.useMaterial3UI 
            ? AppTheme.lightM3() // 新的Material 3主题
            : AppTheme.light(),  // 现有主题
        darkTheme: featureFlags.useMaterial3UI 
            ? AppTheme.darkM3()  // 新的Material 3暗色主题
            : AppTheme.dark(),   // 现有暗色主题
        themeMode: ref.watch(settingsProvider.select((s) => s.themeMode.toFlutterThemeMode())),
        debugShowCheckedModeBanner: false,
        home: featureFlags.useMaterial3UI
            ? const M3MainWindow() // 新的Material 3主窗体
            : const MainWindow(),  // 现有主窗体
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
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (context) => WorkDetailPage(
                workId: args['workId']!, initialPageId: args['pageId']!),
          );
        }
        break;

      case AppRoutes.characterCollection:
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (context) => CharacterCollectionPage(
              workId: args['workId']!,
              initialPageId: args['pageId']!,
              initialCharacterId: args['characterId']!,
            ),
          );
        }
        break;

      case AppRoutes.characterList:
        return MaterialPageRoute(
          builder: (context) => const CharacterListPage(),
        );

      case AppRoutes.characterManagement:
        return MaterialPageRoute(
          builder: (context) => const CharacterManagementPage(),
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
