import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/intents/navigation_intents.dart';
import '../../../presentation/pages/characters/m3_character_management_page.dart';
import '../../../presentation/pages/settings/m3_settings_page.dart';
import '../../../presentation/pages/works/m3_character_collection_page.dart';
import '../../../presentation/pages/works/m3_work_browse_page.dart';
import '../../../presentation/pages/works/m3_work_detail_page.dart';
import '../../../presentation/widgets/navigation/m3_side_nav.dart';
import '../../../presentation/widgets/window/m3_title_bar.dart';
import '../../../routes/app_routes.dart';
import '../../providers/navigation/global_navigation_provider.dart';
import '../../utils/cross_navigation_helper.dart';
import '../library/m3_library_management_page.dart';
import '../practices/m3_practice_edit_page.dart';
import '../practices/m3_practice_list_page.dart';

class M3MainWindow extends ConsumerStatefulWidget {
  const M3MainWindow({super.key});

  @override
  ConsumerState<M3MainWindow> createState() => _M3MainWindowState();
}

class _M3MainWindowState extends ConsumerState<M3MainWindow>
    with WidgetsBindingObserver {
  // 保存所有功能区的Navigator状态
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };

  // 跟踪已初始化的功能区
  final Set<int> _initializedSections = {0}; // 默认只初始化第一个功能区

  Timer? _memoryCleanupTimer;

  // // 内存跟踪器
  // final _memoryTracker = PracticeMemoryTracker();

  // 记录最后一次访问的功能区
  int _lastSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.info('M3MainWindow initState', tag: 'MainWindow');
    WidgetsBinding.instance.addObserver(this);
    
    // 添加帧回调，确认首帧渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('M3MainWindow 首帧渲染完成', tag: 'MainWindow');
    });
    
    // 添加错误处理
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error('Flutter错误', 
        error: details.exception, 
        stackTrace: details.stack, 
        tag: 'FlutterError',
        data: {
          'library': details.library,
          'context': details.context?.toString() ?? 'unknown',
          'silent': details.silent,
        });
      FlutterError.presentError(details);
    };
  }

  @override
  void dispose() {
    AppLogger.info('M3MainWindow dispose', tag: 'MainWindow');
    WidgetsBinding.instance.removeObserver(this);
    _memoryCleanupTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLogger.info('M3MainWindow didChangeDependencies', tag: 'MainWindow');
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('M3MainWindow build开始', tag: 'MainWindow');
    
    try {
      // 从全局导航状态读取状态
      final navState = ref.watch(globalNavigationProvider);
      final selectedIndex = navState.currentSectionIndex;
      
      AppLogger.info('M3MainWindow 导航状态', tag: 'MainWindow', data: {
        'selectedIndex': selectedIndex,
        'isNavigating': navState.isNavigating,
        'isNavigationExtended': navState.isNavigationExtended,
      });
  
      // 检测功能区切换 - 使用WidgetsBinding.instance.addPostFrameCallback避免在build中修改状态
      if (_lastSelectedIndex != selectedIndex) {
        // 记录从哪个功能区切换到哪个功能区
        AppLogger.info(
          '主导航功能区切换',
          data: {
            'fromSection': _lastSelectedIndex,
            'toSection': selectedIndex,
            'operation': 'section_switch',
            'timestamp': DateTime.now().toIso8601String(),
          },
          tag: 'Navigation',
        );
  
        // 延迟到当前帧结束后处理状态更新，避免在build中修改状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _lastSelectedIndex != selectedIndex) {
            setState(() {
              _lastSelectedIndex = selectedIndex;
            });
          }
        });
      }
  
      AppLogger.info('M3MainWindow 构建LayoutBuilder', tag: 'MainWindow');
      return LayoutBuilder(
        builder: (context, constraints) {
          AppLogger.info('M3MainWindow LayoutBuilder回调', tag: 'MainWindow', data: {
            'width': constraints.maxWidth,
            'height': constraints.maxHeight,
          });
          
          return PopScope(
            // 处理返回按钮事件，先尝试在当前功能区内返回，否则尝试跨功能区返回
            canPop: false, // 禁止默认的返回行为，我们将自己处理
            onPopInvokedWithResult: (bool didPop, dynamic result) async {
              // 如果系统已处理了弹出操作，不需要进一步处理
              if (didPop) return;
  
              // 如果正在导航过渡中，不处理返回
              if (navState.isNavigating) return;
  
              // 先尝试在当前功能区内的Navigator返回
              final currentNavigator =
                  _navigatorKeys[selectedIndex]?.currentState;
              final canPopInCurrentSection =
                  currentNavigator != null && currentNavigator.canPop();
  
              if (canPopInCurrentSection) {
                currentNavigator.pop();
                return; // 已在功能区内处理返回，不需要退出应用
              }
  
              // 如果当前功能区内无法返回，尝试回到上一个功能区
              await CrossNavigationHelper.handleBackNavigation(context, ref);
            },
            child: Shortcuts(
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
                    onInvoke: (intent) {
                      ref
                          .read(globalNavigationProvider.notifier)
                          .navigateToSection(intent.index);
                      return null;
                    },
                  ),
                  ToggleNavigationIntent: CallbackAction<ToggleNavigationIntent>(
                    onInvoke: (intent) {
                      ref
                          .read(globalNavigationProvider.notifier)
                          .toggleNavigationExtended();
                      return null;
                    },
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
                              selectedIndex: selectedIndex,
                              onDestinationSelected: (index) {
                                // 使用全局导航提供者切换功能区
                                ref
                                    .read(globalNavigationProvider.notifier)
                                    .navigateToSection(index);
                              },
                              extended: navState.isNavigationExtended,
                              onToggleExtended: () {
                                ref
                                    .read(globalNavigationProvider.notifier)
                                    .toggleNavigationExtended();
                              },
                            ), // 内容区域
                            Expanded(
                              // 使用Stack+Offstage实现懒加载功能区
                              child: Stack(
                                children: List.generate(5, (index) {
                                  // 检查当前索引是否应该被初始化
                                  final shouldInitialize = index == selectedIndex;
                                  final isInitialized =
                                      _initializedSections.contains(index);
  
                                  // 如果当前索引应该被初始化但还未初始化，延迟初始化
                                  if (shouldInitialize && !isInitialized) {
                                    AppLogger.info('初始化功能区', tag: 'MainWindow', data: {
                                      'index': index,
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted &&
                                          !_initializedSections.contains(index)) {
                                        setState(() {
                                          _initializedSections.add(index);
                                        });
                                      }
                                    });
                                  }
  
                                  // 仅当当前选中或已初始化时才创建导航器
                                  if (index == selectedIndex && isInitialized) {
                                    AppLogger.info('构建功能区导航器', tag: 'MainWindow', data: {
                                      'index': index,
                                      'isSelected': true,
                                    });
                                    // 使用KeyedSubtree为每个导航器提供唯一key，避免依赖问题
                                    return KeyedSubtree(
                                      key: ValueKey('navigator_$index'),
                                      child: _buildNavigator(index),
                                    );
                                  } else if (isInitialized) {
                                    // 已初始化但未选中的功能区，使用Offstage隐藏
                                    AppLogger.info('隐藏功能区导航器', tag: 'MainWindow', data: {
                                      'index': index,
                                      'isSelected': false,
                                    });
                                    return Offstage(
                                      offstage: true,
                                      child: KeyedSubtree(
                                        key: ValueKey('navigator_hidden_$index'),
                                        child: _buildNavigator(index),
                                      ),
                                    );
                                  } else {
                                    // 未初始化的功能区，返回空容器
                                    return const SizedBox.shrink();
                                  }
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e, stack) {
      AppLogger.error('M3MainWindow build过程中发生错误', 
        error: e, stackTrace: stack, tag: 'MainWindow');
      return Center(
        child: Text('应用加载错误: $e'),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 当应用进入后台时，执行更积极的内存清理
    if (state == AppLifecycleState.paused) {
      _cleanupUnusedSections();

      // // 记录应用进入后台时的内存状态
      // _memoryTracker.takeMemorySnapshot('应用进入后台');
    } else if (state == AppLifecycleState.resumed) {
      // 记录应用恢复前台时的内存状态
      // _memoryTracker.takeMemorySnapshot('应用恢复前台');
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    setState(() {}); // 触发重建以应用新的亮度设置
  }

  /// 构建导航器
  Widget _buildNavigator(int index) {
    AppLogger.info('构建导航器', tag: 'MainWindow', data: {
      'index': index,
    });
    
    try {
      // 根据索引选择不同的主页
      Widget homePage;
      switch (index) {
        case 0:
          AppLogger.info('创建作品浏览页面', tag: 'MainWindow');
          homePage = const M3WorkBrowsePage();
          break;
        case 1:
          AppLogger.info('创建字符管理页面', tag: 'MainWindow');
          homePage = const M3CharacterManagementPage();
          break;
        case 2:
          AppLogger.info('创建字帖列表页面', tag: 'MainWindow');
          homePage = const M3PracticeListPage();
          break;
        case 3:
          AppLogger.info('创建图库管理页面', tag: 'MainWindow');
          homePage = const M3LibraryManagementPage();
          break;
        case 4:
          AppLogger.info('创建设置页面', tag: 'MainWindow');
          homePage = const M3SettingsPage();
          break;
        default:
          AppLogger.warning('未知的功能区索引', tag: 'MainWindow', data: {
            'index': index,
          });
          homePage = const M3WorkBrowsePage();
      }
  
      // 创建导航器
      AppLogger.info('创建Navigator实例', tag: 'MainWindow', data: {
        'index': index,
        'key': _navigatorKeys[index].toString(),
      });
      
      return Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          AppLogger.info('导航器生成路由', tag: 'MainWindow', data: {
            'index': index,
            'route': settings.name,
          });
          
          // 默认路由返回主页
          if (settings.name == '/' || settings.name == null) {
            return MaterialPageRoute(builder: (context) => homePage);
          }
          
          // 使用全局路由生成器
          return null;
        },
      );
    } catch (e, stack) {
      AppLogger.error('构建导航器失败', 
        error: e, stackTrace: stack, tag: 'MainWindow', data: {
        'index': index,
      });
      return Center(
        child: Text('导航器加载错误: $e'),
      );
    }
  }

  void _cleanupUnusedSections() {
    final currentIndex = ref.read(globalNavigationProvider).currentSectionIndex;
    final lastIndex = _lastSelectedIndex;

    // 使用WidgetsBinding.instance.addPostFrameCallback代替Future.microtask
    // 这样可以确保在正确的Widget生命周期时机执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 找出可以被清理的功能区（除了当前选中的和最后访问的）
      final sectionsToRemove = <int>{};
      for (final index in _initializedSections) {
        // 始终保留当前选中的功能区和最后访问的功能区（提升导航返回体验）
        if (index == currentIndex || index == lastIndex) continue;

        // 使用更可靠的清理策略
        if (_shouldCleanupSection(index)) {
          sectionsToRemove.add(index);
        }
      }

      // 只有当组件仍然挂载在树上时才进行状态更新
      if (mounted && sectionsToRemove.isNotEmpty) {
        setState(() {
          _initializedSections.removeAll(sectionsToRemove);
        });

        // 添加日志以追踪清理行为
        AppLogger.info(
          '清理未使用的功能区',
          data: {
            'sectionsToRemove': sectionsToRemove.toList(),
            'currentIndex': currentIndex,
            'lastIndex': lastIndex,
            'operation': 'memory_cleanup',
          },
          tag: 'Navigation',
        );
      }
    });
  }

  bool _shouldCleanupSection(int index) {
    // 更可靠的清理策略：
    // 1. 不清理低索引值的主要功能区（0和1始终保留）
    // 2. 只清理索引值大于1的功能区
    // 3. 避免随机清理，使用更确定性的方法

    // 保留主要功能区
    if (index <= 1) return false;

    // 其他功能区根据应用的内存状况和使用模式决定是否清理
    // 这里可以基于具体业务逻辑进一步完善
    return true;
  }
}
