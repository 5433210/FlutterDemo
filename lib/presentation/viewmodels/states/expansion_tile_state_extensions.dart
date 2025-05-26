import 'expansion_tile_state.dart';

/// 扩展方法为 ExpansionTileState 提供便捷操作
extension ExpansionTileStateExtensions on ExpansionTileState {
  /// 重置所有 tile 状态
  ExpansionTileState clearAll() {
    return const ExpansionTileState();
  }

  /// 获取指定 tile 的展开状态
  bool getTileExpanded(String tileId, {bool defaultExpanded = true}) {
    return tileStates[tileId] ?? defaultExpanded;
  }

  /// 批量设置多个 tile 状态
  ExpansionTileState setMultipleTiles(Map<String, bool> states) {
    final newStates = Map<String, bool>.from(tileStates);
    newStates.addAll(states);
    return copyWith(tileStates: newStates);
  }

  /// 更新指定 tile 的展开状态
  ExpansionTileState setTileExpanded(String tileId, bool expanded) {
    final newStates = Map<String, bool>.from(tileStates);
    newStates[tileId] = expanded;
    return copyWith(tileStates: newStates);
  }

  /// 切换指定 tile 的展开状态
  ExpansionTileState toggleTile(String tileId, {bool defaultExpanded = true}) {
    final currentState =
        getTileExpanded(tileId, defaultExpanded: defaultExpanded);
    return setTileExpanded(tileId, !currentState);
  }
}
