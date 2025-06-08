import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'custom_operation.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 图层管理功能 Mixin
mixin LayerManagementMixin on ChangeNotifier {
  // 抽象接口
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  Uuid get uuid;

  /// 添加图层
  void addLayer() {
    checkDisposed();
    
    // 确保有当前页面
    if (state.currentPage == null) return;
    
    final newLayer = {
      'id': 'layer_${uuid.v4()}',
      'name': '图层 ${state.layers.length + 1}',
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
      'blendMode': 'normal',
    };

    final operation = AddLayerOperation(
      layer: newLayer,
      addLayer: (layer) {
        // 直接操作当前页面的图层列表
        if (!state.currentPage!.containsKey('layers')) {
          state.currentPage!['layers'] = <Map<String, dynamic>>[];
        }
        final layers = state.currentPage!['layers'] as List<dynamic>;
        layers.add(layer);
        state.selectedLayerId ??= layer['id'] as String;
      },
      removeLayer: (layerId) {
        if (state.currentPage != null && state.currentPage!.containsKey('layers')) {
          final layers = state.currentPage!['layers'] as List<dynamic>;
          layers.removeWhere((l) => l['id'] == layerId);
          if (state.selectedLayerId == layerId) {
            final currentLayers = state.layers;
            state.selectedLayerId = currentLayers.isNotEmpty
                ? currentLayers.first['id'] as String
                : null;
          }
        }
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    notifyListeners();
  }

  /// 添加新图层
  void addNewLayer() {
    checkDisposed();
    
    EditPageLogger.controllerDebug('添加新图层');
    
    // 确保有当前页面
    if (state.currentPage == null) {
      EditPageLogger.controllerWarning('没有当前页面，无法添加图层');
      return;
    }
    
    final layerName = '图层 ${state.layers.length + 1}';
    final newLayer = {
      'id': 'layer_${uuid.v4()}',
      'name': layerName,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
      'blendMode': 'normal',
    };

    debugPrint('  - New layer: $newLayer');

    // 直接操作当前页面的图层列表
    if (!state.currentPage!.containsKey('layers')) {
      state.currentPage!['layers'] = <Map<String, dynamic>>[];
      debugPrint('  - Created new layers list');
    }
    final layers = state.currentPage!['layers'] as List<dynamic>;
    layers.add(newLayer);
    
    debugPrint('  ✅ Layer added to page, total layers: ${layers.length}');
    
    state.selectedLayerId = newLayer['id'] as String;
    debugPrint('  - Selected layer ID: ${state.selectedLayerId}');
    
    markUnsaved();
    
    debugPrint('🔚 LayerManagementMixin: addNewLayer completed');
    notifyListeners();
  }

  void checkDisposed();

  /// 删除所有图层
  void deleteAllLayers() {
    checkDisposed();
    if (state.layers.isEmpty) return;

    final oldLayers = List<Map<String, dynamic>>.from(state.layers);
    final oldSelectedLayerId = state.selectedLayerId;

    final operation = DeleteAllLayersOperation(
      layers: oldLayers,
      selectedLayerId: oldSelectedLayerId,
      deleteLayers: () {
        state.layers.clear();
        state.selectedLayerId = null;
      },
      restoreLayers: (layers, selectedId) {
        state.layers.clear();
        state.layers.addAll(layers);
        state.selectedLayerId = selectedId;
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    notifyListeners();
  }

  /// 删除图层
  void deleteLayer(String layerId) {
    checkDisposed();
    
    // 确保有当前页面
    if (state.currentPage == null || !state.currentPage!.containsKey('layers')) return;
    
    final layers = state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex == -1) return;

    final deletedLayer = layers[layerIndex] as Map<String, dynamic>;

    // 获取该图层上的所有元素
    final elementsOnLayer = state.currentPageElements
        .where((e) => e['layerId'] == layerId)
        .toList();

    final operation = DeleteLayerOperation(
      layer: deletedLayer,
      layerIndex: layerIndex,
      elementsOnLayer: elementsOnLayer,
      insertLayer: (layer, index) {
        if (state.currentPage != null && state.currentPage!.containsKey('layers')) {
          final currentLayers = state.currentPage!['layers'] as List<dynamic>;
          currentLayers.insert(index, layer);
        }
      },
      removeLayer: (id) {
        if (state.currentPage != null && state.currentPage!.containsKey('layers')) {
          final currentLayers = state.currentPage!['layers'] as List<dynamic>;
          currentLayers.removeWhere((l) => l['id'] == id);
          
          // 删除该图层上的所有元素
          if (state.currentPage!.containsKey('elements')) {
            final elements = state.currentPage!['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['layerId'] == id);
          }
          
          if (state.selectedLayerId == id) {
            final remainingLayers = state.layers;
            if (remainingLayers.isNotEmpty) {
              // 选择上一个图层，如果没有则选择第一个
              final newIndex = (layerIndex - 1).clamp(0, remainingLayers.length - 1);
              state.selectedLayerId = remainingLayers[newIndex]['id'] as String;
            } else {
              state.selectedLayerId = null;
            }
          }
        }
      },
      addElements: (elements) {
        if (state.currentPage != null && state.currentPage!.containsKey('elements')) {
          final pageElements = state.currentPage!['elements'] as List<dynamic>;
          pageElements.addAll(elements);
        }
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    notifyListeners();
  }

  void duplicateLayer(String layerId) {
    if (state.currentPage == null) return;

    final layerIndex = state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final originalLayer = state.layers[layerIndex];

    // Create a duplicate layer with a new ID
    final newLayerId = uuid.v4();
    final duplicatedLayer = {
      ...Map<String, dynamic>.from(originalLayer),
      'id': newLayerId,
      'name': '${originalLayer['name']} (复制)',
      'order': state.layers.length, // Place at the end of the layers list
    };

    // Find all elements on the original layer
    final elementsOnLayer = <Map<String, dynamic>>[];
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final page = state.pages[state.currentPageIndex];
      final pageElements = page['elements'] as List<dynamic>;

      // Create copies of all elements in the layer with new IDs
      for (final element in pageElements) {
        if (element['layerId'] == layerId) {
          final elementCopy =
              Map<String, dynamic>.from(element as Map<String, dynamic>);
          // Create new ID for the element
          final String elementType = elementCopy['type'] as String;
          elementCopy['id'] = '${elementType}_${uuid.v4()}';
          elementCopy['layerId'] = newLayerId;

          // Offset the position slightly to make it visible
          elementCopy['x'] = (elementCopy['x'] as num).toDouble() + 20;
          elementCopy['y'] = (elementCopy['y'] as num).toDouble() + 20;

          elementsOnLayer.add(elementCopy);
        }
      }
    }

    final operation = BatchOperation(
      operations: [
        // Add the new layer
        AddLayerOperation(
          layer: duplicatedLayer,
          addLayer: (l) {
            if (state.currentPage != null) {
              final layers = state.currentPage!['layers'] as List<dynamic>;
              layers.add(l);
              state.hasUnsavedChanges = true;
            }
          },
          removeLayer: (id) {
            if (state.currentPage != null) {
              final layers = state.currentPage!['layers'] as List<dynamic>;
              layers.removeWhere((l) => l['id'] == id);
              state.hasUnsavedChanges = true;
            }
          },
        ),

        // Add all duplicated elements
        _createCustomOperation(
          execute: () {
            if (state.currentPageIndex >= 0 &&
                state.currentPageIndex < state.pages.length) {
              final page = state.pages[state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;
              elements.addAll(elementsOnLayer);

              // Select the new layer
              state.selectedLayerId = newLayerId;
              state.hasUnsavedChanges = true;
            }
            notifyListeners();
          },
          undo: () {
            if (state.currentPageIndex >= 0 &&
                state.currentPageIndex < state.pages.length) {
              final page = state.pages[state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;

              // Remove all elements from the duplicated layer
              final elementIds = elementsOnLayer.map((e) => e['id']).toList();
              elements.removeWhere((e) => elementIds.contains(e['id']));

              state.hasUnsavedChanges = true;
            }
            notifyListeners();
          },
          description: '添加复制图层中的元素',
        ),
      ],
      operationDescription: '复制图层',
    );

    undoRedoManager.addOperation(operation);
  }

  // void markUnsaved();

  void markUnsaved();

  /// 移动图层顺序
  void moveLayer(String layerId, int newIndex) {
    checkDisposed();
    
    // 确保有当前页面
    if (state.currentPage == null || !state.currentPage!.containsKey('layers')) return;
    
    final layers = state.currentPage!['layers'] as List<dynamic>;
    final currentIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (currentIndex == -1 || newIndex == currentIndex) return;

    final layer = layers.removeAt(currentIndex);
    layers.insert(newIndex.clamp(0, layers.length), layer);

    final operation = ReorderLayerOperation(
      oldIndex: currentIndex,
      newIndex: newIndex,
      reorderLayer: (fromIndex, toIndex) {
        if (state.currentPage != null && state.currentPage!.containsKey('layers')) {
          final currentLayers = state.currentPage!['layers'] as List<dynamic>;
          final layer = currentLayers.removeAt(fromIndex);
          currentLayers.insert(toIndex.clamp(0, currentLayers.length), layer);
        }
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    notifyListeners();
  }

  /// 重命名图层
  void renameLayer(String layerId, String newName) {
    updateLayerProperties(layerId, {'name': newName});
  }

  /// 重新排序图层
  void reorderLayer(int oldIndex, int newIndex) {
    if (state.currentPage == null ||
        !state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = state.currentPage!['layers'] as List<dynamic>;

    if (oldIndex < 0 ||
        oldIndex >= layers.length ||
        newIndex < 0 ||
        newIndex >= layers.length) {
      return;
    }

    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex, layer);

    // 更新图层的顺序属性，确保渲染顺序正确
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      layer['order'] = i;
    }

    state.hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    if (state.currentPage == null ||
        !state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = state.currentPage!['layers'] as List<dynamic>;

    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= layers.length ||
        newIndex >= layers.length) {
      return;
    }

    final operation = ReorderLayerOperation(
      oldIndex: oldIndex,
      newIndex: newIndex,
      reorderLayer: (oldIndex, newIndex) {
        if (state.currentPage != null &&
            state.currentPage!.containsKey('layers')) {
          final layers = state.currentPage!['layers'] as List<dynamic>;
          final layer = layers.removeAt(oldIndex);
          layers.insert(newIndex, layer);

          // 更新order属性
          for (int i = 0; i < layers.length; i++) {
            final layer = layers[i];
            layer['order'] = i;
          }
        }

        state.hasUnsavedChanges = true;
        notifyListeners();
      },
    );

    undoRedoManager.addOperation(operation);
  }

  /// 选择图层
  void selectLayer(String layerId) {
    checkDisposed();
    
    // 确保有当前页面
    if (state.currentPage == null || !state.currentPage!.containsKey('layers')) return;
    
    final layers = state.currentPage!['layers'] as List<dynamic>;
    if (layers.any((l) => l['id'] == layerId)) {
      state.selectedLayerId = layerId;
      notifyListeners();
    }
  }

  /// 设置图层锁定状态
  void setLayerLocked(String layerId, bool isLocked) {
    updateLayerProperties(layerId, {'isLocked': isLocked});
  }

  /// 设置图层透明度
  void setLayerOpacity(String layerId, double opacity) {
    updateLayerProperties(layerId, {'opacity': opacity.clamp(0.0, 1.0)});
  }

  /// 设置图层可见性
  void setLayerVisibility(String layerId, bool isVisible) {
    updateLayerProperties(layerId, {'isVisible': isVisible});
  }

  /// 显示所有图层
  void showAllLayers() {
    if (state.currentPage == null ||
        !state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = state.currentPage!['layers'] as List<dynamic>;
    final operations = <UndoableOperation>[];

    for (final layer in layers) {
      final layerId = layer['id'] as String;
      final isVisible = layer['isVisible'] as bool? ?? true;

      if (!isVisible) {
        final oldProperties = Map<String, dynamic>.from(layer);
        final newProperties =
            Map<String, dynamic>.from({...layer, 'isVisible': true});

        operations.add(
          UpdateLayerPropertyOperation(
            layerId: layerId,
            oldProperties: oldProperties,
            newProperties: newProperties,
            updateLayer: (id, props) {
              if (state.currentPage != null &&
                  state.currentPage!.containsKey('layers')) {
                final layers = state.currentPage!['layers'] as List<dynamic>;
                final index = layers.indexWhere((l) => l['id'] == id);
                if (index >= 0) {
                  layers[index] = props;
                  state.hasUnsavedChanges = true;
                }
              }
            },
          ),
        );
      }
    }

    if (operations.isNotEmpty) {
      final batchOperation = BatchOperation(
        operations: operations,
        operationDescription: '显示所有图层',
      );

      undoRedoManager.addOperation(batchOperation);
    } else {
      // 如果没有需要修改的图层，直接通知UI刷新
      notifyListeners();
    }
  }

  /// 切换图层锁定状态
  void toggleLayerLock(String layerId, bool isLocked) {
    if (state.currentPage == null ||
        !state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((layer) => layer['id'] == layerId);
    if (layerIndex >= 0) {
      layers[layerIndex]['isLocked'] = isLocked;
      state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 切换图层可见性
  void toggleLayerVisibility(String layerId, bool isVisible) {
    if (state.currentPage == null ||
        !state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((layer) => layer['id'] == layerId);
    if (layerIndex >= 0) {
      layers[layerIndex]['isVisible'] = isVisible;
      state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 更新图层属性
  void updateLayerProperties(String layerId, Map<String, dynamic> properties) {
    checkDisposed();
    
    debugPrint('🔧 LayerManagementMixin: updateLayerProperties called');
    debugPrint('  - layerId: $layerId');
    debugPrint('  - properties: $properties');
    
    // 确保有当前页面
    if (state.currentPage == null || !state.currentPage!.containsKey('layers')) {
      debugPrint('  ❌ No current page or layers');
      return;
    }
    
    final layers = state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex == -1) {
      debugPrint('  ❌ Layer not found with id: $layerId');
      return;
    }

    final oldProperties = <String, dynamic>{};
    final layer = layers[layerIndex] as Map<String, dynamic>;
    
    debugPrint('  - Layer found at index: $layerIndex');
    debugPrint('  - Current layer data: $layer');

    // 保存旧值
    for (final key in properties.keys) {
      if (layer.containsKey(key)) {
        oldProperties[key] = layer[key];
      }
    }
    
    debugPrint('  - Old properties: $oldProperties');

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: properties,
      updateLayer: (id, props) {
        debugPrint('🔄 Executing layer property update');
        debugPrint('  - layerId: $id');
        debugPrint('  - props: $props');
        
        if (state.currentPage != null && state.currentPage!.containsKey('layers')) {
          final currentLayers = state.currentPage!['layers'] as List<dynamic>;
          final index = currentLayers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            final targetLayer = currentLayers[index] as Map<String, dynamic>;
            debugPrint('  - Updating layer at index $index: $targetLayer');
            
            props.forEach((key, value) {
              final oldValue = targetLayer[key];
              targetLayer[key] = value;
              debugPrint('    ✅ Updated $key: $oldValue -> $value');
            });
            
            debugPrint('  - Layer after update: $targetLayer');
            state.hasUnsavedChanges = true;
          } else {
            debugPrint('  ❌ Layer not found during update with id: $id');
          }
        } else {
          debugPrint('  ❌ No current page during update');
        }
      },
    );

    // 立即执行操作
    debugPrint('🚀 Executing layer update operation immediately');
    operation.execute();
    
    // 然后添加到撤销管理器
    undoRedoManager.addOperation(operation);
    markUnsaved();
    
    debugPrint('🔚 LayerManagementMixin: updateLayerProperties completed');
    notifyListeners();
  }

  /// 创建自定义操作
  UndoableOperation _createCustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required String description,
  }) {
    return CustomOperation(
      execute: execute,
      undo: undo,
      description: description,
    );
  }
}
