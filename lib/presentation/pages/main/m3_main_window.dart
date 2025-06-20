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
  Widget build(BuildContext context) {
    // 从全局导航状态读取状态
    final navState = ref.watch(globalNavigationProvider);
    final selectedIndex = navState.currentSectionIndex;

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

    return LayoutBuilder(
      builder: (context, constraints) {
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
                                  // 使用KeyedSubtree为每个导航器提供唯一key，避免依赖问题
                                  return KeyedSubtree(
                                    key: ValueKey('navigator_$index'),
                                    child: _buildNavigator(index),
                                  );
                                } else if (isInitialized &&
                                    index != selectedIndex) {
                                  // 已初始化但非当前选中的功能区隐藏显示
                                  return Offstage(
                                    offstage: true,
                                    child: KeyedSubtree(
                                      key: ValueKey('navigator_$index'),
                                      child: _buildNavigator(index),
                                    ),
                                  );
                                } else {
                                  // 未初始化的功能区返回固定Key的空容器，确保Widget树结构稳定
                                  return KeyedSubtree(
                                    key: ValueKey('empty_$index'),
                                    child: const SizedBox.shrink(),
                                  );
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

  @override
  void dispose() {
    // 取消定时器
    _memoryCleanupTimer?.cancel();

    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);

    // 清理所有导航器的GlobalKey引用，确保没有遗留的依赖项
    for (final navigatorKey in _navigatorKeys.values) {
      // 尝试通过导航器的currentState访问来触发任何未完成的清理
      try {
        navigatorKey.currentState?.dispose();
      } catch (e) {
        // 忽略清理过程中的异常，因为某些导航器可能已经被销毁
        AppLogger.warning(
          '导航器清理时发生异常',
          data: {
            'error': e.toString(),
            'operation': 'navigator_cleanup',
          },
          tag: 'Navigation',
        );
      }
    }

    // 清空初始化集合
    _initializedSections.clear();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 设置定时器，每120秒检查一次非活跃的功能区并释放资源
    _memoryCleanupTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      _cleanupUnusedSections();
    });
  }

  // 构建单个功能区的导航器
  Widget _buildNavigator(int sectionIndex) {
    return Navigator(
      key: _navigatorKeys[sectionIndex],
      // 监听路由变化，记录到全局导航服务
      onGenerateRoute: (settings) {
        // 记录当前功能区路由变化
        if (settings.name != null && settings.name != '/') {
          ref.read(globalNavigationProvider.notifier).recordSectionRoute(
              sectionIndex, settings.name!,
              params: settings.arguments is Map<String, dynamic>
                  ? settings.arguments as Map<String, dynamic>
                  : null);
        }

        // 根据不同功能区生成不同的路由
        switch (sectionIndex) {
          case 0: // 作品浏览
            if (settings.name == AppRoutes.workDetail &&
                settings.arguments != null) {
              final workId = settings.arguments as String;
              return MaterialPageRoute<bool>(
                builder: (context) => M3WorkDetailPage(workId: workId),
              );
            }
            if (settings.name == AppRoutes.characterCollection &&
                settings.arguments != null) {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute<bool>(
                builder: (context) => M3CharacterCollectionPage(
                  workId: args['workId']!,
                  initialPageId: args['pageId']!,
                  initialCharacterId: args['characterId'],
                ),
              );
            }
            // Default to work browse page
            return MaterialPageRoute(
              builder: (context) => const M3WorkBrowsePage(),
            );

          case 1: // 字符管理
            if (settings.name == AppRoutes.characterCollection &&
                settings.arguments != null) {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute<bool>(
                builder: (context) => M3CharacterCollectionPage(
                  workId: args['workId']!,
                  initialPageId: args['pageId']!,
                  initialCharacterId: args['characterId'],
                ),
              );
            }
            if (settings.name == AppRoutes.workDetail &&
                settings.arguments != null) {
              // 支持两种参数类型：字符串和Map
              String workId;
              if (settings.arguments is String) {
                workId = settings.arguments as String;
              } else if (settings.arguments is Map<String, String>) {
                final args = settings.arguments as Map<String, String>;
                workId = args['workId']!;
              } else {
                workId = '';
              }

              return MaterialPageRoute<bool>(
                builder: (context) => M3WorkDetailPage(
                  workId: workId,
                ),
              );
            }
            // Default to character management page
            return MaterialPageRoute(
              builder: (context) => const M3CharacterManagementPage(),
            );
          case 2: // 字帖列表
            if (settings.name == AppRoutes.practiceEdit) {
              String practiceId = '';
              if (settings.arguments != null) {
                practiceId = settings.arguments as String;
              }
              return MaterialPageRoute<dynamic>(
                builder: (context) => M3PracticeEditPage(
                  practiceId: practiceId.isNotEmpty ? practiceId : null,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const M3PracticeListPage(),
            );

          case 3: // 图库管理
            return MaterialPageRoute(
              builder: (context) => const M3LibraryManagementPage(),
            );

          case 4: // 设置
            return MaterialPageRoute(
              builder: (context) => const M3SettingsPage(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => Center(
                  child: Text(AppLocalizations.of(context).pageNotImplemented)),
            );
        }
      },
    );
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
