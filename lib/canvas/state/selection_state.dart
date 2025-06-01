// filepath: lib/canvas/state/selection_state.dart

/// 选择状态管理
class SelectionState {
  final Set<String> _selectedIds;

  const SelectionState({
    Set<String>? selectedIds,
  }) : _selectedIds = selectedIds ?? const {};

  /// 获取第一个选中的元素ID（仅在单选时有效）
  String? get firstSelectedId =>
      _selectedIds.isNotEmpty ? _selectedIds.first : null;

  /// 是否有选中的元素
  bool get hasSelection => _selectedIds.isNotEmpty;

  /// 是否为单选
  bool get isSingleSelection => _selectedIds.length == 1;

  /// 选中的元素ID集合
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// 选中元素数量
  int get selectionCount => _selectedIds.length;

  /// 添加元素到选择集合
  SelectionState addToSelection(String id) {
    final newSelectedIds = Set<String>.from(_selectedIds);
    newSelectedIds.add(id);
    return SelectionState(selectedIds: newSelectedIds);
  }

  /// 清除所有选择
  SelectionState clearSelection() {
    return const SelectionState();
  }

  /// 检查元素是否被选中
  bool isSelected(String id) => _selectedIds.contains(id);

  /// 从选择集合中移除元素
  SelectionState removeFromSelection(String id) {
    final newSelectedIds = Set<String>.from(_selectedIds);
    newSelectedIds.remove(id);
    return SelectionState(selectedIds: newSelectedIds);
  }

  /// 全选（根据提供的所有元素ID）
  SelectionState selectAll(Iterable<String> allElementIds) {
    return SelectionState(selectedIds: Set.from(allElementIds));
  }

  /// 批量选择元素
  SelectionState selectMultiple(Iterable<String> ids) {
    return SelectionState(selectedIds: Set.from(ids));
  }

  /// 选中单个元素（清除其他选择）
  SelectionState selectSingle(String id) {
    return SelectionState(selectedIds: {id});
  }

  /// 切换元素选择状态
  SelectionState toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      return removeFromSelection(id);
    } else {
      return addToSelection(id);
    }
  }
}
