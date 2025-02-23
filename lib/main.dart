import 'package:demo/presentation/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'presentation/pages/works/work_browse_page.dart';
import 'presentation/widgets/window/title_bar.dart';
import 'presentation/widgets/navigation/side_nav.dart';
import 'presentation/pages/characters/character_list_page.dart';
import 'presentation/pages/practices/practice_list_page.dart';
import 'infrastructure/persistence/sqlite/sqlite_database.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size(800, 600),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,  // 是否在任务栏隐藏
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
    center: true,      // 窗口居中
    title: '书法集字',
    // 添加以下设置
    fullScreen: false,
    alwaysOnTop: false,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions);
  await windowManager.show();
  await windowManager.focus();

  await SqliteDatabase.initializePlatform();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(      
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
      home: const MainWindow(),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});
  
  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  int _selectedIndex = 0;

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const WorkBrowsePage();
      case 1:
        return const CharacterListPage();
      case 2:
        return const PracticeListPage();
      case 3:
        return const  SettingsPage();
      default:
        return const Center(child: Text('页面未实现'));
    }
  }
  
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
                    setState(() { _selectedIndex = index; });
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
}
