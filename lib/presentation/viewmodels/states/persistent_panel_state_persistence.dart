import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../infrastructure/logging/logger.dart';
import 'persistent_panel_state.dart';

/// Extension providing persistence functionality for PersistentPanelState
extension PersistentPanelStatePersistence on PersistentPanelState {
  static const String _keyPersistentPanelState = 'persistent_panel_state';

  /// Save state to SharedPreferences
  Future<void> persist() async {
    try {
      AppLogger.debug('Persisting PersistentPanelState',
          tag: 'PersistentPanel');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = toJson();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_keyPersistentPanelState, jsonString);

      AppLogger.debug('PersistentPanelState persisted successfully',
          tag: 'PersistentPanel',
          data: {
            'panelCount': panelWidths.length,
            'sidebarCount': sidebarStates.length,
          });
    } catch (e, stack) {
      AppLogger.error('Failed to persist PersistentPanelState',
          tag: 'PersistentPanel', error: e, stackTrace: stack);
    }
  }

  /// Convert state to JSON
  Map<String, dynamic> toJson() {
    final result = {
      'panelWidths': panelWidths,
      'sidebarStates': sidebarStates,
    };

    AppLogger.debug('PersistentPanelState serialized successfully',
        tag: 'PersistentPanel');
    return result;
  }

  /// Clear saved state
  static Future<void> clear() async {
    try {
      AppLogger.debug('Clearing PersistentPanelState', tag: 'PersistentPanel');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPersistentPanelState);

      AppLogger.debug('PersistentPanelState cleared successfully',
          tag: 'PersistentPanel');
    } catch (e, stack) {
      AppLogger.error('Failed to clear PersistentPanelState',
          tag: 'PersistentPanel', error: e, stackTrace: stack);
    }
  }

  /// Restore state from JSON
  static PersistentPanelState fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Deserializing PersistentPanelState',
          tag: 'PersistentPanel', data: {'json': json});

      // Restore panelWidths
      final panelWidthsData = json['panelWidths'] as Map<String, dynamic>?;
      final panelWidths = panelWidthsData != null
          ? Map<String, double>.from(panelWidthsData.map((key, value) =>
              MapEntry(key, value is num ? value.toDouble() : 0.0)))
          : <String, double>{};

      // Restore sidebarStates
      final sidebarStatesData = json['sidebarStates'] as Map<String, dynamic>?;
      final sidebarStates = sidebarStatesData != null
          ? Map<String, bool>.from(sidebarStatesData.map((key, value) =>
              MapEntry(key, value is bool ? value : value == true)))
          : <String, bool>{};

      final state = PersistentPanelState(
        panelWidths: panelWidths,
        sidebarStates: sidebarStates,
      );

      AppLogger.debug('PersistentPanelState deserialized successfully',
          tag: 'PersistentPanel',
          data: {
            'panelCount': state.panelWidths.length,
            'sidebarCount': state.sidebarStates.length,
          });

      return state;
    } catch (e, stack) {
      AppLogger.error(
        'Error deserializing PersistentPanelState',
        tag: 'PersistentPanel',
        error: e,
        stackTrace: stack,
      );

      // Return default state on error
      return PersistentPanelState.initial();
    }
  }

  /// Restore saved state from SharedPreferences
  static Future<PersistentPanelState> restore() async {
    try {
      AppLogger.debug('Restoring PersistentPanelState', tag: 'PersistentPanel');

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPersistentPanelState);

      if (jsonString == null) {
        AppLogger.debug('No saved PersistentPanelState found, using defaults',
            tag: 'PersistentPanel');
        return PersistentPanelState.initial();
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = fromJson(jsonData);

      AppLogger.debug('PersistentPanelState restored successfully',
          tag: 'PersistentPanel');

      return state;
    } catch (e, stack) {
      AppLogger.error('Failed to restore PersistentPanelState',
          tag: 'PersistentPanel', error: e, stackTrace: stack);
      return PersistentPanelState.initial();
    }
  }
}
