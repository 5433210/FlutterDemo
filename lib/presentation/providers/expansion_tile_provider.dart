import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../viewmodels/states/expansion_tile_state.dart';
import '../viewmodels/states/expansion_tile_state_extensions.dart';
import '../viewmodels/states/expansion_tile_state_persistence.dart';

/// ExpansionTile 状态 Provider
final expansionTileProvider =
    StateNotifierProvider<ExpansionTileNotifier, ExpansionTileState>((ref) {
  return ExpansionTileNotifier();
});

/// 便捷 Provider: 获取指定 tile 的展开状态
final tileExpandedProvider = Provider.family<bool, String>((ref, tileId) {
  final state = ref.watch(expansionTileProvider);
  return state.getTileExpanded(tileId);
});

/// 便捷 Provider: 获取带默认值的 tile 展开状态
final tileExpandedWithDefaultProvider =
    Provider.family<bool, ({String tileId, bool defaultExpanded})>(
        (ref, params) {
  final state = ref.watch(expansionTileProvider);
  return state.getTileExpanded(params.tileId,
      defaultExpanded: params.defaultExpanded);
});

/// ExpansionTile 状态 Notifier
class ExpansionTileNotifier extends StateNotifier<ExpansionTileState> {
  ExpansionTileNotifier() : super(ExpansionTileState.initial()) {
    _loadState();
  }

  /// 重置所有 tile 状态
  Future<void> clearAll() async {
    try {
      state = state.clearAll();
      await ExpansionTileStatePersistence.clear();

      AppLogger.debug('All tile states cleared', tag: 'ExpansionTileProvider');
    } catch (e, stack) {
      AppLogger.error('Failed to clear all tile states',
          tag: 'ExpansionTileProvider', error: e, stackTrace: stack);
    }
  }

  /// 获取指定 tile 的展开状态
  bool getTileExpanded(String tileId, {bool defaultExpanded = true}) {
    return state.getTileExpanded(tileId, defaultExpanded: defaultExpanded);
  }

  /// 强制重新加载状态
  Future<void> reload() async {
    await _loadState();
  }

  /// 批量设置多个 tile 状态
  Future<void> setMultipleTiles(Map<String, bool> tileStates) async {
    try {
      state = state.setMultipleTiles(tileStates);
      await state.persist();

      AppLogger.debug('Multiple tile states updated',
          tag: 'ExpansionTileProvider', data: {'tileCount': tileStates.length});
    } catch (e, stack) {
      AppLogger.error('Failed to update multiple tile states',
          tag: 'ExpansionTileProvider', error: e, stackTrace: stack);
    }
  }

  /// 设置指定 tile 的展开状态
  Future<void> setTileExpanded(String tileId, bool expanded) async {
    try {
      state = state.setTileExpanded(tileId, expanded);
      await state.persist();

      AppLogger.debug('Tile state updated',
          tag: 'ExpansionTileProvider',
          data: {'tileId': tileId, 'expanded': expanded});
    } catch (e, stack) {
      AppLogger.error('Failed to update tile state',
          tag: 'ExpansionTileProvider', error: e, stackTrace: stack);
    }
  }

  /// 切换指定 tile 的展开状态
  Future<void> toggleTile(String tileId, {bool defaultExpanded = true}) async {
    try {
      final currentState =
          state.getTileExpanded(tileId, defaultExpanded: defaultExpanded);
      await setTileExpanded(tileId, !currentState);
    } catch (e, stack) {
      AppLogger.error('Failed to toggle tile state',
          tag: 'ExpansionTileProvider', error: e, stackTrace: stack);
    }
  }

  /// 加载保存的状态
  Future<void> _loadState() async {
    try {
      final savedState = await ExpansionTileStatePersistence.restore();
      state = savedState;
      AppLogger.debug('ExpansionTile state loaded successfully',
          tag: 'ExpansionTileProvider');
    } catch (e, stack) {
      AppLogger.error('Failed to load ExpansionTile state',
          tag: 'ExpansionTileProvider', error: e, stackTrace: stack);
    }
  }
}
