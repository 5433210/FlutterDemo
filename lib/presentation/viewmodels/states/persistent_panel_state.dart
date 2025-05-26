/// State class for persistent panel components
/// Manages both ResizablePanel dimensions and SidebarToggle visibility states
class PersistentPanelState {
  /// Map of panel IDs to their current widths
  final Map<String, double> panelWidths;

  /// Map of sidebar IDs to their visibility states
  final Map<String, bool> sidebarStates;

  const PersistentPanelState({
    this.panelWidths = const {},
    this.sidebarStates = const {},
  });

  /// Initial state with empty maps
  factory PersistentPanelState.initial() => const PersistentPanelState();

  /// Create a copy with updated fields
  PersistentPanelState copyWith({
    Map<String, double>? panelWidths,
    Map<String, bool>? sidebarStates,
  }) {
    return PersistentPanelState(
      panelWidths: panelWidths ?? this.panelWidths,
      sidebarStates: sidebarStates ?? this.sidebarStates,
    );
  }
}

/// Extensions for PersistentPanelState
extension PersistentPanelStateExtensions on PersistentPanelState {
  /// Clear all states
  PersistentPanelState clearAll() {
    return PersistentPanelState.initial();
  }

  /// Get panel width with default fallback
  double getPanelWidth(String panelId, {double defaultWidth = 300.0}) {
    return panelWidths[panelId] ?? defaultWidth;
  }

  /// Get sidebar state with default fallback
  bool getSidebarState(String sidebarId, {bool defaultState = false}) {
    return sidebarStates[sidebarId] ?? defaultState;
  }

  /// Remove panel width
  PersistentPanelState removePanelWidth(String panelId) {
    final newPanelWidths = Map<String, double>.from(panelWidths);
    newPanelWidths.remove(panelId);
    return copyWith(panelWidths: newPanelWidths);
  }

  /// Remove sidebar state
  PersistentPanelState removeSidebarState(String sidebarId) {
    final newSidebarStates = Map<String, bool>.from(sidebarStates);
    newSidebarStates.remove(sidebarId);
    return copyWith(sidebarStates: newSidebarStates);
  }

  /// Set multiple panel widths at once
  PersistentPanelState setMultiplePanelWidths(Map<String, double> widths) {
    return copyWith(
      panelWidths: {...panelWidths, ...widths},
    );
  }

  /// Set multiple sidebar states at once
  PersistentPanelState setMultipleSidebarStates(Map<String, bool> states) {
    return copyWith(
      sidebarStates: {...sidebarStates, ...states},
    );
  }

  /// Set panel width
  PersistentPanelState setPanelWidth(String panelId, double width) {
    return copyWith(
      panelWidths: {...panelWidths, panelId: width},
    );
  }

  /// Set sidebar state
  PersistentPanelState setSidebarState(String sidebarId, bool isOpen) {
    return copyWith(
      sidebarStates: {...sidebarStates, sidebarId: isOpen},
    );
  }
}
