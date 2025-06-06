import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/practice/dirty_tracker.dart';
import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/element_cache_manager.dart';
import '../../../widgets/practice/selective_rebuild_manager.dart';
import 'element_change_types.dart';

/// Controller for managing content rendering layer updates and notifications
class ContentRenderController extends ChangeNotifier {
  final List<ElementChangeInfo> _changeHistory = [];
  final Map<String, Map<String, dynamic>> _lastKnownProperties = {};
  final StreamController<ElementChangeInfo> _changeStreamController =
      StreamController<ElementChangeInfo>.broadcast();

  // 拖拽状态管理器引用
  DragStateManager? _dragStateManager;

  // 需要跳过渲染的元素列表 (将在DragPreviewLayer中显示)
  final Set<String> _elementsToSkip = <String>{};

  // Smart rebuilding system components
  late final DirtyTracker _dirtyTracker;
  SelectiveRebuildManager? _rebuildManager;

  /// Initialize the controller with optional selective rebuilding
  ContentRenderController({
    bool enableSelectiveRebuilding = true,
  }) {
    _dirtyTracker = DirtyTracker();

    if (enableSelectiveRebuilding) {
      // Note: rebuildManager will be initialized when cacheManager is available
      // This is done in ContentRenderLayer when it creates the cache manager
    }
  }

  /// Get the change history
  List<ElementChangeInfo> get changeHistory =>
      List.unmodifiable(_changeHistory);

  /// Stream of element changes for reactive updates
  Stream<ElementChangeInfo> get changeStream => _changeStreamController.stream;

  /// Get the dirty tracker for selective rebuilding
  DirtyTracker get dirtyTracker => _dirtyTracker;

  // 是否正在拖拽中
  bool get isDragging => _dragStateManager?.isDragging ?? false;

  /// Get selective rebuild manager (may be null if not enabled)
  SelectiveRebuildManager? get rebuildManager => _rebuildManager;

  void agStateChanged() {
    debugPrint('🔄 ContentRenderController: 拖拽状态变化，触发重建');
    debugPrint('   isDragging: ${_dragStateManager?.isDragging}');
    debugPrint(
        '   draggingElementIds: ${_dragStateManager?.draggingElementIds}');
    notifyListeners();
  }

  /// Clear change history
  void clearHistory() {
    _changeHistory.clear();
  }

  @override
  void dispose() {
    _changeStreamController.close();
    _dirtyTracker.dispose();
    _rebuildManager?.dispose();
    // 移除拖拽状态监听器
    _dragStateManager?.removeListener(_onDragStateChanged);
    super.dispose();
  }

  /// Get changes for a specific element
  List<ElementChangeInfo> getChangesForElement(String elementId) {
    return _changeHistory
        .where((change) => change.elementId == elementId)
        .toList();
  }

  /// 获取元素的预览位置（如果正在拖拽中）
  Offset? getElementPreviewPosition(String elementId) {
    if (_dragStateManager == null || !_dragStateManager!.isDragging) {
      return null;
    }
    return _dragStateManager!.getElementPreviewPosition(elementId);
  }

  /// Get last known properties for an element
  Map<String, dynamic>? getLastKnownProperties(String elementId) {
    return _lastKnownProperties[elementId];
  }

  /// Get rebuild strategy for an element
  RebuildStrategy getRebuildStrategy(
      String elementId, ElementChangeType changeType) {
    return _rebuildManager?.getRebuildStrategy(elementId, changeType) ??
        RebuildStrategy.fullRebuild;
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

  /// Initialize selective rebuild manager with cache manager
  void initializeSelectiveRebuilding(ElementCacheManager cacheManager) {
    _rebuildManager = SelectiveRebuildManager(
      dirtyTracker: _dirtyTracker,
      cacheManager: cacheManager,
    );
  }

  /// 检查元素是否正在被拖拽
  bool isElementDragging(String elementId) {
    if (_dragStateManager == null) return false;
    return _dragStateManager!.isElementDragging(elementId);
  }

  /// Check if element is being tracked
  bool isElementTracked(String elementId) {
    return _lastKnownProperties.containsKey(elementId);
  }

  /// Mark element as clean after rebuilding
  void markElementClean(String elementId) {
    _dirtyTracker.markElementClean(elementId);
  }

  /// Mark an element as dirty for rebuilding
  void markElementDirty(String elementId, ElementChangeType changeType) {
    _dirtyTracker.markElementDirty(elementId, changeType);
  }

  /// Mark multiple elements as dirty
  void markElementsDirty(Map<String, ElementChangeType> elements) {
    _dirtyTracker.markElementsDirty(elements);
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
    }

    // Mark element as dirty for selective rebuilding
    _dirtyTracker.markElementDirty(elementId, changeInfo.changeType);

    // Notify through stream only (avoid triggering broad notifyListeners)
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

    // Mark new element as dirty
    _dirtyTracker.markElementDirty(elementId, ElementChangeType.created);

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

    // Remove element from dirty tracking
    _dirtyTracker.removeElement(elementId);
    _rebuildManager?.removeElement(elementId);

    _changeStreamController.add(changeInfo);

    debugPrint('ContentRenderController: Element $elementId deleted');
  }

  /// Reset controller state
  void reset() {
    _changeHistory.clear();
    _lastKnownProperties.clear();
    notifyListeners();
  }

  /// 设置拖拽状态管理器
  void setDragStateManager(DragStateManager dragStateManager) {
    // 移除旧的监听器
    _dragStateManager?.removeListener(_onDragStateChanged);

    _dragStateManager = dragStateManager;

    // 添加新的监听器
    _dragStateManager?.addListener(_onDragStateChanged);

    debugPrint(
        '🎯 ContentRenderController: DragStateManager connected with listener');
  }

  /// Check if an element should be rebuilt
  bool shouldRebuildElement(String elementId) {
    return _rebuildManager?.shouldRebuildElement(elementId) ?? true;
  }

  /// 检查元素是否应该跳过渲染（由于拖拽预览层已处理）

  /// 检查元素是否应该跳过渲染（由于拖拽预览层已处理）
  bool shouldSkipElementRendering(String elementId) {
    // 添加调试信息
    final isDragStateManagerActive = _dragStateManager != null;
    final isDragging = _dragStateManager?.isDragging ?? false;
    final isElementDragging =
        _dragStateManager?.isElementDragging(elementId) ?? false;
    final enableDragPreview = DragConfig.enableDragPreview;
    final isDragPreviewActive = _dragStateManager?.isDragPreviewActive ?? false;

    debugPrint(
        '🔍 ContentRenderController: shouldSkipElementRendering($elementId)');
    debugPrint('   dragStateManager: $isDragStateManagerActive');
    debugPrint('   isDragging: $isDragging');
    debugPrint('   isDragPreviewActive: $isDragPreviewActive');
    debugPrint('   isElementDragging: $isElementDragging');
    debugPrint('   enableDragPreview: $enableDragPreview');

    // 如果启用了拖拽预览层且元素正在被拖拽，可以跳过主渲染层中的渲染
    if (isDragStateManagerActive &&
        isDragging &&
        isDragPreviewActive &&
        isElementDragging &&
        enableDragPreview) {
      debugPrint('🎯 ContentRenderController: ✅ 跳过元素 $elementId 渲染 (拖拽中)');
      return true;
    }

    debugPrint('🎯 ContentRenderController: ❌ 不跳过元素 $elementId 渲染');
    return false;
  }

  /// 拖拽状态变化处理方法
  void _onDragStateChanged() {
    // 当拖拽状态发生变化时更新渲染控制器的状态
    if (_dragStateManager != null) {
      final isDragging = _dragStateManager!.isDragging;
      final draggingElementIds = _dragStateManager!
          .draggingElementIds; // 更新需要跳过渲染的元素列表（这些元素将在DragPreviewLayer中显示）
      _elementsToSkip.clear();
      if (isDragging) {
        _elementsToSkip.addAll(draggingElementIds); // 标记这些元素为脏状态，以便下一次渲染时更新
        for (final elementId in draggingElementIds) {
          markElementDirty(elementId, ElementChangeType.multiple);
        }
      }

      // 通知监听器状态已更新
      notifyListeners();

      debugPrint(
          'ContentRenderController: 拖拽状态更新，当前拖拽中: $isDragging, 元素: $draggingElementIds');
    }
  }
}
