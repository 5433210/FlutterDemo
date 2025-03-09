import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_filter.freezed.dart';
part 'practice_filter.g.dart';

/// 字帖练习过滤器
@freezed
class PracticeFilter with _$PracticeFilter {
  const factory PracticeFilter({
    /// 标题关键词
    String? keyword,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 开始时间
    @JsonKey(name: 'start_time') DateTime? startTime,

    /// 结束时间
    @JsonKey(name: 'end_time') DateTime? endTime,

    /// 状态
    String? status,

    /// 分页大小
    @Default(20) int limit,

    /// 偏移量
    @Default(0) int offset,

    /// 排序字段
    @Default('create_time') String sortField,

    /// 排序方向(asc/desc)
    @Default('desc') String sortOrder,
  }) = _PracticeFilter;

  /// 从JSON创建实例
  factory PracticeFilter.fromJson(Map<String, dynamic> json) =>
      _$PracticeFilterFromJson(json);

  const PracticeFilter._();
}
