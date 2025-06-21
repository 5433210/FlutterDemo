import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/work/work_entity.dart';
import '../../domain/models/character/character_entity.dart';
import '../../infrastructure/logging/logger.dart';

part 'batch_selection_provider.freezed.dart';

/// 批量选择状态
@freezed
class BatchSelectionState with _$BatchSelectionState {
  const factory BatchSelectionState({
    /// 是否启用批量模式
    @Default(false) bool isBatchMode,
    
    /// 选中的作品ID列表
    @Default({}) Set<String> selectedWorkIds,
    
    /// 选中的集字ID列表
    @Default({}) Set<String> selectedCharacterIds,
    
    /// 当前页面类型
    @Default(PageType.works) PageType pageType,
    
    /// 是否全选状态
    @Default(false) bool isAllSelected,
    
    /// 最后操作时间
    DateTime? lastOperationTime,
  }) = _BatchSelectionState;
  
  const BatchSelectionState._();
  
  /// 是否有选中项
  bool get hasSelection => selectedWorkIds.isNotEmpty || selectedCharacterIds.isNotEmpty;
  
  /// 选中项总数
  int get totalSelected => selectedWorkIds.length + selectedCharacterIds.length;
  
  /// 根据页面类型获取选中数量
  int get selectedCount {
    switch (pageType) {
      case PageType.works:
        return selectedWorkIds.length;
      case PageType.characters:
        return selectedCharacterIds.length;
    }
  }
}

/// 页面类型枚举
enum PageType {
  /// 作品页面
  works,
  /// 集字页面
  characters,
}

/// 批量选择操作类型
enum BatchOperation {
  /// 导出
  export,
  /// 删除
  delete,
  /// 导入
  import,
}

/// 批量选择状态管理器
class BatchSelectionNotifier extends StateNotifier<BatchSelectionState> {
  BatchSelectionNotifier() : super(const BatchSelectionState());

  /// 切换批量模式
  void toggleBatchMode() {
    final newBatchMode = !state.isBatchMode;
    
    AppLogger.info(
      '切换批量模式',
      data: {
        'oldBatchMode': state.isBatchMode,
        'newBatchMode': newBatchMode,
        'pageType': state.pageType.name,
        'previousSelectedCount': state.selectedCount,
      },
      tag: 'batch_selection',
    );
    
    state = state.copyWith(
      isBatchMode: newBatchMode,
      selectedWorkIds: {},
      selectedCharacterIds: {},
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 设置页面类型
  void setPageType(PageType pageType) {
    if (state.pageType == pageType) return;
    
    AppLogger.debug(
      '切换页面类型',
      data: {
        'oldPageType': state.pageType.name,
        'newPageType': pageType.name,
        'isBatchMode': state.isBatchMode,
      },
      tag: 'batch_selection',
    );
    
    state = state.copyWith(
      pageType: pageType,
      selectedWorkIds: {},
      selectedCharacterIds: {},
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 切换作品选择状态
  void toggleWorkSelection(String workId) {
    if (!state.isBatchMode || state.pageType != PageType.works) return;
    
    final newSelectedIds = Set<String>.from(state.selectedWorkIds);
    final wasSelected = newSelectedIds.contains(workId);
    
    if (wasSelected) {
      newSelectedIds.remove(workId);
    } else {
      newSelectedIds.add(workId);
    }
    
    AppLogger.debug(
      '切换作品选择',
      data: {
        'workId': workId,
        'wasSelected': wasSelected,
        'newSelectedCount': newSelectedIds.length,
      },
      tag: 'batch_selection',
    );
    
    state = state.copyWith(
      selectedWorkIds: newSelectedIds,
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 切换集字选择状态
  void toggleCharacterSelection(String characterId) {
    if (!state.isBatchMode || state.pageType != PageType.characters) return;
    
    final newSelectedIds = Set<String>.from(state.selectedCharacterIds);
    final wasSelected = newSelectedIds.contains(characterId);
    
    if (wasSelected) {
      newSelectedIds.remove(characterId);
    } else {
      newSelectedIds.add(characterId);
    }
    
    AppLogger.debug(
      '切换集字选择',
      data: {
        'characterId': characterId,
        'wasSelected': wasSelected,
        'newSelectedCount': newSelectedIds.length,
      },
      tag: 'batch_selection',
    );
    
    state = state.copyWith(
      selectedCharacterIds: newSelectedIds,
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 全选
  void selectAll(List<String> allIds) {
    if (!state.isBatchMode) return;
    
    AppLogger.info(
      '全选操作',
      data: {
        'pageType': state.pageType.name,
        'totalItems': allIds.length,
        'previousSelectedCount': state.selectedCount,
      },
      tag: 'batch_selection',
    );
    
    switch (state.pageType) {
      case PageType.works:
        state = state.copyWith(
          selectedWorkIds: Set<String>.from(allIds),
          isAllSelected: true,
          lastOperationTime: DateTime.now(),
        );
        break;
      case PageType.characters:
        state = state.copyWith(
          selectedCharacterIds: Set<String>.from(allIds),
          isAllSelected: true,
          lastOperationTime: DateTime.now(),
        );
        break;
    }
  }

  /// 取消选择
  void clearSelection() {
    if (!state.hasSelection) return;
    
    AppLogger.info(
      '清除选择',
      data: {
        'pageType': state.pageType.name,
        'previousSelectedCount': state.selectedCount,
      },
      tag: 'batch_selection',
    );
    
    state = state.copyWith(
      selectedWorkIds: {},
      selectedCharacterIds: {},
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 批量选择作品
  void selectWorks(List<String> workIds) {
    if (!state.isBatchMode || state.pageType != PageType.works) return;
    
    AppLogger.debug(
      '批量选择作品',
      data: {
        'workIds': workIds,
        'count': workIds.length,
      },
      tag: 'batch_selection',
    );
    
    final newSelectedIds = Set<String>.from(state.selectedWorkIds);
    newSelectedIds.addAll(workIds);
    
    state = state.copyWith(
      selectedWorkIds: newSelectedIds,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 批量选择集字
  void selectCharacters(List<String> characterIds) {
    if (!state.isBatchMode || state.pageType != PageType.characters) return;
    
    AppLogger.debug(
      '批量选择集字',
      data: {
        'characterIds': characterIds,
        'count': characterIds.length,
      },
      tag: 'batch_selection',
    );
    
    final newSelectedIds = Set<String>.from(state.selectedCharacterIds);
    newSelectedIds.addAll(characterIds);
    
    state = state.copyWith(
      selectedCharacterIds: newSelectedIds,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 批量取消选择作品
  void deselectWorks(List<String> workIds) {
    if (!state.isBatchMode || state.pageType != PageType.works) return;
    
    AppLogger.debug(
      '批量取消选择作品',
      data: {
        'workIds': workIds,
        'count': workIds.length,
      },
      tag: 'batch_selection',
    );
    
    final newSelectedIds = Set<String>.from(state.selectedWorkIds);
    newSelectedIds.removeAll(workIds);
    
    state = state.copyWith(
      selectedWorkIds: newSelectedIds,
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 批量取消选择集字
  void deselectCharacters(List<String> characterIds) {
    if (!state.isBatchMode || state.pageType != PageType.characters) return;
    
    AppLogger.debug(
      '批量取消选择集字',
      data: {
        'characterIds': characterIds,
        'count': characterIds.length,
      },
      tag: 'batch_selection',
    );
    
    final newSelectedIds = Set<String>.from(state.selectedCharacterIds);
    newSelectedIds.removeAll(characterIds);
    
    state = state.copyWith(
      selectedCharacterIds: newSelectedIds,
      isAllSelected: false,
      lastOperationTime: DateTime.now(),
    );
  }

  /// 检查作品是否被选中
  bool isWorkSelected(String workId) {
    return state.isBatchMode && 
           state.pageType == PageType.works && 
           state.selectedWorkIds.contains(workId);
  }

  /// 检查集字是否被选中
  bool isCharacterSelected(String characterId) {
    return state.isBatchMode && 
           state.pageType == PageType.characters && 
           state.selectedCharacterIds.contains(characterId);
  }

  /// 更新全选状态
  void updateAllSelectedState(int totalItems) {
    final currentSelected = state.selectedCount;
    final newIsAllSelected = currentSelected > 0 && currentSelected == totalItems;
    
    if (state.isAllSelected != newIsAllSelected) {
      state = state.copyWith(isAllSelected: newIsAllSelected);
    }
  }

  /// 重置状态
  void reset() {
    AppLogger.debug(
      '重置批量选择状态',
      data: {
        'previousBatchMode': state.isBatchMode,
        'previousSelectedCount': state.selectedCount,
      },
      tag: 'batch_selection',
    );
    
    state = const BatchSelectionState();
  }

  /// 获取选择统计信息
  Map<String, dynamic> getSelectionStats() {
    return {
      'isBatchMode': state.isBatchMode,
      'pageType': state.pageType.name,
      'selectedWorks': state.selectedWorkIds.length,
      'selectedCharacters': state.selectedCharacterIds.length,
      'totalSelected': state.totalSelected,
      'isAllSelected': state.isAllSelected,
      'hasSelection': state.hasSelection,
      'lastOperationTime': state.lastOperationTime?.toIso8601String(),
    };
  }
}

/// 批量选择状态Provider
final batchSelectionProvider = StateNotifierProvider<BatchSelectionNotifier, BatchSelectionState>((ref) {
  return BatchSelectionNotifier();
});

/// 作品页面批量选择Provider（便捷访问）
final worksBatchSelectionProvider = Provider<BatchSelectionState>((ref) {
  final state = ref.watch(batchSelectionProvider);
  return state.pageType == PageType.works ? state : state.copyWith(pageType: PageType.works);
});

/// 集字页面批量选择Provider（便捷访问）
final charactersBatchSelectionProvider = Provider<BatchSelectionState>((ref) {
  final state = ref.watch(batchSelectionProvider);
  return state.pageType == PageType.characters ? state : state.copyWith(pageType: PageType.characters);
});

/// 批量操作可用性Provider
final batchOperationsAvailableProvider = Provider<Map<BatchOperation, bool>>((ref) {
  final state = ref.watch(batchSelectionProvider);
  
  return {
    BatchOperation.export: state.hasSelection,
    BatchOperation.delete: state.hasSelection,
    BatchOperation.import: true, // 导入总是可用
  };
});

/// 选择摘要Provider
final selectionSummaryProvider = Provider<String>((ref) {
  final state = ref.watch(batchSelectionProvider);
  
  if (!state.isBatchMode) return '';
  if (!state.hasSelection) return '未选择项目';
  
  switch (state.pageType) {
    case PageType.works:
      if (state.isAllSelected) {
        return '已选择全部 ${state.selectedWorkIds.length} 个作品';
      }
      return '已选择 ${state.selectedWorkIds.length} 个作品';
    case PageType.characters:
      if (state.isAllSelected) {
        return '已选择全部 ${state.selectedCharacterIds.length} 个集字';
      }
      return '已选择 ${state.selectedCharacterIds.length} 个集字';
  }
}); 