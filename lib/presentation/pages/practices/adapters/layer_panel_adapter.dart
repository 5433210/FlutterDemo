// filepath: lib/presentation/pages/practices/adapters/layer_panel_adapter.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../canvas/compatibility/canvas_controller_adapter.dart';
import '../../../../canvas/core/interfaces/element_data.dart';
import '../../../../canvas/core/interfaces/layer_data.dart';
import '../../../widgets/practice/m3_practice_layer_panel.dart';
import 'property_panel_adapter.dart';

/// 图层面板适配器
///
/// 将图层管理功能集成到Canvas架构中，包括:
/// - 图层显示和隐藏
/// - 图层锁定和解锁
/// - 图层重排序
/// - 图层添加和删除
/// - 图层元素管理
class LayerPanelAdapter extends BasePropertyPanelAdapter {
  final CanvasControllerAdapter canvasController;
  final ValueNotifier<List<LayerData>> _layersNotifier;
  final ValueNotifier<String?> _activeLayerIdNotifier;
  final Function(String)? onLayerSelect;
  final Function(String, bool)? onLayerVisibilityToggle;
  final Function(String, bool)? onLayerLockToggle;
  final VoidCallback? onAddLayer;
  final Function(String)? onDeleteLayer;
  final Function(int, int)? onReorderLayer;

  LayerPanelAdapter({
    required this.canvasController,
    this.onLayerSelect,
    this.onLayerVisibilityToggle,
    this.onLayerLockToggle,
    this.onAddLayer,
    this.onDeleteLayer,
    this.onReorderLayer,
  })  : _layersNotifier = ValueNotifier([]),
        _activeLayerIdNotifier = ValueNotifier(null) {
    _setupListeners();
  }

  /// 当前活动图层ID
  String? get activeLayerId => _activeLayerIdNotifier.value;

  /// 活动图层通知器
  ValueListenable<String?> get activeLayerIdListenable =>
      _activeLayerIdNotifier;
  String get adapterId => 'layer_panel_adapter';
  String get adapterType => 'layer_panel';

  /// 当前图层列表
  List<LayerData> get layers => _layersNotifier.value;

  /// 图层通知器
  ValueListenable<List<LayerData>> get layersListenable => _layersNotifier;

  @override
  List<String> get supportedElementTypes => ['layer'];

  /// 添加新图层
  void addLayer({String? name, String? layerId}) {
    debugPrint('➕ Adding new layer: $name');

    final newLayerId =
        layerId ?? 'layer_${DateTime.now().millisecondsSinceEpoch}';
    final layerName = name ?? '图层 ${layers.length + 1}';

    // 通过Canvas系统添加图层
    _addLayerToCanvas(newLayerId, layerName);

    // 调用外部回调
    onAddLayer?.call();

    refresh();
  }

  Widget buildPanel(BuildContext context) {
    debugPrint('🏗️ LayerPanelAdapter.buildPanel() called');

    return ValueListenableBuilder<List<LayerData>>(
      valueListenable: _layersNotifier,
      builder: (context, layers, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _activeLayerIdNotifier,
          builder: (context, activeLayerId, child) {
            debugPrint(
                '🔄 Layer state updated: ${layers.length} layers, active: $activeLayerId');

            // 转换为M3PracticeLayerPanel所需的格式
            _convertLayersToLegacyFormat(layers); // 用于遗留系统兼容

            return M3PracticeLayerPanel(
              controller: _createLegacyController(),
              onLayerSelect: _handleLayerSelect,
              onLayerVisibilityToggle: _handleLayerVisibilityToggle,
              onLayerLockToggle: _handleLayerLockToggle,
              onAddLayer: _handleAddLayer,
              onDeleteLayer: _handleDeleteLayer,
              onReorderLayer: _handleReorderLayer,
            );
          },
        );
      },
    );
  }

  @override
  Widget buildPropertyEditor({
    required BuildContext context,
    required List<dynamic> selectedElements,
    required Function(String elementId, String property, dynamic value)
        onPropertyChanged,
    PropertyPanelConfig? config,
  }) {
    // 图层面板不使用标准属性编辑器，而是使用自定义的图层面板UI
    return buildPanel(context);
  }

  /// 删除图层
  void deleteLayer(String layerId) {
    debugPrint('🗑️ Deleting layer: $layerId');

    if (layers.length <= 1) {
      debugPrint('⚠️ Cannot delete the last layer');
      return;
    }

    // 通过Canvas系统删除图层
    _deleteLayerFromCanvas(layerId);

    // 调用外部回调
    onDeleteLayer?.call(layerId);

    refresh();
  }

  void dispose() {
    debugPrint('🧹 LayerPanelAdapter.dispose() called');
    _layersNotifier.dispose();
    _activeLayerIdNotifier.dispose();
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    // 图层属性的默认值
    switch (propertyName) {
      case 'visible':
        return true;
      case 'locked':
        return false;
      case 'opacity':
        return 1.0;
      case 'blendMode':
        return 'normal';
      case 'zIndex':
        return layers.length;
      default:
        return null;
    }
  }

  /// 获取图层中的元素
  List<ElementData> getElementsInLayer(String layerId) {
    if (canvasController.stateManager == null) return [];

    return canvasController.stateManager!.getElementsByLayerId(layerId);
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    // 图层的属性定义
    return {
      'visible': const PropertyDefinition(
        name: 'visible',
        displayName: '可见性',
        type: PropertyType.boolean,
        defaultValue: true,
      ),
      'locked': const PropertyDefinition(
        name: 'locked',
        displayName: '锁定',
        type: PropertyType.boolean,
        defaultValue: false,
      ),
      'zIndex': const PropertyDefinition(
        name: 'zIndex',
        displayName: '层级',
        type: PropertyType.number,
        defaultValue: 0,
      ),
      'name': const PropertyDefinition(
        name: 'name',
        displayName: '名称',
        type: PropertyType.string,
        isRequired: true,
      ),
    };
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is! LayerData) return null;

    switch (propertyName) {
      case 'visible':
        return element.visible;
      case 'locked':
        return element.locked;
      case 'opacity':
        return element.opacity;
      case 'blendMode':
        return element.blendMode;
      case 'name':
        return element.name;
      case 'zIndex':
        return element.properties['zIndex'] ?? 0;
      default:
        return element.properties[propertyName];
    }
  }

  /// 移动元素到指定图层
  void moveElementToLayer(String elementId, String targetLayerId) {
    debugPrint('🔄 Moving element $elementId to layer $targetLayerId');

    canvasController.updateElement(elementId, {'layerId': targetLayerId});
    refresh();
  }

  void refresh() {
    debugPrint('� LayerPanelAdapter.refresh() called');

    if (canvasController.stateManager != null) {
      final stateManager = canvasController.stateManager;

      // 获取所有图层
      final allLayers = _getAllLayersFromCanvas(stateManager);
      _layersNotifier.value = List.from(allLayers);

      // 获取活动图层
      final activeLayer = _getActiveLayerFromCanvas(stateManager);
      _activeLayerIdNotifier.value = activeLayer?.id;

      debugPrint('✅ Layer state refreshed: ${allLayers.length} layers');
    }
  }

  /// 重排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    debugPrint('🔄 Reordering layer from $oldIndex to $newIndex');

    final currentLayers = List<LayerData>.from(layers);
    if (oldIndex < 0 ||
        oldIndex >= currentLayers.length ||
        newIndex < 0 ||
        newIndex >= currentLayers.length) {
      return;
    }

    final layer = currentLayers.removeAt(oldIndex);
    currentLayers.insert(newIndex, layer);

    // 更新图层顺序
    _updateLayerOrder(currentLayers);

    // 调用外部回调
    onReorderLayer?.call(oldIndex, newIndex);

    refresh();
  }

  /// 选择图层
  void selectLayer(String layerId) {
    debugPrint('🎯 Selecting layer: $layerId');

    _activeLayerIdNotifier.value = layerId;

    // 调用外部回调
    onLayerSelect?.call(layerId);
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is! String) return; // 应该是图层ID

    _updateLayerProperty(element, propertyName, value);
  }

  /// 切换图层锁定状态
  void toggleLayerLock(String layerId) {
    debugPrint('🔒 Toggling layer lock: $layerId');

    final layer = _getLayerById(layerId);
    if (layer == null) {
      debugPrint('⚠️ Layer not found: $layerId');
      return;
    }

    final newLockState = !layer.locked;

    // 使用更新的_updateLayerProperty方法更新locked属性
    _updateLayerProperty(layerId, 'locked', newLockState);

    // 调用外部回调
    onLayerLockToggle?.call(layerId, newLockState);

    refresh();
  }

  /// 切换图层可见性
  void toggleLayerVisibility(String layerId) {
    debugPrint('👁️ Toggling layer visibility: $layerId');

    final layer = _getLayerById(layerId);
    if (layer == null) {
      debugPrint('⚠️ Layer not found: $layerId');
      return;
    }

    final newVisibilityState = !layer.visible;

    // 使用更新的_updateLayerProperty方法更新visible属性
    _updateLayerProperty(layerId, 'visible', newVisibilityState);

    // 调用外部回调
    onLayerVisibilityToggle?.call(layerId, newVisibilityState);

    refresh();
  }

  void updateFromSelection(List<String> selectedElementIds) {
    debugPrint(
        '🎯 LayerPanelAdapter.updateFromSelection() called with: $selectedElementIds');

    // 图层面板不直接依赖于选中的元素，但可以高亮显示包含选中元素的图层
    if (selectedElementIds.isNotEmpty) {
      final element = canvasController.stateManager
          ?.getElementById(selectedElementIds.first);
      if (element != null) {
        _activeLayerIdNotifier.value = element.layerId;
      }
    }

    refresh();
  }

  /// 添加图层到Canvas
  void _addLayerToCanvas(String layerId, String name) {
    debugPrint('Adding layer to canvas: $layerId, name: $name');

    if (canvasController.stateManager == null) {
      debugPrint('⚠️ Warning: stateManager is null, cannot add layer');
      return;
    }

    try {
      // 创建新图层
      final layer = LayerData(
        id: layerId,
        name: name,
        visible: true,
        locked: false,
        properties: {'zIndex': layers.length},
      );

      canvasController.stateManager.createLayer(layer);

      // 如果这是第一个图层，自动选择它
      if (layers.isEmpty) {
        canvasController.stateManager.selectLayer(layerId);
      }

      debugPrint('✅ Layer added successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to add layer: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 转换图层为旧版格式
  Map<String, dynamic> _convertLayersToLegacyFormat(List<LayerData> layers) {
    return {
      'layers': layers
          .map((layer) => {
                'id': layer.id,
                'name': layer.name,
                'visible': layer.visible,
                'locked': layer.locked,
                'zIndex': layer.properties['zIndex'] ?? 0,
                'elementCount': getElementsInLayer(layer.id).length,
              })
          .toList(),
      'activeLayerId': activeLayerId,
    };
  }

  /// 创建旧版控制器适配
  dynamic _createLegacyController() {
    // 返回一个简化的控制器对象，包含必要的状态信息
    return _LegacyLayerController(
      layers: layers,
      activeLayerId: activeLayerId,
      getElementsInLayer: getElementsInLayer,
    );
  }

  /// 从Canvas删除图层
  void _deleteLayerFromCanvas(String layerId) {
    debugPrint('Deleting layer from canvas: $layerId');

    if (canvasController.stateManager == null) {
      debugPrint('⚠️ Warning: stateManager is null, cannot delete layer');
      return;
    }

    try {
      // 首先将该图层的所有元素移动到默认图层或第一个可用图层
      final elementsInLayer = getElementsInLayer(layerId);

      // 找到一个可用的目标图层（不是当前正在删除的图层）
      String? targetLayerId;
      for (final layer in layers) {
        if (layer.id != layerId) {
          targetLayerId = layer.id;
          break;
        }
      }

      // 如果没有其他图层，不能删除
      if (targetLayerId == null) {
        debugPrint('⚠️ Cannot delete the last layer');
        return;
      }

      // 移动所有元素到目标图层
      for (final element in elementsInLayer) {
        canvasController.stateManager
            .moveElementToLayer(element.id, targetLayerId);
      }

      // 然后删除图层
      canvasController.stateManager.deleteLayer(layerId);

      // 如果删除的是当前选中的图层，选中另一个图层
      if (activeLayerId == layerId) {
        canvasController.stateManager.selectLayer(targetLayerId);
      }

      debugPrint('✅ Layer deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to delete layer: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 获取活动图层
  LayerData? _getActiveLayerFromCanvas(dynamic stateManager) {
    debugPrint('Getting active layer from canvas');

    if (stateManager == null) {
      debugPrint('⚠️ Warning: stateManager is null, returning null');
      return null;
    }

    try {
      // 从Canvas状态管理器获取当前选中的图层
      final selectedLayerId = stateManager.selectedLayerId;

      if (selectedLayerId != null) {
        final layer = stateManager.getLayerById(selectedLayerId);
        if (layer != null) {
          debugPrint('✅ Retrieved active layer: ${layer.id} (${layer.name})');
          return layer;
        }
      }

      // 如果没有选中的图层，返回第一个图层
      final allLayers = _getAllLayersFromCanvas(stateManager);
      if (allLayers.isNotEmpty) {
        debugPrint(
            'ℹ️ No active layer, returning first layer: ${allLayers.first.id}');
        return allLayers.first;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to get active layer: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// 获取所有图层
  List<LayerData> _getAllLayersFromCanvas(dynamic stateManager) {
    debugPrint('Getting all layers from canvas');

    if (stateManager == null) {
      debugPrint('⚠️ Warning: stateManager is null, returning empty list');
      return [];
    }

    try {
      // 从Canvas状态管理器获取所有图层并按Z轴排序
      final layerState = stateManager.layerState;
      if (layerState == null) {
        debugPrint('⚠️ Warning: layerState is null, returning empty list');
        return [];
      }

      final layers = layerState.sortedLayers;
      debugPrint('✅ Retrieved ${layers.length} layers from canvas');

      // 如果没有图层，创建一个默认图层
      if (layers.isEmpty) {
        debugPrint('ℹ️ No layers found, creating a default layer');
        const defaultLayer = LayerData(
          id: 'default_layer',
          name: '默认图层',
          visible: true,
          locked: false,
          properties: {'zIndex': 0},
        );
        stateManager.createLayer(defaultLayer);
        return [defaultLayer];
      }

      return layers;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to get layers: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // 返回默认图层作为后备
      return [
        const LayerData(
          id: 'default',
          name: '默认图层',
          visible: true,
          locked: false,
          properties: {'zIndex': 0},
        )
      ];
    }
  }

  /// 根据ID获取图层
  LayerData? _getLayerById(String layerId) {
    try {
      return layers.firstWhere((layer) => layer.id == layerId);
    } catch (e) {
      return null;
    }
  }

  /// 处理添加图层
  void _handleAddLayer() {
    debugPrint('📝 LayerPanelAdapter handling add layer');
    addLayer();
  }

  /// 处理删除图层
  void _handleDeleteLayer(String layerId) {
    debugPrint('🗑️ LayerPanelAdapter handling delete layer: $layerId');
    deleteLayer(layerId);
  }

  /// 处理图层锁定切换
  void _handleLayerLockToggle(String layerId, bool isLocked) {
    debugPrint(
        '🔒 LayerPanelAdapter handling layer lock toggle: $layerId = $isLocked');

    _updateLayerProperty(layerId, 'locked', isLocked);
    onLayerLockToggle?.call(layerId, isLocked);
    refresh();
  }

  /// 处理图层选择
  void _handleLayerSelect(String layerId) {
    debugPrint('🎯 LayerPanelAdapter handling layer select: $layerId');
    selectLayer(layerId);
  }

  /// 处理图层可见性切换
  void _handleLayerVisibilityToggle(String layerId, bool isVisible) {
    debugPrint(
        '👁️ LayerPanelAdapter handling layer visibility toggle: $layerId = $isVisible');

    _updateLayerProperty(layerId, 'visible', isVisible);
    onLayerVisibilityToggle?.call(layerId, isVisible);
    refresh();
  }

  /// 处理重排序图层
  void _handleReorderLayer(int oldIndex, int newIndex) {
    debugPrint(
        '🔄 LayerPanelAdapter handling layer reorder: $oldIndex -> $newIndex');
    reorderLayers(oldIndex, newIndex);
  }

  /// Canvas控制器变化处理
  void _onCanvasControllerChanged() {
    refresh();
  }

  /// 设置监听器
  void _setupListeners() {
    debugPrint('🔗 Setting up LayerPanelAdapter listeners');

    // 监听Canvas控制器变化
    canvasController.addListener(_onCanvasControllerChanged);
  }

  /// 更新图层顺序
  void _updateLayerOrder(List<LayerData> orderedLayers) {
    debugPrint('Updating layer order in canvas');

    if (canvasController.stateManager == null) {
      debugPrint('⚠️ Warning: stateManager is null, cannot update layer order');
      return;
    }

    try {
      // 为每个图层分配新的zIndex值
      for (int i = 0; i < orderedLayers.length; i++) {
        final layerId = orderedLayers[i].id;
        _updateLayerProperty(layerId, 'zIndex', i);
      }

      debugPrint('✅ Layer order updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to update layer order: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 更新图层属性
  void _updateLayerProperty(String layerId, String property, dynamic value) {
    debugPrint('Updating layer property: $layerId.$property = $value');

    if (canvasController.stateManager == null) {
      debugPrint(
          '⚠️ Warning: stateManager is null, cannot update layer property');
      return;
    }

    try {
      // 创建属性更新映射
      final Map<String, dynamic> properties = {property: value};

      // 调用Canvas状态管理器的方法更新图层属性
      canvasController.stateManager.updateLayerProperties(layerId, properties);

      debugPrint('✅ Layer property updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to update layer property: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }
}

/// 旧版图层控制器适配类
class _LegacyLayerController {
  final List<LayerData> layers;
  final String? activeLayerId;
  final List<ElementData> Function(String) getElementsInLayer;

  _LegacyLayerController({
    required this.layers,
    required this.activeLayerId,
    required this.getElementsInLayer,
  });

  /// 提供与旧版控制器兼容的状态访问
  dynamic get state => _LegacyLayerState(
        layers: layers,
        selectedLayerId: activeLayerId,
        getElementsInLayer: getElementsInLayer,
      );
}

/// 旧版图层状态适配类
class _LegacyLayerState {
  final List<LayerData> layers;
  final String? selectedLayerId;
  final List<ElementData> Function(String) getElementsInLayer;

  _LegacyLayerState({
    required this.layers,
    required this.selectedLayerId,
    required this.getElementsInLayer,
  });

  /// 获取图层列表（转换为旧版格式）
  List<Map<String, dynamic>> get layerList {
    return layers
        .map((layer) => {
              'id': layer.id,
              'name': layer.name,
              'visible': layer.visible,
              'locked': layer.locked,
              'zIndex': layer.properties['zIndex'] ?? 0,
              'elements': getElementsInLayer(layer.id)
                  .map((element) => {
                        'id': element.id,
                        'type': element.type,
                        'name': element.properties['name'] ?? element.type,
                      })
                  .toList(),
            })
        .toList();
  }
}
