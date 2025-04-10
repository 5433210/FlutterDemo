import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/json/character_region_converter.dart';
import 'character_region.dart';

part 'character_entity.freezed.dart';
part 'character_entity.g.dart';

@freezed
class CharacterEntity with _$CharacterEntity {
  const factory CharacterEntity({
    required String id,
    required String workId,
    required String pageId,
    required String character,
    required CharacterRegion region,
    required DateTime createTime,
    required DateTime updateTime,
    @Default(false) bool isFavorite,
    @Default([]) List<String> tags,
    String? note,
  }) = _CharacterEntity;

  factory CharacterEntity.create({
    required String workId,
    required String pageId,
    required CharacterRegion region,
    String character = '',
    List<String> tags = const [],
    String? note,
  }) {
    final now = DateTime.now();
    return CharacterEntity(
      id: region.id,
      workId: workId,
      pageId: pageId,
      character: character,
      region: region,
      createTime: now,
      updateTime: now,
      tags: tags,
      note: note,
    );
  }

  factory CharacterEntity.fromJson(Map<String, dynamic> json) =>
      _$CharacterEntityFromJson(json);
}

// 字符过滤器类
class CharacterFilter extends Equatable {
  final String? workId;
  final String? pageId;
  final String? searchText;
  final List<String>? tags;
  final bool? isFavorite;
  final DateTime? fromDate;
  final DateTime? toDate;
  final SortField? sortBy;
  final SortDirection? sortDirection;
  final int? limit;
  final int? offset;

  const CharacterFilter({
    this.workId,
    this.pageId,
    this.searchText,
    this.tags,
    this.isFavorite,
    this.fromDate,
    this.toDate,
    this.sortBy,
    this.sortDirection,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [
        workId,
        pageId,
        searchText,
        tags,
        isFavorite,
        fromDate,
        toDate,
        sortBy,
        sortDirection,
        limit,
        offset,
      ];

  // 创建副本并更新部分属性
  CharacterFilter copyWith({
    String? workId,
    String? pageId,
    String? searchText,
    List<String>? tags,
    bool? isFavorite,
    DateTime? fromDate,
    DateTime? toDate,
    SortField? sortBy,
    SortDirection? sortDirection,
    int? limit,
    int? offset,
    bool clearWorkId = false,
    bool clearPageId = false,
    bool clearSearchText = false,
    bool clearTags = false,
    bool clearIsFavorite = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearSortBy = false,
    bool clearSortDirection = false,
    bool clearLimit = false,
    bool clearOffset = false,
  }) {
    return CharacterFilter(
      workId: clearWorkId ? null : workId ?? this.workId,
      pageId: clearPageId ? null : pageId ?? this.pageId,
      searchText: clearSearchText ? null : searchText ?? this.searchText,
      tags: clearTags ? null : tags ?? this.tags,
      isFavorite: clearIsFavorite ? null : isFavorite ?? this.isFavorite,
      fromDate: clearFromDate ? null : fromDate ?? this.fromDate,
      toDate: clearToDate ? null : toDate ?? this.toDate,
      sortBy: clearSortBy ? null : sortBy ?? this.sortBy,
      sortDirection:
          clearSortDirection ? null : sortDirection ?? this.sortDirection,
      limit: clearLimit ? null : limit ?? this.limit,
      offset: clearOffset ? null : offset ?? this.offset,
    );
  }
}

// 排序方向
enum SortDirection {
  ascending,
  descending,
}

// 排序字段
enum SortField {
  character,
  createTime,
  updateTime,
}
