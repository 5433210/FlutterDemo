// filepath: lib/canvas/state/selection_state.dart

/// 元素选择状态
class SelectionState {
  final Set<String> _selectedIds;

  const SelectionState({
    Set<String>? selectedIds,
  }) : _selectedIds = selectedIds ?? const {};

  /// 是否有选中的元素
  bool get hasSelection => _selectedIds.isNotEmpty;

  /// 所有选中的元素ID
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// 选中的元素数量
  int get selectionCount => _selectedIds.length;

  /// 添加多个选中元素
  SelectionState addAllToSelection(Iterable<String> ids) {
    final newSelection = Set<String>.from(_selectedIds);
    newSelection.addAll(ids);
    return SelectionState(selectedIds: newSelection);
  }

  /// 添加选中的元素
  SelectionState addToSelection(String id) {
    final newSelection = Set<String>.from(_selectedIds);
    newSelection.add(id);
    return SelectionState(selectedIds: newSelection);
  }

  /// 清除选择
  SelectionState clearSelection() {
    return const SelectionState();
  }

  /// 检查元素是否被选中
  bool isSelected(String id) => _selectedIds.contains(id);

  /// 从选择中移除
  SelectionState removeFromSelection(String id) {
    final newSelection = Set<String>.from(_selectedIds);
    newSelection.remove(id);
    return SelectionState(selectedIds: newSelection);
  }

  /// 替换选择
  SelectionState replaceSelection(String id) {
    return SelectionState(selectedIds: {id});
  }

  /// 替换为多个选择
  SelectionState replaceSelectionWithMultiple(Iterable<String> ids) {
    return SelectionState(selectedIds: Set<String>.from(ids));
  }

  /// 切换选择状态
  SelectionState toggleSelection(String id) {
    final newSelection = Set<String>.from(_selectedIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }
    return SelectionState(selectedIds: newSelection);
  }
}
