import 'package:demo/presentation/pages/characters/character_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers/initialization_providers.dart';
import '../presentation/pages/characters/character_list_page.dart';
import '../presentation/pages/practices/practice_detail_page.dart';
import '../presentation/pages/practices/practice_edit_page.dart';
import '../presentation/pages/practices/practice_list_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/works/work_browse_page.dart';
import '../presentation/pages/works/work_detail_page.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'pages/initialization/initialization_screen.dart';
import 'pages/main/main_window.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to initialization provider to ensure everything is set up
    final initialization = ref.watch(appInitializationProvider);

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
        title: '书法集字',
        theme: AppTheme.light(),
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
