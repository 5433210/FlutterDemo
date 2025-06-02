/// Canvas属性面板控制器 - Phase 2.2
///
/// 职责：
/// 1. 属性面板状态管理
/// 2. 批量属性更新
/// 3. 属性变更历史记录
/// 4. 性能优化的属性绑定
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/element_data.dart';

/// 属性变更记录
class PropertyChangeRecord {
  final String targetId;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> previousProperties;
  final DateTime timestamp;

  const PropertyChangeRecord({
    required this.targetId,
    required this.properties,
    required this.previousProperties,
    required this.timestamp,
  });
}

/// 属性面板配置
class PropertyPanelConfig {
  final bool showAdvancedProperties;
  final bool enableBatchEditing;
  final bool enableRealTimeUpdate;
  final Duration debounceDelay;
  final bool showPropertyHistory;

  const PropertyPanelConfig({
    this.showAdvancedProperties = true,
    this.enableBatchEditing = true,
    this.enableRealTimeUpdate = true,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.showPropertyHistory = false,
  });
}

/// 属性面板控制器
class PropertyPanelController extends ChangeNotifier {
  final CanvasStateManager _stateManager;

  /// 属性变更历史记录
  final List<PropertyChangeRecord> _history = [];

  /// 批量更新计时器
  Timer? _batchUpdateTimer;

  /// 待处理的批量更新
  final Map<String, Map<String, dynamic>> _pendingElementUpdates = {};

  /// 配置
  late PropertyPanelConfig _config;

  /// 当前选中的属性目标
  PropertyTarget? _currentTarget;

  PropertyPanelController({
    required CanvasStateManager stateManager,
    PropertyPanelConfig? config,
  })  : _stateManager = stateManager,
        _config = config ?? const PropertyPanelConfig(),
        _currentTarget = PropertyTarget.page() {
    // 监听状态管理器变化
    _stateManager.addListener(_onStateManagerChanged);
  }

  /// 获取当前配置
  PropertyPanelConfig get config => _config;

  /// 获取当前属性目标
  PropertyTarget? get currentTarget => _currentTarget;

  /// 是否有待处理的更新
  bool get hasPendingUpdates => _pendingElementUpdates.isNotEmpty;

  /// 获取属性变更历史
  List<PropertyChangeRecord> get history => List.unmodifiable(_history);

  /// 清空历史记录
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onStateManagerChanged);
    _batchUpdateTimer?.cancel();
    super.dispose();
  }

  /// 立即应用所有待处理的更新
  void flushPendingUpdates() {
    _batchUpdateTimer?.cancel();
    _processBatchUpdates();
  }

  /// 获取多选元素的共同属性
  Map<String, dynamic> getCommonProperties(List<String> elementIds) {
    if (elementIds.isEmpty) return {};

    final elements = elementIds
        .map((id) => _stateManager.elementState.getElementById(id))
        .where((element) => element != null)
        .cast<ElementData>()
        .toList();

    if (elements.isEmpty) return {};

    final commonProperties = <String, dynamic>{};
    final firstElement = elements.first;

    // 检查基础属性
    final basicProperties = ['opacity', 'rotation', 'isHidden', 'isLocked'];

    for (final property in basicProperties) {
      late dynamic firstValue;
      switch (property) {
        case 'opacity':
          firstValue = firstElement.opacity;
          break;
        case 'rotation':
          firstValue = firstElement.rotation;
          break;
        case 'isHidden':
          firstValue = firstElement.isHidden;
          break;
        case 'isLocked':
          firstValue = firstElement.isLocked;
          break;
        default:
          firstValue = firstElement.properties[property];
      }

      bool isCommon = true;

      for (int i = 1; i < elements.length; i++) {
        late dynamic otherValue;
        switch (property) {
          case 'opacity':
            otherValue = elements[i].opacity;
            break;
          case 'rotation':
            otherValue = elements[i].rotation;
            break;
          case 'isHidden':
            otherValue = elements[i].isHidden;
            break;
          case 'isLocked':
            otherValue = elements[i].isLocked;
            break;
          default:
            otherValue = elements[i].properties[property];
        }

        if (firstValue != otherValue) {
          isCommon = false;
          break;
        }
      }

      if (isCommon) {
        commonProperties[property] = firstValue;
      }
    }

    return commonProperties;
  }

  /// 获取元素属性值
  T? getElementProperty<T>(String elementId, String propertyKey) {
    final element = _stateManager.elementState.getElementById(elementId);
    return element?.properties[propertyKey] as T?;
  }

  /// 撤销上一次属性更改
  bool undoLastChange() {
    if (_history.isEmpty) return false;

    final lastRecord = _history.removeLast();
    _applyPropertyChange(lastRecord.targetId, lastRecord.previousProperties);

    notifyListeners();
    return true;
  }

  /// 更新配置
  void updateConfig(PropertyPanelConfig config) {
    _config = config;
    notifyListeners();
  }

  /// 更新元素属性
  void updateElementProperties(
      String elementId, Map<String, dynamic> properties) {
    if (_config.enableBatchEditing) {
      _batchElementUpdate(elementId, properties);
    } else {
      _immediateElementUpdate(elementId, properties);
    }
  }

  /// 批量更新多个元素的属性
  void updateMultipleElementProperties(
      List<String> elementIds, Map<String, dynamic> properties) {
    for (final elementId in elementIds) {
      updateElementProperties(elementId, properties);
    }
  }

  /// 添加到历史记录
  void _addToHistory(String targetId, Map<String, dynamic> properties,
      Map<String, dynamic> previousProperties) {
    final record = PropertyChangeRecord(
      targetId: targetId,
      properties: Map.from(properties),
      previousProperties: Map.from(previousProperties),
      timestamp: DateTime.now(),
    );

    _history.add(record);

    // 限制历史记录数量
    if (_history.length > 100) {
      _history.removeAt(0);
    }
  }

  /// 应用属性变更
  void _applyPropertyChange(String targetId, Map<String, dynamic> properties) {
    _immediateElementUpdate(targetId, properties);
  }

  /// 批量元素更新
  void _batchElementUpdate(String elementId, Map<String, dynamic> properties) {
    // 合并到待处理更新中
    _pendingElementUpdates[elementId] ??= {};
    _pendingElementUpdates[elementId]!.addAll(properties);

    // 重置定时器
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(_config.debounceDelay, _processBatchUpdates);

    if (_config.enableRealTimeUpdate) {
      _immediateElementUpdate(elementId, properties);
    }
  }

  /// 立即元素更新
  void _immediateElementUpdate(
      String elementId, Map<String, dynamic> properties) {
    final element = _stateManager.elementState.getElementById(elementId);
    if (element == null) return;

    final previousProperties = <String, dynamic>{};

    // 保存之前的属性值
    for (final key in properties.keys) {
      switch (key) {
        case 'opacity':
          previousProperties[key] = element.opacity;
          break;
        case 'rotation':
          previousProperties[key] = element.rotation;
          break;
        case 'isHidden':
          previousProperties[key] = element.isHidden;
          break;
        case 'isLocked':
          previousProperties[key] = element.isLocked;
          break;
        default:
          previousProperties[key] = element.properties[key];
      }
    }

    // 创建新的属性映射
    final newProperties = Map<String, dynamic>.from(element.properties);

    // 更新特殊属性和自定义属性
    double? newOpacity = element.opacity;
    double? newRotation = element.rotation;
    bool? newIsHidden = element.isHidden;
    bool? newIsLocked = element.isLocked;

    for (final entry in properties.entries) {
      switch (entry.key) {
        case 'opacity':
          newOpacity = entry.value as double?;
          break;
        case 'rotation':
          newRotation = entry.value as double?;
          break;
        case 'isHidden':
          newIsHidden = entry.value as bool?;
          break;
        case 'isLocked':
          newIsLocked = entry.value as bool?;
          break;
        default:
          newProperties[entry.key] = entry.value;
      }
    } // 更新元素属性
    final updatedElement = element.copyWith(
      opacity: newOpacity,
      rotation: newRotation,
      visible: newIsHidden != null ? !newIsHidden : null,
      locked: newIsLocked,
      properties: newProperties,
    );

    final updatedElementState =
        _stateManager.elementState.updateElement(elementId, updatedElement);
    _stateManager.updateElementState(updatedElementState);

    // 记录变更历史
    if (_config.showPropertyHistory) {
      _addToHistory(elementId, properties, previousProperties);
    }
  }

  /// 状态管理器变更处理
  void _onStateManagerChanged() {
    _updateCurrentTarget();
    notifyListeners();
  }

  /// 处理批量更新
  void _processBatchUpdates() {
    // 处理元素更新
    for (final entry in _pendingElementUpdates.entries) {
      _immediateElementUpdate(entry.key, entry.value);
    }
    _pendingElementUpdates.clear();

    notifyListeners();
  }

  /// 更新当前属性目标
  void _updateCurrentTarget() {
    final selectedIds = _stateManager.selectionState.selectedIds;

    if (selectedIds.length == 1) {
      final element =
          _stateManager.elementState.getElementById(selectedIds.first);
      if (element != null) {
        _currentTarget = PropertyTarget.element(element);
        return;
      }
    }

    if (selectedIds.length > 1) {
      final elements = selectedIds
          .map((id) => _stateManager.elementState.getElementById(id))
          .where((ElementData? element) => element != null)
          .cast<ElementData>()
          .toList();

      if (elements.isNotEmpty) {
        _currentTarget = PropertyTarget.multipleElements(elements);
        return;
      }
    }

    _currentTarget = PropertyTarget.page();
  }
}

/// 属性目标
class PropertyTarget {
  final PropertyTargetType type;
  final ElementData? element;
  final List<ElementData>? elements;

  factory PropertyTarget.element(ElementData element) {
    return PropertyTarget._(
      type: PropertyTargetType.element,
      element: element,
    );
  }

  factory PropertyTarget.multipleElements(List<ElementData> elements) {
    return PropertyTarget._(
      type: PropertyTargetType.multipleElements,
      elements: elements,
    );
  }

  factory PropertyTarget.page() {
    return const PropertyTarget._(
      type: PropertyTargetType.page,
    );
  }

  const PropertyTarget._({
    required this.type,
    this.element,
    this.elements,
  });
}

/// 属性目标类型
enum PropertyTargetType {
  element,
  multipleElements,
  page,
}
