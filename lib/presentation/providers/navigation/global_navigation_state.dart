import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/navigation/navigation_history_item.dart';

part 'global_navigation_state.freezed.dart';
part 'global_navigation_state.g.dart';

/// 全局导航状态
@freezed
class GlobalNavigationState with _$GlobalNavigationState {
  const factory GlobalNavigationState({
    /// 当前功能区索引
    @Default(0) int currentSectionIndex,

    /// 导航历史记录
    @Default([]) List<NavigationHistoryItem> history,

    /// 各功能区当前路由状态
    @Default({}) Map<int, String?> sectionRoutes,

    /// 导航栏展开状态
    @Default(true) bool isNavigationExtended,

    /// 是否正在导航中状态
    @Default(false) bool isNavigating,

    /// 上次导航时间戳
    DateTime? lastNavigationTime,

    /// 各功能区内部后退栈状态
    @Default({}) Map<int, bool> canPopInSection,
  }) = _GlobalNavigationState;

  /// Create a GlobalNavigationState instance from a JSON object
  factory GlobalNavigationState.fromJson(Map<String, dynamic> json) =>
      _$GlobalNavigationStateFromJson(json);

  /// Copy constructor with internal methods
  const GlobalNavigationState._();

  /// 检查是否可以返回上一个功能区
  bool get canNavigateBack => history.isNotEmpty;

  /// 检查指定功能区是否可以内部后退
  bool canPopInSectionIndex(int sectionIndex) =>
      canPopInSection[sectionIndex] ?? false;

  /// 获取指定功能区的当前路由
  String? getSectionRoute(int sectionIndex) => sectionRoutes[sectionIndex];
}
