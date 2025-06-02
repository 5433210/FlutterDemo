// filepath: lib/canvas/state/element_state.dart

import '../core/interfaces/element_data.dart';

/// 元素集合状态
class ElementState {
  final Map<String, ElementData> _elements;
  final Set<String> _dirtyElementIds;

  const ElementState({
    Map<String, ElementData>? elements,
    Set<String>? dirtyElementIds,
  })  : _elements = elements ?? const {},
        _dirtyElementIds = dirtyElementIds ?? const {};

  /// 需要重绘的元素ID集合
  Set<String> get dirtyElementIds => Set.unmodifiable(_dirtyElementIds);

  /// 所有元素
  Map<String, ElementData> get elements => Map.unmodifiable(_elements);

  /// 按Z轴排序的元素列表
  List<ElementData> get sortedElements {
    final elementList = _elements.values.toList();
    elementList.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return elementList;
  }

  /// 添加元素
  ElementState addElement(ElementData element) {
    final newElements = Map<String, ElementData>.from(_elements);
    newElements[element.id] = element;

    final newDirtyIds = Set<String>.from(_dirtyElementIds);
    newDirtyIds.add(element.id);

    return ElementState(
      elements: newElements,
      dirtyElementIds: newDirtyIds,
    );
  }

  /// 清除脏标记
  ElementState clearDirtyFlags() {
    return ElementState(
      elements: _elements,
      dirtyElementIds: const {},
    );
  }

  /// 检查元素是否存在
  bool containsElement(String id) => _elements.containsKey(id);

  /// 获取指定ID的元素
  ElementData? getElementById(String id) => _elements[id];

  /// 获取指定图层ID上的所有元素
  List<ElementData> getElementsByLayerId(String layerId) {
    return _elements.values
        .where((element) => element.layerId == layerId)
        .toList();
  }

  /// 标记元素为脏（需要重绘）
  ElementState markElementDirty(String id) {
    if (!_elements.containsKey(id)) return this;

    final newDirtyIds = Set<String>.from(_dirtyElementIds);
    newDirtyIds.add(id);

    return ElementState(
      elements: _elements,
      dirtyElementIds: newDirtyIds,
    );
  }

  /// 删除元素
  ElementState removeElement(String id) {
    if (!_elements.containsKey(id)) return this;

    final newElements = Map<String, ElementData>.from(_elements);
    newElements.remove(id);

    final newDirtyIds = Set<String>.from(_dirtyElementIds);
    newDirtyIds.remove(id);

    return ElementState(
      elements: newElements,
      dirtyElementIds: newDirtyIds,
    );
  }

  /// 批量删除元素
  ElementState removeElements(Iterable<String> ids) {
    ElementState newState = this;
    for (final id in ids) {
      newState = newState.removeElement(id);
    }
    return newState;
  }

  /// 更新元素
  ElementState updateElement(String id, ElementData element) {
    if (!_elements.containsKey(id)) return this;

    final newElements = Map<String, ElementData>.from(_elements);
    newElements[id] = element;

    final newDirtyIds = Set<String>.from(_dirtyElementIds);
    newDirtyIds.add(id);

    return ElementState(
      elements: newElements,
      dirtyElementIds: newDirtyIds,
    );
  }

  /// 更新指定图层上所有元素的属性
  ElementState updateElementsOnLayer(
      String layerId, Map<String, dynamic> properties) {
    final elementsOnLayer = getElementsByLayerId(layerId);
    ElementState newState = this;

    for (final element in elementsOnLayer) {
      final updatedElement = element.copyWith(
        visible: properties['visible'] ?? element.visible,
        locked: properties['locked'] ?? element.locked,
      );
      newState = newState.updateElement(element.id, updatedElement);
    }

    return newState;
  }
}
