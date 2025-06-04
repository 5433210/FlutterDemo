import 'dart:async';

import 'package:flutter/foundation.dart';

import 'element_change_types.dart';

/// Controller for managing content rendering layer updates and notifications
class ContentRenderController extends ChangeNotifier {
  final List<ElementChangeInfo> _changeHistory = [];
  final Map<String, Map<String, dynamic>> _lastKnownProperties = {};
  final StreamController<ElementChangeInfo> _changeStreamController =
      StreamController<ElementChangeInfo>.broadcast();

  /// Get the change history
  List<ElementChangeInfo> get changeHistory =>
      List.unmodifiable(_changeHistory);

  /// Stream of element changes for reactive updates
  Stream<ElementChangeInfo> get changeStream => _changeStreamController.stream;

  /// Clear change history
  void clearHistory() {
    _changeHistory.clear();
  }

  @override
  void dispose() {
    _changeStreamController.close();
    super.dispose();
  }

  /// Get changes for a specific element
  List<ElementChangeInfo> getChangesForElement(String elementId) {
    return _changeHistory
        .where((change) => change.elementId == elementId)
        .toList();
  }

  /// Get last known properties for an element
  Map<String, dynamic>? getLastKnownProperties(String elementId) {
    return _lastKnownProperties[elementId];
  }

  /// Get recent changes within a time window
  List<ElementChangeInfo> getRecentChanges(Duration timeWindow) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return _changeHistory
        .where((change) => change.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Initialize element properties tracking
  void initializeElement({
    required String elementId,
    required Map<String, dynamic> properties,
  }) {
    print('🎯 ContentRenderController: Initializing element $elementId');
    print(
        '🎯 ContentRenderController: Element properties: ${properties.keys.join(', ')}');
    _lastKnownProperties[elementId] = Map.from(properties);
  }

  /// Initialize multiple elements at once
  void initializeElements(List<Map<String, dynamic>> elements) {
    print(
        '🎯 ContentRenderController: Initializing ${elements.length} elements');
    for (final element in elements) {
      final elementId = element['id'] as String;
      final elementType = element['type'] as String?;
      print(
          '🎯 ContentRenderController: - Element $elementId (type: $elementType)');
      _lastKnownProperties[elementId] = Map.from(element);
    }
  }

  /// Check if element is being tracked
  bool isElementTracked(String elementId) {
    return _lastKnownProperties.containsKey(elementId);
  }

  /// Notify about element property changes
  void notifyElementChanged({
    required String elementId,
    required Map<String, dynamic> newProperties,
  }) {
    print('🔔 ContentRenderController: Element $elementId changed');
    print(
        '🔔 ContentRenderController: New properties: ${newProperties.keys.join(', ')}');

    final oldProperties =
        _lastKnownProperties[elementId] ?? <String, dynamic>{};

    // Create change info
    final changeInfo = ElementChangeInfo.fromChanges(
      elementId: elementId,
      oldProperties: oldProperties,
      newProperties: newProperties,
    );

    // Update stored properties
    _lastKnownProperties[elementId] = Map.from(newProperties);

    // Add to history
    _changeHistory.add(changeInfo);

    // Limit history size
    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    } // Notify through stream only (avoid triggering broad notifyListeners)
    _changeStreamController.add(changeInfo);

    print('🔔 ContentRenderController: Change type: ${changeInfo.changeType}');
    debugPrint(
        'ContentRenderController: Element $elementId changed - ${changeInfo.changeType}');
  }

  /// Notify about element creation
  void notifyElementCreated({
    required String elementId,
    required Map<String, dynamic> properties,
  }) {
    final changeInfo = ElementChangeInfo(
      elementId: elementId,
      changeType: ElementChangeType.created,
      oldProperties: <String, dynamic>{},
      newProperties: Map.from(properties),
      timestamp: DateTime.now(),
    );
    _lastKnownProperties[elementId] = Map.from(properties);
    _changeHistory.add(changeInfo);

    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    }

    _changeStreamController.add(changeInfo);

    debugPrint('ContentRenderController: Element $elementId created');
  }

  /// Notify about element deletion
  void notifyElementDeleted({
    required String elementId,
  }) {
    final oldProperties =
        _lastKnownProperties[elementId] ?? <String, dynamic>{};

    final changeInfo = ElementChangeInfo(
      elementId: elementId,
      changeType: ElementChangeType.deleted,
      oldProperties: Map.from(oldProperties),
      newProperties: <String, dynamic>{},
      timestamp: DateTime.now(),
    );
    _lastKnownProperties.remove(elementId);
    _changeHistory.add(changeInfo);

    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    }

    _changeStreamController.add(changeInfo);

    debugPrint('ContentRenderController: Element $elementId deleted');
  }

  /// Reset controller state
  void reset() {
    _changeHistory.clear();
    _lastKnownProperties.clear();
    notifyListeners();
  }
}
