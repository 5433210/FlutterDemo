import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/logging/logger.dart';

/// 抽象撤销操作接口
abstract class UndoableOperation {
  String get description;
  void execute();
  void undo();
}

/// 添加元素操作
class AddElementOperation implements UndoableOperation {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;

  @override
  final String description = '添加元素';

  AddElementOperation({
    required this.element,
    required this.addElement,
    required this.removeElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行添加元素操作',
      data: {
        'elementId': element['id'],
        'elementType': element['type'],
        'operation': 'add_element_execute',
      },
    );
    addElement(element);
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '撤销添加元素操作',
      data: {
        'elementId': element['id'],
        'operation': 'add_element_undo',
      },
    );
    removeElement(element['id'] as String);
  }
}

/// 删除元素操作
class DeleteElementOperation implements UndoableOperation {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;

  @override
  final String description = '删除元素';

  DeleteElementOperation({
    required this.element,
    required this.addElement,
    required this.removeElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行删除元素操作',
      data: {
        'elementId': element['id'],
        'elementType': element['type'],
        'operation': 'delete_element_execute',
      },
    );
    removeElement(element['id'] as String);
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '撤销删除元素操作',
      data: {
        'elementId': element['id'],
        'operation': 'delete_element_undo',
      },
    );
    addElement(element);
  }
}

/// 元素属性操作
class ElementPropertyOperation implements UndoableOperation {
  final String elementId;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final Function(String, Map<String, dynamic>) updateElement;

  @override
  final String description = '更新元素属性';

  ElementPropertyOperation({
    required this.elementId,
    required this.oldProperties,
    required this.newProperties,
    required this.updateElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行元素属性更新操作',
      data: {
        'elementId': elementId,
        'changedProperties': newProperties.keys.toList(),
        'operation': 'property_update_execute',
      },
    );
    updateElement(elementId, newProperties);
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '撤销元素属性更新操作',
      data: {
        'elementId': elementId,
        'restoredProperties': oldProperties.keys.toList(),
        'operation': 'property_update_undo',
      },
    );
    updateElement(elementId, oldProperties);
  }
}

/// 批量操作
class BatchOperation implements UndoableOperation {
  final List<UndoableOperation> operations;
  @override
  final String operationDescription;

  BatchOperation({
    required this.operations,
    required this.operationDescription,
  });

  @override
  String get description => operationDescription;

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行批量操作',
      data: {
        'operationCount': operations.length,
        'description': operationDescription,
        'operation': 'batch_execute',
      },
    );
    
    for (final operation in operations) {
      operation.execute();
    }
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销批量操作',
      data: {
        'operationCount': operations.length,
        'description': operationDescription,
        'operation': 'batch_undo',
      },
    );
    
    for (final operation in operations.reversed) {
      operation.undo();
    }
  }
}

/// 元素位移操作
class ElementTranslationOperation implements UndoableOperation {
  final List<String> elementIds;
  final List<Map<String, dynamic>> oldPositions;
  final List<Map<String, dynamic>> newPositions;
  final Function(String, Map<String, dynamic>) updateElement;

  @override
  final String description = '移动元素';

  ElementTranslationOperation({
    required this.elementIds,
    required this.oldPositions,
    required this.newPositions,
    required this.updateElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行元素移动操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'element_translation_execute',
      },
    );
    
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], newPositions[i]);
    }
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '🔧 DEBUG: 开始撤销元素移动操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'element_translation_undo_start',
      },
    );
    
    for (int i = 0; i < elementIds.length; i++) {
      EditPageLogger.controllerDebug(
        '🔧 DEBUG: 撤销单个元素移动',
        data: {
          'elementId': elementIds[i],
          'oldPosition': oldPositions[i],
          'operation': 'element_translation_undo_item',
        },
      );
      updateElement(elementIds[i], oldPositions[i]);
    }
    
    EditPageLogger.controllerDebug(
      '🔧 DEBUG: 元素移动撤销操作完成',
      data: {
        'elementCount': elementIds.length,
        'operation': 'element_translation_undo_complete',
      },
    );
  }
}

/// 元素调整大小操作
class ResizeElementOperation implements UndoableOperation {
  final List<String> elementIds;
  final List<Map<String, dynamic>> oldSizes;
  final List<Map<String, dynamic>> newSizes;
  final Function(String, Map<String, dynamic>) updateElement;

  @override
  final String description = '调整元素大小';

  ResizeElementOperation({
    required this.elementIds,
    required this.oldSizes,
    required this.newSizes,
    required this.updateElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行元素调整大小操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'resize_element_execute',
      },
    );
    
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], newSizes[i]);
    }
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '🔧 DEBUG: 开始撤销元素调整大小操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'operation': 'resize_element_undo_start',
      },
    );
    
    for (int i = 0; i < elementIds.length; i++) {
      EditPageLogger.controllerDebug(
        '🔧 DEBUG: 撤销单个元素调整大小',
        data: {
          'elementId': elementIds[i],
          'oldSize': oldSizes[i],
          'operation': 'resize_element_undo_item',
        },
      );
      updateElement(elementIds[i], oldSizes[i]);
    }
    
    EditPageLogger.controllerDebug(
      '🔧 DEBUG: 元素调整大小撤销操作完成',
      data: {
        'elementCount': elementIds.length,
        'operation': 'resize_element_undo_complete',
      },
    );
  }
}

/// 元素旋转操作
class ElementRotationOperation implements UndoableOperation {
  final List<String> elementIds;
  final List<double> oldRotations;
  final List<double> newRotations;
  final Function(String, Map<String, dynamic>) updateElement;

  @override
  final String description = '旋转元素';

  ElementRotationOperation({
    required this.elementIds,
    required this.oldRotations,
    required this.newRotations,
    required this.updateElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行元素旋转操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'rotationValues': newRotations,
        'operation': 'rotation_execute',
      },
    );
    
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], {'rotation': newRotations[i]});
    }
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '撤销元素旋转操作',
      data: {
        'elementCount': elementIds.length,
        'elementIds': elementIds,
        'rotationValues': oldRotations,
        'operation': 'rotation_undo',
      },
    );
    
    for (int i = 0; i < elementIds.length; i++) {
      updateElement(elementIds[i], {'rotation': oldRotations[i]});
    }
  }
}

/// 组合元素旋转操作 - 处理子元素状态的完整保存和恢复
class GroupElementRotationOperation implements UndoableOperation {
  final String groupElementId;
  final Map<String, dynamic> oldGroupState;
  final Map<String, dynamic> newGroupState;
  final Function(String, Map<String, dynamic>) updateElement;

  @override
  final String description = '旋转组合元素';

  GroupElementRotationOperation({
    required this.groupElementId,
    required this.oldGroupState,
    required this.newGroupState,
    required this.updateElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerDebug(
      '执行组合元素旋转操作',
      data: {
        'groupElementId': groupElementId,
        'oldRotation': oldGroupState['rotation'],
        'newRotation': newGroupState['rotation'],
        'operation': 'group_rotation_execute',
      },
    );
    
    // 恢复整个组合元素的状态，包括子元素
    updateElement(groupElementId, newGroupState);
  }

  @override
  void undo() {
    EditPageLogger.controllerDebug(
      '撤销组合元素旋转操作',
      data: {
        'groupElementId': groupElementId,
        'oldRotation': oldGroupState['rotation'],
        'newRotation': newGroupState['rotation'],
        'operation': 'group_rotation_undo',
      },
    );
    
    // 🔧 添加详细的状态调试信息
    if (oldGroupState['type'] == 'group') {
      final content = oldGroupState['content'] as Map<String, dynamic>?;
      final children = content?['children'] as List<dynamic>? ?? [];
      
      EditPageLogger.controllerDebug('🔧 恢复组合元素完整状态', data: {
        'groupElementId': groupElementId,
        'restoredRotation': oldGroupState['rotation'],
        'restoredPosition': {'x': oldGroupState['x'], 'y': oldGroupState['y']},
        'restoredSize': {'width': oldGroupState['width'], 'height': oldGroupState['height']},
        'restoredChildrenCount': children.length,
        'restoredChildrenDetails': children.map((child) {
          final childMap = child as Map<String, dynamic>;
          return {
            'id': childMap['id'],
            'x': childMap['x'],
            'y': childMap['y'],
            'rotation': childMap['rotation'],
          };
        }).toList(),
        'operation': 'detailed_undo_state_restore',
      });
    }
    
    // 恢复整个组合元素的状态，包括子元素
    updateElement(groupElementId, oldGroupState);
  }
}

/// 添加图层操作
class AddLayerOperation implements UndoableOperation {
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) addLayer;
  final Function(String) removeLayer;

  @override
  final String description = '添加图层';

  AddLayerOperation({
    required this.layer,
    required this.addLayer,
    required this.removeLayer,
  });

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行添加图层操作',
      data: {
        'layerId': layer['id'],
        'layerName': layer['name'],
        'operation': 'add_layer_execute',
      },
    );
    addLayer(layer);
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销添加图层操作',
      data: {
        'layerId': layer['id'],
        'operation': 'add_layer_undo',
      },
    );
    removeLayer(layer['id'] as String);
  }
}

/// 删除图层操作
class DeleteLayerOperation implements UndoableOperation {
  final Map<String, dynamic> layer;
  final int layerIndex;
  final List<Map<String, dynamic>> elementsOnLayer;
  final Function(Map<String, dynamic>, int) insertLayer;
  final Function(String) removeLayer;
  final Function(List<Map<String, dynamic>>) addElements;

  @override
  final String description = '删除图层';

  DeleteLayerOperation({
    required this.layer,
    required this.layerIndex,
    required this.elementsOnLayer,
    required this.insertLayer,
    required this.removeLayer,
    required this.addElements,
  });

  @override
  void execute() {
    removeLayer(layer['id'] as String);
  }

  @override
  void undo() {
    insertLayer(layer, layerIndex);
    addElements(elementsOnLayer);
  }
}

/// 更新图层属性操作
class UpdateLayerPropertyOperation implements UndoableOperation {
  final String layerId;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final Function(String, Map<String, dynamic>) updateLayer;

  @override
  final String description = '更新图层属性';

  UpdateLayerPropertyOperation({
    required this.layerId,
    required this.oldProperties,
    required this.newProperties,
    required this.updateLayer,
  });

  @override
  void execute() {
    updateLayer(layerId, newProperties);
  }

  @override
  void undo() {
    updateLayer(layerId, oldProperties);
  }
}

/// 重新排序图层操作
class ReorderLayerOperation implements UndoableOperation {
  final int oldIndex;
  final int newIndex;
  final Function(int, int) reorderLayer;

  @override
  final String description = '重新排序图层';

  ReorderLayerOperation({
    required this.oldIndex,
    required this.newIndex,
    required this.reorderLayer,
  });

  @override
  void execute() {
    reorderLayer(oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderLayer(newIndex, oldIndex);
  }
}

/// 添加页面操作
class AddPageOperation implements UndoableOperation {
  final Map<String, dynamic> page;
  final Function(Map<String, dynamic>) addPage;
  final Function(String) removePage;

  @override
  final String description = '添加页面';

  AddPageOperation({
    required this.page,
    required this.addPage,
    required this.removePage,
  });

  @override
  void execute() {
    addPage(page);
  }

  @override
  void undo() {
    removePage(page['id'] as String);
  }
}

/// 重新排序页面操作
class ReorderPageOperation implements UndoableOperation {
  final int oldIndex;
  final int newIndex;
  final Function(int, int) reorderPage;

  @override
  final String description = '重新排序页面';

  ReorderPageOperation({
    required this.oldIndex,
    required this.newIndex,
    required this.reorderPage,
  });

  @override
  void execute() {
    reorderPage(oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderPage(newIndex, oldIndex);
  }
}

/// 更新页面属性操作
class UpdatePagePropertyOperation implements UndoableOperation {
  final int pageIndex;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final Function(int, Map<String, dynamic>) updatePage;

  @override
  final String description = '更新页面属性';

  UpdatePagePropertyOperation({
    required this.pageIndex,
    required this.oldProperties,
    required this.newProperties,
    required this.updatePage,
  });

  @override
  void execute() {
    updatePage(pageIndex, newProperties);
  }

  @override
  void undo() {
    updatePage(pageIndex, oldProperties);
  }
}

/// 组合元素操作
class GroupElementsOperation implements UndoableOperation {
  final List<Map<String, dynamic>> elements;
  final Map<String, dynamic> groupElement;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;
  final Function(List<String>) removeElements;

  @override
  final String description = '组合元素';

  GroupElementsOperation({
    required this.elements,
    required this.groupElement,
    required this.addElement,
    required this.removeElement,
    required this.removeElements,
  });

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行组合元素操作',
      data: {
        'elementCount': elements.length,
        'elementIds': elements.map((e) => e['id']).toList(),
        'groupElementId': groupElement['id'],
        'operation': 'group_elements_execute',
      },
    );
    
    // 删除原来的元素
    final elementIds = elements.map((e) => e['id'] as String).toList();
    removeElements(elementIds);
    
    // 添加组合元素
    addElement(groupElement);
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销组合元素操作',
      data: {
        'groupElementId': groupElement['id'],
        'restoredElementCount': elements.length,
        'operation': 'group_elements_undo',
      },
    );
    
    // 删除组合元素
    removeElement(groupElement['id'] as String);
    
    // 恢复原来的元素
    for (final element in elements) {
      addElement(element);
    }
  }
}

/// 取消组合元素操作
class UngroupElementOperation implements UndoableOperation {
  final Map<String, dynamic> groupElement;
  final List<Map<String, dynamic>> childElements;
  final Function(Map<String, dynamic>) addElement;
  final Function(String) removeElement;
  final Function(List<Map<String, dynamic>>) addElements;

  @override
  final String description = '取消组合元素';

  UngroupElementOperation({
    required this.groupElement,
    required this.childElements,
    required this.addElement,
    required this.removeElement,
    required this.addElements,
  });

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行取消组合元素操作',
      data: {
        'groupElementId': groupElement['id'],
        'childElementCount': childElements.length,
        'childElementIds': childElements.map((e) => e['id']).toList(),
        'operation': 'ungroup_element_execute',
      },
    );
    
    // 删除组合元素
    removeElement(groupElement['id'] as String);
    
    // 添加子元素
    addElements(childElements);
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销取消组合元素操作',
      data: {
        'groupElementId': groupElement['id'],
        'removedChildCount': childElements.length,
        'operation': 'ungroup_element_undo',
      },
    );
    
    // 删除子元素
    final childIds = childElements.map((e) => e['id'] as String).toList();
    for (final id in childIds) {
      removeElement(id);
    }
    
    // 恢复组合元素
    addElement(groupElement);
  }
}

/// 格式刷操作
class FormatPainterOperation implements UndoableOperation {
  final List<String> targetElementIds;
  final List<Map<String, dynamic>> oldPropertiesList;
  final List<Map<String, dynamic>> newPropertiesList;
  final Function(String, Map<String, dynamic>) updateElement;

  @override
  final String description = '应用格式刷';

  FormatPainterOperation({
    required this.targetElementIds,
    required this.oldPropertiesList,
    required this.newPropertiesList,
    required this.updateElement,
  });

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行格式刷操作',
      data: {
        'targetElementCount': targetElementIds.length,
        'targetElementIds': targetElementIds,
        'operation': 'format_painter_execute',
      },
    );
    
    for (int i = 0; i < targetElementIds.length; i++) {
      updateElement(targetElementIds[i], newPropertiesList[i]);
    }
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销格式刷操作',
      data: {
        'targetElementCount': targetElementIds.length,
        'targetElementIds': targetElementIds,
        'operation': 'format_painter_undo',
      },
    );
    
    for (int i = 0; i < targetElementIds.length; i++) {
      updateElement(targetElementIds[i], oldPropertiesList[i]);
    }
  }
}

/// 元素置于顶层操作
class BringElementToFrontOperation implements UndoableOperation {
  final String elementId;
  final int oldIndex;
  final int newIndex;
  final Function(String, int, int) reorderElement;

  @override
  final String description = '置于顶层';

  BringElementToFrontOperation({
    required this.elementId,
    required this.oldIndex,
    required this.newIndex,
    required this.reorderElement,
  });

  @override
  void execute() {
    reorderElement(elementId, oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderElement(elementId, newIndex, oldIndex);
  }
}

/// 元素置于底层操作
class SendElementToBackOperation implements UndoableOperation {
  final String elementId;
  final int oldIndex;
  final int newIndex;
  final Function(String, int, int) reorderElement;

  @override
  final String description = '置于底层';

  SendElementToBackOperation({
    required this.elementId,
    required this.oldIndex,
    required this.newIndex,
    required this.reorderElement,
  });

  @override
  void execute() {
    reorderElement(elementId, oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderElement(elementId, newIndex, oldIndex);
  }
}

/// 元素上移一层操作
class MoveElementUpOperation implements UndoableOperation {
  final String elementId;
  final int oldIndex;
  final int newIndex;
  final Function(String, int, int) reorderElement;

  @override
  final String description = '上移一层';

  MoveElementUpOperation({
    required this.elementId,
    required this.oldIndex,
    required this.newIndex,
    required this.reorderElement,
  });

  @override
  void execute() {
    reorderElement(elementId, oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderElement(elementId, newIndex, oldIndex);
  }
}

/// 元素下移一层操作
class MoveElementDownOperation implements UndoableOperation {
  final String elementId;
  final int oldIndex;
  final int newIndex;
  final Function(String, int, int) reorderElement;

  @override
  final String description = '下移一层';

  MoveElementDownOperation({
    required this.elementId,
    required this.oldIndex,
    required this.newIndex,
    required this.reorderElement,
  });

  @override
  void execute() {
    reorderElement(elementId, oldIndex, newIndex);
  }

  @override
  void undo() {
    reorderElement(elementId, newIndex, oldIndex);
  }
}

/// 粘贴元素操作
class PasteElementOperation implements UndoableOperation {
  final List<Map<String, dynamic>> newElements;
  final Function(List<Map<String, dynamic>>) addElements;
  final Function(List<String>) removeElements;

  @override
  final String description = '粘贴元素';

  PasteElementOperation({
    required this.newElements,
    required this.addElements,
    required this.removeElements,
  });

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行粘贴元素操作',
      data: {
        'elementCount': newElements.length,
        'elementIds': newElements.map((e) => e['id']).toList(),
        'elementTypes': newElements.map((e) => e['type']).toList(),
        'operation': 'paste_elements_execute',
      },
    );
    addElements(newElements);
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销粘贴元素操作',
      data: {
        'elementCount': newElements.length,
        'operation': 'paste_elements_undo',
      },
    );
    final elementIds = newElements.map((e) => e['id'] as String).toList();
    removeElements(elementIds);
  }
}

/// 删除所有图层操作
class DeleteAllLayersOperation implements UndoableOperation {
  final List<Map<String, dynamic>> layers;
  final String? selectedLayerId;
  final Function() deleteLayers;
  final Function(List<Map<String, dynamic>>, String?) restoreLayers;

  @override
  final String description = '删除所有图层';

  DeleteAllLayersOperation({
    required this.layers,
    required this.selectedLayerId,
    required this.deleteLayers,
    required this.restoreLayers,
  });

  @override
  void execute() {
    deleteLayers();
  }

  @override
  void undo() {
    restoreLayers(layers, selectedLayerId);
  }
}

/// 删除页面操作
class DeletePageOperation implements UndoableOperation {
  final Map<String, dynamic> page;
  final int pageIndex;
  final bool wasCurrentPage;
  final int oldCurrentPageIndex;
  final Function(Map<String, dynamic>, int) addPage;
  final Function(int) removePage;
  final Function(int) setCurrentPageIndex;

  @override
  final String description = '删除页面';

  DeletePageOperation({
    required this.page,
    required this.pageIndex,
    required this.wasCurrentPage,
    required this.oldCurrentPageIndex,
    required this.addPage,
    required this.removePage,
    required this.setCurrentPageIndex,
  });

  @override
  void execute() {
    EditPageLogger.controllerInfo(
      '执行删除页面操作',
      data: {
        'pageId': page['id'],
        'pageIndex': pageIndex,
        'wasCurrentPage': wasCurrentPage,
        'pageName': page['name'],
        'operation': 'delete_page_execute',
      },
    );
    removePage(pageIndex);
  }

  @override
  void undo() {
    EditPageLogger.controllerInfo(
      '撤销删除页面操作',
      data: {
        'pageId': page['id'],
        'pageIndex': pageIndex,
        'restoredAsCurrentPage': wasCurrentPage,
        'operation': 'delete_page_undo',
      },
    );
    addPage(page, pageIndex);
    if (wasCurrentPage) {
      setCurrentPageIndex(oldCurrentPageIndex);
    }
  }
} 