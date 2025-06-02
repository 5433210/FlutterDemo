// filepath: lib/canvas/state/layer_state.dart

import '../core/interfaces/layer_data.dart';

/// 图层集合状态
class LayerState {
  final Map<String, LayerData> _layers;
  final Set<String> _dirtyLayerIds;
  final int _zOrderCounter;

  const LayerState({
    Map<String, LayerData>? layers,
    Set<String>? dirtyLayerIds,
    int? zOrderCounter,
  })  : _layers = layers ?? const {},
        _dirtyLayerIds = dirtyLayerIds ?? const {},
        _zOrderCounter = zOrderCounter ?? 0;

  /// 需要重绘的图层ID集合
  Set<String> get dirtyLayerIds => Set.unmodifiable(_dirtyLayerIds);

  /// 图层计数
  int get layerCount => _layers.length;

  /// 所有图层
  Map<String, LayerData> get layers => Map.unmodifiable(_layers);

  /// 按Z轴逆序的图层列表（从顶到底）
  List<LayerData> get reversedLayers {
    return sortedLayers.reversed.toList();
  }

  /// 按Z轴排序的图层列表（从底到顶）
  List<LayerData> get sortedLayers {
    final layerList = _layers.values.toList();
    // 根据添加顺序排序，最后添加的显示在顶部
    return layerList
      ..sort((a, b) {
        // 解析properties中的zIndex进行排序
        final aIndex = a.properties['zIndex'] as int? ?? 0;
        final bIndex = b.properties['zIndex'] as int? ?? 0;
        return aIndex.compareTo(bIndex);
      });
  }

  /// Z序计数器
  int get zOrderCounter => _zOrderCounter;

  /// 添加图层
  LayerState addLayer(LayerData layer) {
    final newLayers = Map<String, LayerData>.from(_layers);

    // 设置zIndex属性（存储在properties中）
    final updatedProperties = Map<String, dynamic>.from(layer.properties);
    updatedProperties['zIndex'] = _zOrderCounter;

    final layerWithZIndex = LayerData(
      id: layer.id,
      name: layer.name,
      visible: layer.visible,
      locked: layer.locked,
      opacity: layer.opacity,
      blendMode: layer.blendMode,
      properties: updatedProperties,
    );

    newLayers[layer.id] = layerWithZIndex;

    final newDirtyIds = Set<String>.from(_dirtyLayerIds);
    newDirtyIds.add(layer.id);

    return LayerState(
      layers: newLayers,
      dirtyLayerIds: newDirtyIds,
      zOrderCounter: _zOrderCounter + 1,
    );
  }

  /// 清除脏标记
  LayerState clearDirtyFlags() {
    return LayerState(
      layers: _layers,
      dirtyLayerIds: const {},
      zOrderCounter: _zOrderCounter,
    );
  }

  /// 检查图层是否存在
  bool containsLayer(String id) => _layers.containsKey(id);

  /// 获取指定ID的图层
  LayerData? getLayerById(String id) => _layers[id];

  /// 标记图层为脏（需要重绘）
  LayerState markLayerDirty(String id) {
    if (!_layers.containsKey(id)) return this;

    final newDirtyIds = Set<String>.from(_dirtyLayerIds);
    newDirtyIds.add(id);

    return LayerState(
      layers: _layers,
      dirtyLayerIds: newDirtyIds,
      zOrderCounter: _zOrderCounter,
    );
  }

  /// 删除图层
  LayerState removeLayer(String id) {
    if (!_layers.containsKey(id)) return this;

    final newLayers = Map<String, LayerData>.from(_layers);
    newLayers.remove(id);

    final newDirtyIds = Set<String>.from(_dirtyLayerIds);
    newDirtyIds.remove(id);

    return LayerState(
      layers: newLayers,
      dirtyLayerIds: newDirtyIds,
      zOrderCounter: _zOrderCounter,
    );
  }

  /// 重新排序图层
  LayerState reorderLayers(int oldIndex, int newIndex) {
    final layerList = sortedLayers;

    if (oldIndex < 0 ||
        oldIndex >= layerList.length ||
        newIndex < 0 ||
        newIndex >= layerList.length) {
      return this;
    }

    // 获取要移动的图层
    final layer = layerList[oldIndex];

    // 移除图层
    layerList.removeAt(oldIndex);

    // 在新位置插入图层
    if (newIndex > oldIndex) {
      newIndex -= 1; // 调整索引，因为移除了元素
    }
    layerList.insert(newIndex, layer);

    // 更新所有图层的zIndex
    final newLayers = <String, LayerData>{};
    final dirtyIds = <String>{};

    for (int i = 0; i < layerList.length; i++) {
      final currentLayer = layerList[i];

      // 更新zIndex属性
      final updatedProperties =
          Map<String, dynamic>.from(currentLayer.properties);
      updatedProperties['zIndex'] = i;

      final updatedLayer = LayerData(
        id: currentLayer.id,
        name: currentLayer.name,
        visible: currentLayer.visible,
        locked: currentLayer.locked,
        opacity: currentLayer.opacity,
        blendMode: currentLayer.blendMode,
        properties: updatedProperties,
      );

      newLayers[updatedLayer.id] = updatedLayer;
      dirtyIds.add(updatedLayer.id);
    }

    return LayerState(
      layers: newLayers,
      dirtyLayerIds: dirtyIds,
      zOrderCounter: _zOrderCounter,
    );
  }

  /// 更新图层
  LayerState updateLayer(String id, LayerData layer) {
    if (!_layers.containsKey(id)) return this;

    final newLayers = Map<String, LayerData>.from(_layers);
    newLayers[id] = layer;

    final newDirtyIds = Set<String>.from(_dirtyLayerIds);
    newDirtyIds.add(id);

    return LayerState(
      layers: newLayers,
      dirtyLayerIds: newDirtyIds,
      zOrderCounter: _zOrderCounter,
    );
  }

  /// 更新图层属性
  LayerState updateLayerProperties(String id, Map<String, dynamic> properties) {
    final layer = _layers[id];
    if (layer == null) return this;

    // 合并属性
    final updatedProperties = Map<String, dynamic>.from(layer.properties);
    updatedProperties.addAll(properties);

    final updatedLayer = LayerData(
      id: layer.id,
      name: layer.name,
      visible: properties['visible'] ?? layer.visible,
      locked: properties['locked'] ?? layer.locked,
      opacity: properties['opacity'] != null
          ? (properties['opacity'] as num).toDouble()
          : layer.opacity,
      blendMode: properties['blendMode'] ?? layer.blendMode,
      properties: updatedProperties,
    );

    return updateLayer(id, updatedLayer);
  }
}
