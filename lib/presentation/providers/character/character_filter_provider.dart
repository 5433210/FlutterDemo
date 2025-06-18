import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/sort_field.dart';
import '../../../domain/models/character/character_filter.dart';
import '../../../domain/models/common/date_range_filter.dart';
import '../../../domain/models/common/sort_option.dart';
import 'character_management_provider.dart';

/// 字符筛选状态提供器
final characterFilterProvider =
    StateNotifierProvider<CharacterFilterNotifier, CharacterFilter>((ref) {
  return CharacterFilterNotifier(ref);
});

/// 字符筛选状态管理
class CharacterFilterNotifier extends StateNotifier<CharacterFilter> {
  final Ref _ref;

  CharacterFilterNotifier(this._ref) : super(const CharacterFilter());

  /// 添加单个标签
  void addTag(String tag) {
    if (state.tags.contains(tag)) return;
    final newTags = [...state.tags, tag];
    state = state.copyWith(tags: newTags);
    _notifyFilterChange();
  }

  /// 删除单个标签
  void removeTag(String tag) {
    if (!state.tags.contains(tag)) return;
    final newTags = [...state.tags]..remove(tag);
    state = state.copyWith(tags: newTags);
    _notifyFilterChange();
  }

  /// 重置所有筛选条件
  void resetFilters() {
    state = const CharacterFilter();
    _notifyFilterChange();
  }

  /// 设置排序方向
  void setSortDirection(bool descending) {
    if (state.sortOption.descending == descending) return;
    state = state.copyWith(
      sortOption: state.sortOption.copyWith(descending: descending),
    );
    _notifyFilterChange();
  }

  void setSortField(SortField field) {
    if (state.sortOption.field == field) return;
    state = state.copyWith(
      sortOption: state.sortOption.copyWith(field: field),
    );
    _notifyFilterChange();
  }

  /// 切换排序方向
  void toggleSortDirection() {
    final newDirection = !state.sortOption.descending;
    state = state.copyWith(
      sortOption: state.sortOption.copyWith(descending: newDirection),
    );
    _notifyFilterChange();
  }
  /// 更新书法风格筛选
  void updateCalligraphyStyles(String? style) {
    if (style == null) {
      state = state.copyWith(style: null);
    } else if (state.style == style) {
      return;
    } else {
      state = state.copyWith(style: style);
    }
    _notifyFilterChange();
  }

  /// 更新收集时间预设
  void updateCollectionDatePreset(DateRangePreset preset) {
    if (state.collectionDatePreset == preset) return;
    state = state.copyWith(collectionDatePreset: preset);
    _notifyFilterChange();
  }

  /// 更新收集时间范围
  void updateCollectionDateRange(DateTimeRange? dateRange) {
    if (state.collectionDateRange == dateRange) return;
    state = state.copyWith(collectionDateRange: dateRange);
    _notifyFilterChange();
  }

  /// 更新创作时间预设
  void updateCreationDatePreset(DateRangePreset preset) {
    if (state.creationDatePreset == preset) return;
    state = state.copyWith(creationDatePreset: preset);
    _notifyFilterChange();
  }

  /// 更新自定义创作时间范围
  void updateCreationDateRange(DateTimeRange? dateRange) {
    if (state.creationDateRange == dateRange) return;
    state = state.copyWith(creationDateRange: dateRange);
    _notifyFilterChange();
  }

  /// 更新收藏筛选
  void updateFavoriteFilter(bool? isFavorite) {
    if (state.isFavorite == isFavorite) return;
    state = state.copyWith(isFavorite: isFavorite);
    _notifyFilterChange();
  }

  /// 更新分页限制
  void updateLimit(int? limit) {
    if (state.limit == limit) return;
    state = state.copyWith(limit: limit);
    _notifyFilterChange();
  }

  /// 更新分页偏移
  void updateOffset(int? offset) {
    if (state.offset == offset) return;
    state = state.copyWith(offset: offset);
    _notifyFilterChange();
  }

  /// 更新搜索文本
  void updateSearchText(String? text) {
    if (state.searchText == text) return;

    // 保存搜索文本以用于显示
    state = state.copyWith(searchText: text);

    // 不再清除标签，让搜索文本同时查找字符和标签
    _notifyFilterChange();
  }

  /// 更新排序选项
  void updateSortOption(SortOption sortOption) {
    if (state.sortOption == sortOption) return;
    state = state.copyWith(sortOption: sortOption);
    _notifyFilterChange();
  }

  /// 更新标签筛选
  void updateTags(List<String> tags) {
    if (listEquals(state.tags, tags)) return;
    state = state.copyWith(tags: tags);
    _notifyFilterChange();
  }

  /// 更新作品ID筛选
  void updateWorkId(String? workId) {
    if (state.workId == workId) return;
    state = state.copyWith(workId: workId);
    _notifyFilterChange();
  }
  /// 更新书写工具筛选
  void updateWritingTools(String? tool) {
    if (tool == null) {
      state = state.copyWith(tool: null);
    } else if (state.tool == tool) {
      return;
    } else {
      state = state.copyWith(tool: tool);
    }
    _notifyFilterChange();
  }

  // Helper method to notify management provider about filter changes
  void _notifyFilterChange() {
    // Notify the character management provider to update with new filters
    _ref.read(characterManagementProvider.notifier).updateFilter(state);
  }
}
