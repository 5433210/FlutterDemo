import 'package:freezed_annotation/freezed_annotation.dart';

part 'navigation_history_item.freezed.dart';
part 'navigation_history_item.g.dart';

@freezed
class NavigationHistoryItem with _$NavigationHistoryItem {
  const factory NavigationHistoryItem({
    required int sectionIndex,
    String? routePath,
    Map<String, dynamic>? routeParams,
    required DateTime timestamp,
  }) = _NavigationHistoryItem;

  /// 创建一个新的历史记录项
  factory NavigationHistoryItem.create({
    required int sectionIndex,
    String? routePath,
    Map<String, dynamic>? routeParams,
  }) =>
      NavigationHistoryItem(
        sectionIndex: sectionIndex,
        routePath: routePath,
        routeParams: routeParams,
        timestamp: DateTime.now(),
      );

  factory NavigationHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$NavigationHistoryItemFromJson(json);
}
