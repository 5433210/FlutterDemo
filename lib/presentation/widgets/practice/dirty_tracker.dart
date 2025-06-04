import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../pages/practices/widgets/element_change_types.dart';

/// Tracks which elements are dirty and need rebuilding for optimized rendering
class DirtyTracker extends ChangeNotifier {
  /// Set of element IDs that are currently dirty and need rebuilding
  final Set<String> _dirtyElements = <String>{};

  /// Map of element IDs to their last rebuild version numbers
  final Map<String, int> _elementVersions = <String, int>{};

  /// Map of element IDs to their dirty reasons for debugging
  final Map<String, Set<ElementChangeType>> _dirtyReasons =
      <String, Set<ElementChangeType>>{};

  /// Global rebuild counter for versioning
  int _globalVersion = 0;

  /// Queue of pending dirty operations for batch processing
  final Queue<_DirtyOperation> _pendingOperations = Queue<_DirtyOperation>();

  /// Whether batch mode is currently active
  bool _batchMode = false;

  /// Get read-only view of dirty elements
  Set<String> get dirtyElements => Set.unmodifiable(_dirtyElements);

  /// Get the current global version
  int get globalVersion => _globalVersion;

  /// Clear all dirty state
  void clearAll() {
    final hadDirtyElements = _dirtyElements.isNotEmpty;
    _dirtyElements.clear();
    _dirtyReasons.clear();
    _pendingOperations.clear();

    if (hadDirtyElements) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dirtyElements.clear();
    _elementVersions.clear();
    _dirtyReasons.clear();
    _pendingOperations.clear();
    super.dispose();
  }

  /// End batch mode and process all pending operations
  void endBatch() {
    if (!_batchMode) return;

    _batchMode = false;

    if (_pendingOperations.isEmpty) return;

    bool hasChanges = false;

    // Increment version first if there are operations to process
    _incrementGlobalVersion();

    // Process all pending operations
    while (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeFirst();

      if (operation.isMarkOperation) {
        if (_performMarkDirty(operation.elementId, operation.changeType!)) {
          hasChanges = true;
        }
      } else {
        if (_performMarkClean(operation.elementId)) {
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Get dirty reasons for an element (for debugging)
  Set<ElementChangeType> getDirtyReasons(String elementId) {
    return Set.unmodifiable(_dirtyReasons[elementId] ?? <ElementChangeType>{});
  }

  /// Get the rebuild version for an element
  int getElementVersion(String elementId) {
    return _elementVersions[elementId] ?? 0;
  }

  /// Get statistics about dirty tracking
  DirtyTrackerStats getStats() {
    return DirtyTrackerStats(
      totalTrackedElements: _elementVersions.length,
      dirtyElementsCount: _dirtyElements.length,
      globalVersion: _globalVersion,
      isDirtySetEmpty: _dirtyElements.isEmpty,
    );
  }

  /// Check if a specific element is dirty
  bool isElementDirty(String elementId) {
    return _dirtyElements.contains(elementId);
  }

  /// Mark all elements as dirty (usually after major structural changes)
  void markAllDirty(Set<String> elementIds,
      [ElementChangeType changeType = ElementChangeType.multiple]) {
    if (_batchMode) {
      for (final elementId in elementIds) {
        _pendingOperations.add(_DirtyOperation.mark(elementId, changeType));
      }
      return;
    }

    bool hasChanges = false;
    for (final elementId in elementIds) {
      if (_performMarkDirty(elementId, changeType)) {
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _incrementGlobalVersion();
      notifyListeners();
    }
  }

  /// Mark an element as clean after rebuilding
  void markElementClean(String elementId) {
    if (_batchMode) {
      _pendingOperations.add(_DirtyOperation.clean(elementId));
      return;
    }

    if (_performMarkClean(elementId)) {
      _incrementGlobalVersion();
      notifyListeners();
    }
  }

  /// Mark an element as dirty with a specific reason
  void markElementDirty(String elementId, ElementChangeType changeType) {
    if (_batchMode) {
      _pendingOperations.add(_DirtyOperation.mark(elementId, changeType));
      return;
    }

    if (_performMarkDirty(elementId, changeType)) {
      _incrementGlobalVersion();
      notifyListeners();
    }
  }

  /// Mark multiple elements as clean
  void markElementsClean(Set<String> elementIds) {
    if (_batchMode) {
      for (final elementId in elementIds) {
        _pendingOperations.add(_DirtyOperation.clean(elementId));
      }
      return;
    }

    bool hasChanges = false;
    for (final elementId in elementIds) {
      if (_performMarkClean(elementId)) {
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Mark multiple elements as dirty
  void markElementsDirty(Map<String, ElementChangeType> elements) {
    if (_batchMode) {
      for (final entry in elements.entries) {
        _pendingOperations.add(_DirtyOperation.mark(entry.key, entry.value));
      }
      return;
    }

    bool hasChanges = false;
    for (final entry in elements.entries) {
      if (_performMarkDirty(entry.key, entry.value)) {
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _incrementGlobalVersion();
      notifyListeners();
    }
  }

  /// Remove element from tracking
  void removeElement(String elementId) {
    final hadElement = _dirtyElements.remove(elementId);
    _elementVersions.remove(elementId);
    _dirtyReasons.remove(elementId);

    if (hadElement) {
      notifyListeners();
    }
  }

  /// Start batch mode for efficient bulk operations
  void startBatch() {
    _batchMode = true;
    _pendingOperations.clear();
  }

  /// Increment global version counter
  void _incrementGlobalVersion() {
    _globalVersion++;
  }

  /// Internal method to mark element clean
  bool _performMarkClean(String elementId) {
    final wasDirty = _dirtyElements.remove(elementId);
    _dirtyReasons.remove(elementId);
    _elementVersions[elementId] = _globalVersion;

    return wasDirty;
  }

  /// Internal method to mark element dirty
  bool _performMarkDirty(String elementId, ElementChangeType changeType) {
    final wasClean = !_dirtyElements.contains(elementId);

    _dirtyElements.add(elementId);
    _dirtyReasons
        .putIfAbsent(elementId, () => <ElementChangeType>{})
        .add(changeType);

    return wasClean;
  }
}

/// Statistics class for dirty tracker metrics
class DirtyTrackerStats {
  final int totalTrackedElements;
  final int dirtyElementsCount;
  final int globalVersion;
  final bool isDirtySetEmpty;

  const DirtyTrackerStats({
    required this.totalTrackedElements,
    required this.dirtyElementsCount,
    required this.globalVersion,
    required this.isDirtySetEmpty,
  });

  double get dirtyRatio => totalTrackedElements > 0
      ? dirtyElementsCount / totalTrackedElements
      : 0.0;

  @override
  String toString() {
    return 'DirtyTrackerStats(tracked: $totalTrackedElements, dirty: $dirtyElementsCount, '
        'ratio: ${(dirtyRatio * 100).toStringAsFixed(1)}%, version: $globalVersion)';
  }
}

/// Internal class for batch operations
class _DirtyOperation {
  final String elementId;
  final ElementChangeType? changeType;
  final bool isMarkOperation;

  _DirtyOperation.clean(this.elementId)
      : changeType = null,
        isMarkOperation = false;
  _DirtyOperation.mark(this.elementId, this.changeType)
      : isMarkOperation = true;
}
