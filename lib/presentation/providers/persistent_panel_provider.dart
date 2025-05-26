import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../viewmodels/states/persistent_panel_state.dart';
import '../viewmodels/states/persistent_panel_state_persistence.dart';

/// Convenient Provider: Get panel width for a specific panel ID
final panelWidthProvider =
    Provider.family<double, ({String panelId, double defaultWidth})>(
        (ref, params) {
  final state = ref.watch(persistentPanelProvider);
  return state.getPanelWidth(params.panelId, defaultWidth: params.defaultWidth);
});

/// PersistentPanel state Provider
final persistentPanelProvider =
    StateNotifierProvider<PersistentPanelNotifier, PersistentPanelState>((ref) {
  return PersistentPanelNotifier();
});

/// Convenient Provider: Get sidebar state for a specific sidebar ID
final sidebarStateProvider =
    Provider.family<bool, ({String sidebarId, bool defaultState})>(
        (ref, params) {
  final state = ref.watch(persistentPanelProvider);
  return state.getSidebarState(params.sidebarId,
      defaultState: params.defaultState);
});

/// PersistentPanel state Notifier
class PersistentPanelNotifier extends StateNotifier<PersistentPanelState> {
  PersistentPanelNotifier() : super(PersistentPanelState.initial()) {
    _loadState();
  }

  /// Clear all states
  Future<void> clearAll() async {
    try {
      state = state.clearAll();
      await PersistentPanelStatePersistence.clear();

      AppLogger.debug('All panel states cleared',
          tag: 'PersistentPanelProvider');
    } catch (e, stack) {
      AppLogger.error('Failed to clear all panel states',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Get panel width
  double getPanelWidth(String panelId, {double defaultWidth = 300.0}) {
    return state.getPanelWidth(panelId, defaultWidth: defaultWidth);
  }

  /// Get sidebar state
  bool getSidebarState(String sidebarId, {bool defaultState = false}) {
    return state.getSidebarState(sidebarId, defaultState: defaultState);
  }

  /// Force reload state
  Future<void> reload() async {
    await _loadState();
  }

  /// Remove panel width
  Future<void> removePanelWidth(String panelId) async {
    try {
      state = state.removePanelWidth(panelId);
      await state.persist();

      AppLogger.debug('Panel width removed',
          tag: 'PersistentPanelProvider', data: {'panelId': panelId});
    } catch (e, stack) {
      AppLogger.error('Failed to remove panel width',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Remove sidebar state
  Future<void> removeSidebarState(String sidebarId) async {
    try {
      state = state.removeSidebarState(sidebarId);
      await state.persist();

      AppLogger.debug('Sidebar state removed',
          tag: 'PersistentPanelProvider', data: {'sidebarId': sidebarId});
    } catch (e, stack) {
      AppLogger.error('Failed to remove sidebar state',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Set multiple panel widths
  Future<void> setMultiplePanelWidths(Map<String, double> widths) async {
    try {
      state = state.setMultiplePanelWidths(widths);
      await state.persist();

      AppLogger.debug('Multiple panel widths updated',
          tag: 'PersistentPanelProvider', data: {'panelCount': widths.length});
    } catch (e, stack) {
      AppLogger.error('Failed to update multiple panel widths',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Set multiple sidebar states
  Future<void> setMultipleSidebarStates(Map<String, bool> states) async {
    try {
      state = state.setMultipleSidebarStates(states);
      await state.persist();

      AppLogger.debug('Multiple sidebar states updated',
          tag: 'PersistentPanelProvider',
          data: {'sidebarCount': states.length});
    } catch (e, stack) {
      AppLogger.error('Failed to update multiple sidebar states',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Set panel width
  Future<void> setPanelWidth(String panelId, double width) async {
    try {
      state = state.setPanelWidth(panelId, width);
      await state.persist();

      AppLogger.debug('Panel width updated',
          tag: 'PersistentPanelProvider',
          data: {'panelId': panelId, 'width': width});
    } catch (e, stack) {
      AppLogger.error('Failed to update panel width',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Set sidebar state
  Future<void> setSidebarState(String sidebarId, bool isOpen) async {
    try {
      state = state.setSidebarState(sidebarId, isOpen);
      await state.persist();

      AppLogger.debug('Sidebar state updated',
          tag: 'PersistentPanelProvider',
          data: {'sidebarId': sidebarId, 'isOpen': isOpen});
    } catch (e, stack) {
      AppLogger.error('Failed to update sidebar state',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Toggle sidebar state
  Future<void> toggleSidebar(String sidebarId,
      {bool defaultState = false}) async {
    try {
      final currentState =
          state.getSidebarState(sidebarId, defaultState: defaultState);
      await setSidebarState(sidebarId, !currentState);
    } catch (e, stack) {
      AppLogger.error('Failed to toggle sidebar state',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }

  /// Load saved state
  Future<void> _loadState() async {
    try {
      final savedState = await PersistentPanelStatePersistence.restore();
      state = savedState;
      AppLogger.debug('PersistentPanel state loaded successfully',
          tag: 'PersistentPanelProvider');
    } catch (e, stack) {
      AppLogger.error('Failed to load PersistentPanel state',
          tag: 'PersistentPanelProvider', error: e, stackTrace: stack);
    }
  }
}
