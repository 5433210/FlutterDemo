/// 属性绑定优化 - Phase 2.2
///
/// 优化属性绑定机制，提高大量属性更新时的性能
library;

import 'dart:async';

import './property_panel_controller.dart';

/// 单个元素的属性绑定
class PropertyBinding {
  final String elementId;
  final PropertyBindingManager _manager;
  final PropertyBindingOptions options;

  /// 当前值缓存
  final Map<String, dynamic> _valueCache = {};

  /// 防抖计时器
  Timer? _debounceTimer;

  PropertyBinding._({
    required this.elementId,
    required PropertyBindingManager manager,
    required this.options,
  }) : _manager = manager;

  /// 设置布尔属性
  void setBoolean(String property, bool value) {
    _setValue(property, value);
  }

  /// 设置颜色属性
  void setColor(String property, int value) {
    _setValue(property, value);
  }

  /// 设置数值型属性
  void setNumber(String property, num value) {
    _setValue(property, value);
  }

  /// 一次性设置多个属性
  void setProperties(Map<String, dynamic> properties) {
    if (properties.isEmpty) return;

    // 检查是否有变化
    bool hasChanges = false;
    for (final entry in properties.entries) {
      if (_valueCache[entry.key] != entry.value) {
        _valueCache[entry.key] = entry.value;
        hasChanges = true;
      }
    }

    if (!hasChanges) return;

    // 根据绑定类型执行更新
    _manager._updateProperty(elementId, properties, options);
  }

  /// 设置自定义属性
  void setProperty(String property, dynamic value) {
    _setValue(property, value);
  }

  /// 设置字符串属性
  void setString(String property, String value) {
    _setValue(property, value);
  }

  /// 设置单个属性值
  void _setValue(String property, dynamic value) {
    // 如果值没有变化，不做任何操作
    if (_valueCache[property] == value) return;

    // 更新缓存
    _valueCache[property] = value;

    // 更新属性
    _manager._updateProperty(elementId, {property: value}, options);
  }
}

/// 属性绑定管理器
/// 优化大量属性更新时的性能
class PropertyBindingManager {
  final PropertyPanelController _controller;

  /// 活跃的属性绑定
  final Map<String, PropertyBinding> _bindings = {};

  /// 批量更新定时器
  Timer? _batchTimer;

  /// 批量更新队列
  final Map<String, Map<String, dynamic>> _batchQueue = {};

  PropertyBindingManager(this._controller);

  /// 创建属性绑定
  PropertyBinding bindElement(
    String elementId, {
    PropertyBindingOptions options = const PropertyBindingOptions(),
  }) {
    // 重用现有绑定或创建新绑定
    return _bindings[elementId] ??= PropertyBinding._(
      elementId: elementId,
      manager: this,
      options: options,
    );
  }

  /// 批量绑定多个元素
  List<PropertyBinding> bindElements(
    List<String> elementIds, {
    PropertyBindingOptions options = const PropertyBindingOptions(),
  }) {
    return elementIds.map((id) => bindElement(id, options: options)).toList();
  }

  /// 清除所有绑定
  void clearBindings() {
    _bindings.clear();
    _batchQueue.clear();
    _batchTimer?.cancel();
  }

  /// 删除特定元素的绑定
  void removeBinding(String elementId) {
    _bindings.remove(elementId);
    _batchQueue.remove(elementId);
  }

  /// 执行批量更新
  void _executeBatchUpdate() {
    if (_batchQueue.isEmpty) return;

    // 复制队列并清空原队列
    final updates = Map<String, Map<String, dynamic>>.from(_batchQueue);
    _batchQueue.clear();

    // 应用所有更新
    for (final entry in updates.entries) {
      _controller.updateElementProperties(entry.key, entry.value);
    }
  }

  /// 将更新添加到批量队列
  void _queueUpdate(String elementId, Map<String, dynamic> properties) {
    _batchQueue[elementId] ??= {};
    _batchQueue[elementId]!.addAll(properties);

    // 如果没有计时器，创建一个
    _batchTimer ??= Timer(const Duration(milliseconds: 16), () {
      _executeBatchUpdate();
      _batchTimer = null;
    });
  }

  /// 更新属性 - 内部方法
  void _updateProperty(
    String elementId,
    Map<String, dynamic> properties,
    PropertyBindingOptions options,
  ) {
    switch (options.type) {
      case PropertyBindingType.direct:
        _controller.updateElementProperties(elementId, properties);
        break;
      case PropertyBindingType.throttle:
        // TODO: 实现节流逻辑
        _controller.updateElementProperties(elementId, properties);
        break;
      case PropertyBindingType.debounce:
        // 使用控制器的批量更新（已有防抖功能）
        _controller.updateElementProperties(elementId, properties);
        break;
      case PropertyBindingType.batch:
        // 将更新添加到批量队列
        _queueUpdate(elementId, properties);
        break;
    }
  }
}

/// 属性绑定选项
class PropertyBindingOptions {
  final PropertyBindingType type;
  final Duration delay;
  final bool trackHistory;
  final bool notifyOnChange;

  const PropertyBindingOptions({
    this.type = PropertyBindingType.direct,
    this.delay = const Duration(milliseconds: 300),
    this.trackHistory = true,
    this.notifyOnChange = true,
  });
}

/// 属性绑定类型
enum PropertyBindingType {
  /// 直接绑定 - 立即更新
  direct,

  /// 节流绑定 - 限制更新频率
  throttle,

  /// 防抖绑定 - 等待变化停止后更新
  debounce,

  /// 批量绑定 - 收集多个变化一次更新
  batch,
}
