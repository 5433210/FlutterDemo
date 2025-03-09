import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/sort_field.dart';

part 'sort_option.freezed.dart';
part 'sort_option.g.dart';

SortField _sortFieldFromJson(dynamic value) {
  if (value is SortField) return value;
  final str = value?.toString() ?? '';
  return SortFieldParsing.fromString(str);
}

String _sortFieldToJson(SortField field) => field.value;

/// 排序选项
@freezed
class SortOption with _$SortOption {
  /// 按创建时间降序(默认排序)
  static const defaultOption = SortOption();

  const factory SortOption({
    @Default(SortField.createTime)
    @JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
    SortField field,
    @Default(true) bool descending,
  }) = _SortOption;

  factory SortOption.fromJson(Map<String, dynamic> json) =>
      _$SortOptionFromJson(json);

  const SortOption._();

  /// 是否是默认排序
  bool get isDefault => field == SortField.createTime && descending;

  /// 切换排序方向
  SortOption toggleDirection() => copyWith(descending: !descending);

  /// 切换排序字段
  SortOption withField(SortField field) => copyWith(field: field);
}
