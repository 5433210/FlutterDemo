import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_settings.freezed.dart';
part 'pagination_settings.g.dart';

/// 分页设置模型
@freezed
class PaginationSettings with _$PaginationSettings {
  const factory PaginationSettings({
    /// 页面标识符（用于区分不同页面的设置）
    required String pageId,
    /// 每页项数
    @Default(20) int pageSize,
    /// 上次更新时间
    DateTime? lastUpdated,
  }) = _PaginationSettings;

  factory PaginationSettings.fromJson(Map<String, dynamic> json) =>
      _$PaginationSettingsFromJson(json);
}

/// 所有分页设置的集合
@freezed
class AllPaginationSettings with _$AllPaginationSettings {
  const factory AllPaginationSettings({
    /// 按页面ID映射的分页设置
    @Default({}) Map<String, PaginationSettings> settings,
    /// 上次更新时间
    DateTime? lastUpdated,
  }) = _AllPaginationSettings;

  factory AllPaginationSettings.fromJson(Map<String, dynamic> json) =>
      _$AllPaginationSettingsFromJson(json);
}