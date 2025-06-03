// filepath: lib/canvas/core/selection/selection_manager.dart

import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Selection history entry
class SelectionHistoryEntry {
  final Set<String> selectedIds;
  final DateTime timestamp;

  const SelectionHistoryEntry({
    required this.selectedIds,
    required this.timestamp,
  });
}

/// Advanced selection management for Canvas elements
class SelectionManager extends ChangeNotifier {
  final Set<String> _selectedIds = <String>{};
  final Map<String, Rect> _elementBounds = <String, Rect>{};
  final List<SelectionHistoryEntry> _selectionHistory = [];
  int _historyIndex = -1;

  /// Selection modes
  SelectionMode _mode = SelectionMode.single;

  /// Selection area for box selection
  Rect? _selectionArea;
  bool _isBoxSelecting = false;

  /// Hover state for interactive feedback
  String? _hoveredElementId;

  /// Selection callbacks
  Function(Set<String>)? onSelectionChanged;
  Function(String?)? onHoverChanged;

  bool get canRedo => _historyIndex < _selectionHistory.length - 1;
  bool get canUndo => _historyIndex > 0;
  bool get hasMultipleSelection => _selectedIds.length > 1;
  bool get hasSelection => _selectedIds.isNotEmpty;
  String? get hoveredElementId => _hoveredElementId;
  bool get isBoxSelecting => _isBoxSelecting;
  SelectionMode get mode => _mode;
  String? get primarySelectedId =>
      _selectedIds.isNotEmpty ? _selectedIds.first : null;

  /// Current selection state
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  Rect? get selectionArea => _selectionArea;

  /// Get selection bounds
  Rect? get selectionBounds {
    if (_selectedIds.isEmpty) return null;

    Rect? bounds;
    for (final id in _selectedIds) {
      final elementBounds = _elementBounds[id];
      if (elementBounds != null) {
        bounds = bounds?.expandToInclude(elementBounds) ?? elementBounds;
      }
    }
    return bounds;
  }

  /// Cancel box selection
  void cancelBoxSelection() {
    _isBoxSelecting = false;
    _selectionArea = null;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    if (_selectedIds.isNotEmpty) {
      _clearSelection();
      _recordSelectionChange();
    }
  }

  /// Complete box selection
  void completeBoxSelection({bool addToSelection = false}) {
    if (!_isBoxSelecting || _selectionArea == null) return;

    final selectedInArea = <String>{};

    // Find elements within selection area
    for (final entry in _elementBounds.entries) {
      final elementBounds = entry.value;
      if (_selectionArea!.overlaps(elementBounds)) {
        selectedInArea.add(entry.key);
      }
    }

    // Update selection
    if (!addToSelection) {
      _clearSelection(notify: false);
    }

    for (final id in selectedInArea) {
      _addToSelection(id, notify: false);
    }

    // Clean up box selection
    _isBoxSelecting = false;
    _selectionArea = null;

    _recordSelectionChange();
    notifyListeners();
  }

  /// Deselect a specific element
  void deselectElement(String elementId) {
    if (_selectedIds.contains(elementId)) {
      _selectedIds.remove(elementId);
      _recordSelectionChange();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _selectedIds.clear();
    _elementBounds.clear();
    _selectionHistory.clear();
    super.dispose();
  }

  /// Get selection outline for rendering
  SelectionOutline? getSelectionOutline() {
    if (_selectedIds.isEmpty) return null;

    final bounds = selectionBounds;
    if (bounds == null) return null;

    return SelectionOutline(
      bounds: bounds,
      isMultiple: hasMultipleSelection,
      selectedIds: _selectedIds,
    );
  }

  /// Invert selection
  void invertSelection(List<String> allElementIds) {
    final currentSelection = Set<String>.from(_selectedIds);
    _clearSelection(notify: false);

    for (final id in allElementIds) {
      if (!currentSelection.contains(id)) {
        _addToSelection(id, notify: false);
      }
    }

    _recordSelectionChange();
    notifyListeners();
  }

  /// Check if element is hovered
  bool isHovered(String elementId) => _hoveredElementId == elementId;

  /// Check if element is selected
  bool isSelected(String elementId) => _selectedIds.contains(elementId);

  void redo() {
    if (_historyIndex < _selectionHistory.length - 1) {
      _historyIndex++;
      final entry = _selectionHistory[_historyIndex];
      _restoreSelection(entry);
    }
  }

  /// Remove element bounds when element is deleted
  void removeElementBounds(String elementId) {
    _elementBounds.remove(elementId);
    if (_selectedIds.contains(elementId)) {
      _removeFromSelection(elementId);
    }
  }

  /// Select all elements
  void selectAll(List<String> allElementIds) {
    _clearSelection(notify: false);
    for (final id in allElementIds) {
      _addToSelection(id, notify: false);
    }
    _recordSelectionChange();
    notifyListeners();
  }

  /// Select single element
  void selectElement(String elementId, {bool addToSelection = false}) {
    if (_mode == SelectionMode.single || !addToSelection) {
      _clearSelection(notify: false);
    }

    if (_selectedIds.contains(elementId)) {
      if (addToSelection || _mode == SelectionMode.multiple) {
        _removeFromSelection(elementId, notify: false);
      }
    } else {
      _addToSelection(elementId, notify: false);
    }

    _recordSelectionChange();
    notifyListeners();
  }

  /// Select multiple elements
  void selectElements(Set<String> elementIds, {bool replace = true}) {
    if (replace) {
      _clearSelection(notify: false);
    }

    for (final id in elementIds) {
      _addToSelection(id, notify: false);
    }

    _recordSelectionChange();
    notifyListeners();
  }

  /// Set hover state
  void setHover(String? elementId) {
    if (_hoveredElementId != elementId) {
      _hoveredElementId = elementId;
      onHoverChanged?.call(elementId);
      notifyListeners();
    }
  }

  /// Set selection mode
  void setMode(SelectionMode mode) {
    if (_mode != mode) {
      _mode = mode;
      if (mode == SelectionMode.single && _selectedIds.length > 1) {
        // Convert to single selection by keeping only the first element
        final firstId = _selectedIds.first;
        _clearSelection(notify: false);
        _addToSelection(firstId, notify: false);
        _recordSelectionChange();
        notifyListeners();
      }
    }
  }

  /// Start box selection
  void startBoxSelection(Offset startPoint) {
    _isBoxSelecting = true;
    _selectionArea = Rect.fromLTWH(startPoint.dx, startPoint.dy, 0, 0);
    notifyListeners();
  }

  /// Selection history management
  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      final entry = _selectionHistory[_historyIndex];
      _restoreSelection(entry);
    }
  }

  /// Update box selection
  void updateBoxSelection(Offset currentPoint) {
    if (!_isBoxSelecting || _selectionArea == null) return;

    final startPoint = _selectionArea!.topLeft;
    _selectionArea = Rect.fromPoints(startPoint, currentPoint);
    notifyListeners();
  }

  /// Update element bounds for selection calculations
  void updateElementBounds(String elementId, Rect bounds) {
    _elementBounds[elementId] = bounds;
  }

  /// Private methods
  void _addToSelection(String elementId, {bool notify = true}) {
    if (_mode == SelectionMode.single && _selectedIds.isNotEmpty) {
      _clearSelection(notify: false);
    }

    _selectedIds.add(elementId);
    if (notify) {
      onSelectionChanged?.call(_selectedIds);
      notifyListeners();
    }
  }

  void _clearSelection({bool notify = true}) {
    _selectedIds.clear();
    if (notify) {
      onSelectionChanged?.call(_selectedIds);
      notifyListeners();
    }
  }

  void _recordSelectionChange() {
    // Remove future history if we're not at the end
    if (_historyIndex < _selectionHistory.length - 1) {
      _selectionHistory.removeRange(
          _historyIndex + 1, _selectionHistory.length);
    }

    // Add new entry
    _selectionHistory.add(SelectionHistoryEntry(
      selectedIds: Set.from(_selectedIds),
      timestamp: DateTime.now(),
    ));

    _historyIndex = _selectionHistory.length - 1;

    // Limit history size
    if (_selectionHistory.length > 50) {
      _selectionHistory.removeAt(0);
      _historyIndex--;
    }
  }

  void _removeFromSelection(String elementId, {bool notify = true}) {
    _selectedIds.remove(elementId);
    if (notify) {
      onSelectionChanged?.call(_selectedIds);
      notifyListeners();
    }
  }

  void _restoreSelection(SelectionHistoryEntry entry) {
    _clearSelection(notify: false);
    for (final id in entry.selectedIds) {
      _addToSelection(id, notify: false);
    }
    onSelectionChanged?.call(_selectedIds);
    notifyListeners();
  }
}

/// Selection modes
enum SelectionMode {
  single,
  multiple,
}

/// Selection outline for rendering
class SelectionOutline {
  final Rect bounds;
  final bool isMultiple;
  final Set<String> selectedIds;

  const SelectionOutline({
    required this.bounds,
    required this.isMultiple,
    required this.selectedIds,
  });
}
