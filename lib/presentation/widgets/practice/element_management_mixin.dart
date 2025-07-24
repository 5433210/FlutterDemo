import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'batch_update_options.dart';
import 'intelligent_notification_mixin.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 元素管理混入类 - 负责元素的增删改查操作
mixin ElementManagementMixin on ChangeNotifier
    implements IntelligentNotificationMixin {
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  Uuid get uuid;

  /// 获取本地化实例 - 需要由实现类提供
  AppLocalizations? get l10n;
  set l10n(AppLocalizations? value);

  /// 添加集字元素
  void addCollectionElement(String characters) {
    checkDisposed();
    final element = {
      'id': 'collection_${uuid.v4()}',
      'type': 'collection',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.collectionElement,
      'content': {
        'characters': characters,
        'fontSize': 200.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'padding': 0.0,
        'gridLines': false,
        'showBackground': true,
        'textureFillMode': 'stretch',
        'textureFitMode': 'fill',
      },
    };

    _addElement(element);
  }

  /// 添加集字元素在指定位置
  String addCollectionElementAt(double x, double y, String characters,
      {bool isFromCharacterManagement = false,
      Map<String, dynamic>? elementFromCharacterManagement}) {
    if (isFromCharacterManagement) {
      elementFromCharacterManagement!['x'] = x;
      elementFromCharacterManagement['y'] = y;
      _addElement(elementFromCharacterManagement);
      return elementFromCharacterManagement['id'] as String;
    }
    final elementId = 'collection_${uuid.v4()}';
    final element = {
      'id': elementId,
      'type': 'collection',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.collectionElement,
      'isFromCharacterManagement': isFromCharacterManagement,
      'content': {
        'characters': characters,
        'fontSize': isFromCharacterManagement ? 200.0 : 50.0,
        'fontColor': '#000000',
        'backgroundColor': 'transparent',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'padding': 0.0,
        'gridLines': false,
        'showBackground': true,
        'textureFillMode': 'stretch',
        'textureFitMode': 'fill',
      },
    };

    _addElement(element);
    return elementId;
  }

  /// 添加空集字元素在指定位置（不显示对话框）
  String addEmptyCollectionElementAt(double x, double y) {
    final elementId = 'collection_${uuid.v4()}';
    final element = {
      'id': elementId,
      'type': 'collection',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.collectionElement,
      'content': {
        'characters': '',
        'fontSize': 50.0,
        'fontColor': '#000000',
        'backgroundColor': 'transparent',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'padding': 0.0,
        'gridLines': false,
        'showBackground': true,
        'textureFillMode': 'stretch',
        'textureFitMode': 'fill',
      },
    };

    _addElement(element);
    return elementId;
  }

  /// 添加空图片元素在指定位置（不显示对话框）
  String addEmptyImageElementAt(double x, double y) {
    final elementId = 'image_${uuid.v4()}';
    final element = {
      'id': elementId,
      'type': 'image',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.imageElement,
      'content': {
        'imageUrl': '',
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    _addElement(element);
    return elementId;
  }

  /// 添加图片元素
  void addImageElement(String imageUrl) {
    final element = {
      'id': 'image_${uuid.v4()}',
      'type': 'image',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.imageElement,
      'content': {
        'imageUrl': imageUrl,
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    _addElement(element);
  }

  /// 添加图片元素在指定位置
  String addImageElementAt(double x, double y, String imageUrl) {
    final elementId = 'image_${uuid.v4()}';
    final element = {
      'id': elementId,
      'type': 'image',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.imageElement,
      'content': {
        'imageUrl': imageUrl,
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    _addElement(element);
    return elementId;
  }

  /// 添加文本元素
  void addTextElement() {
    final element = {
      'id': 'text_${uuid.v4()}',
      'type': 'text',
      'x': 100.0,
      'y': 100.0,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': l10n!.textElement,
      'content': {
        'text': l10n!.defaultEditableText,
        'fontSize': 35.0,
        'fontColor': '#000000',
        'backgroundColor': 'transparent',
        'textAlign': 'left',
        'fontWeight': 'normal',
        'fontStyle': 'normal',
      },
    };

    _addElement(element);
  }

  /// 添加文本元素在指定位置
  String addTextElementAt(double x, double y) {
    final elementId = 'text_${uuid.v4()}';
    final element = {
      'id': elementId,
      'type': 'text', 'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0, 'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': l10n!.textElement, // 默认名称
      'content': {
        'text': l10n!.defaultEditableText, 'fontFamily': 'sans-serif',
        'fontSize': 35.0,
        'fontColor': '#000000', // 修改为fontColor以匹配渲染器
        'backgroundColor': '#FFFFFF',
        'textAlign': 'left', // 修改为textAlign以匹配渲染器
        'verticalAlign': 'top', // 添加垂直对齐属性
        'writingMode': 'horizontal-l', // 添加书写模式属性
        'lineHeight': 1.2,
        'letterSpacing': 0.0,
        'padding': 8.0, // 添加内边距属性
        'fontWeight': 'normal', // 添加字重属性
        'fontStyle': 'normal', // 添加字体样式属性
      },
    };

    _addElement(element);
    return elementId;
  }

  /// 批量更新多个元素的属性
  void batchUpdateElementProperties(
    Map<String, Map<String, dynamic>> batchUpdates, {
    BatchUpdateOptions? options,
  }) {
    if (batchUpdates.isEmpty) return;

    if (state.currentPageIndex >= state.pages.length) {
      EditPageLogger.controllerWarning('当前页面索引无效，无法批量更新元素属性');
      return;
    }

    final batchOptions = options ?? const BatchUpdateOptions();
    _executeBatchUpdate(batchUpdates, batchOptions);
  }

  @override
  void checkDisposed();

  /// 清除选择
  void clearSelection() {
    final previousIds = List<String>.from(state.selectedElementIds);
    state.selectedElementIds.clear();
    state.selectedElement = null;
    state.selectedLayerId =
        null; // 🔧 Also clear layer selection to properly switch to page properties

    // 🚀 使用智能状态分发器通知选择清除
    intelligentNotify(
      changeType: 'selection_change',
      eventData: {
        'selectedIds': <String>[],
        'previousIds': previousIds,
        'selectionCount': 0,
        'operation': 'clear_selection',
      },
      operation: 'clear_selection',
      affectedLayers: ['interaction'],
      affectedUIComponents: ['property_panel', 'toolbar'],
    );
  }

  /// 删除元素
  void deleteElement(String id) {
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final page = state.pages[state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;

      // 查找要删除的元素
      final elementIndex = elements.indexWhere((e) => e['id'] == id);
      if (elementIndex < 0) return; // 元素不存在

      final element = Map<String, dynamic>.from(elements[elementIndex]);

      EditPageLogger.controllerInfo('删除元素: $id, 类型: ${element['type']}');

      // 创建删除操作
      final operation = DeleteElementOperation(
        element: element,
        addElement: (e) {
          EditPageLogger.controllerDebug('【Undo/Redo】撤销删除 - 恢复元素: ${e['id']}');
          if (state.currentPageIndex >= 0 &&
              state.currentPageIndex < state.pages.length) {
            final page = state.pages[state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;

            // 在原来的位置插入元素
            if (elementIndex < elements.length) {
              elements.insert(elementIndex, e);
            } else {
              elements.add(e);
            }

            state.hasUnsavedChanges = true;

            // 🚀 使用智能状态分发器替代直接的notifyListeners
            intelligentNotify(
              changeType: 'element_restore',
              eventData: {
                'elementId': e['id'],
                'elementType': e['type'],
                'elementCount': elements.length,
                'operation': 'restore_element_undo',
                'timestamp': DateTime.now().toIso8601String(),
              },
              operation: 'restore_element',
              affectedElements: [e['id'] as String],
              affectedLayers: ['content', 'interaction'],
              affectedUIComponents: [
                'canvas',
                'property_panel',
                'element_list'
              ],
            );
          }
        },
        removeElement: (elementId) {
          EditPageLogger.controllerDebug('【Undo/Redo】执行删除元素: $elementId');
          if (state.currentPageIndex >= 0 &&
              state.currentPageIndex < state.pages.length) {
            final page = state.pages[state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['id'] == elementId);

            // 如果删除的是当前选中的元素，清除选择
            final wasSelected = state.selectedElementIds.contains(elementId);
            if (wasSelected) {
              state.selectedElementIds.remove(elementId);
              if (state.selectedElementIds.isEmpty) {
                state.selectedElement = null;
              }
            }

            state.hasUnsavedChanges = true;

            // 🚀 使用智能状态分发器替代直接的notifyListeners
            intelligentNotify(
              changeType: 'element_delete',
              eventData: {
                'elementId': elementId,
                'elementCount': elements.length,
                'wasSelected': wasSelected,
                'operation': 'delete_element_execute',
                'timestamp': DateTime.now().toIso8601String(),
              },
              operation: 'delete_element',
              affectedElements: [elementId],
              affectedLayers: ['content', 'interaction'],
              affectedUIComponents: [
                'canvas',
                'property_panel',
                'element_list'
              ],
            );
          }
        },
      );

      undoRedoManager.addOperation(operation);
    }
  }

  /// 删除选中的元素
  void deleteSelectedElements() {
    if (state.selectedElementIds.isEmpty) return;

    final operations = <UndoableOperation>[];
    final deletingElementIds = List<String>.from(state.selectedElementIds);

    for (final id in deletingElementIds) {
      if (state.currentPageIndex >= 0 &&
          state.currentPageIndex < state.pages.length) {
        final page = state.pages[state.currentPageIndex];
        final elements = page['elements'] as List<dynamic>;
        final elementIndex = elements.indexWhere((e) => e['id'] == id);

        if (elementIndex >= 0) {
          final element = elements[elementIndex];

          final operation = DeleteElementOperation(
            element: Map<String, dynamic>.from(element as Map<String, dynamic>),
            addElement: (e) {
              if (state.currentPageIndex >= 0 &&
                  state.currentPageIndex < state.pages.length) {
                final page = state.pages[state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                elements.add(e);
                state.hasUnsavedChanges = true;

                // 🚀 使用智能状态分发器替代直接的notifyListeners
                intelligentNotify(
                  changeType: 'element_restore_batch',
                  eventData: {
                    'elementId': e['id'],
                    'elementType': e['type'],
                    'elementCount': elements.length,
                    'operation': 'restore_element_batch_undo',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                  operation: 'restore_element_batch',
                  affectedElements: [e['id'] as String],
                  affectedLayers: ['content', 'interaction'],
                  affectedUIComponents: [
                    'canvas',
                    'property_panel',
                    'element_list'
                  ],
                );
              }
            },
            removeElement: (id) {
              if (state.currentPageIndex >= 0 &&
                  state.currentPageIndex < state.pages.length) {
                final page = state.pages[state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                elements.removeWhere((e) => e['id'] == id);
                state.hasUnsavedChanges = true;

                // 🚀 使用智能状态分发器替代直接的notifyListeners
                intelligentNotify(
                  changeType: 'element_delete_batch',
                  eventData: {
                    'elementId': id,
                    'elementCount': elements.length,
                    'operation': 'delete_element_batch_execute',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                  operation: 'delete_element_batch',
                  affectedElements: [id],
                  affectedLayers: ['content', 'interaction'],
                  affectedUIComponents: [
                    'canvas',
                    'property_panel',
                    'element_list'
                  ],
                );
              }
            },
          );

          operations.add(operation);
        }
      }
    }

    if (operations.isNotEmpty) {
      final batchOperation = BatchOperation(
        operations: operations,
        operationDescription: '删除${operations.length}个元素',
      );

      // 清除选择状态
      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.hasUnsavedChanges = true;

      undoRedoManager.addOperation(batchOperation);

      // 🚀 使用智能状态分发器通知批量删除完成
      intelligentNotify(
        changeType: 'element_delete_selected',
        eventData: {
          'deletedElementIds': deletingElementIds,
          'deletedCount': operations.length,
          'operation': 'delete_selected_elements',
          'timestamp': DateTime.now().toIso8601String(),
        },
        operation: 'delete_selected_elements',
        affectedElements: deletingElementIds,
        affectedLayers: ['content', 'interaction'],
        affectedUIComponents: ['canvas', 'property_panel', 'element_list'],
      );
    }
  }

  void markUnsaved();

  /// 重新排序元素（用于层次操作）
  void reorderElement(String elementId, int oldIndex, int newIndex) {
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final page = state.pages[state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;

      if (oldIndex >= 0 &&
          oldIndex < elements.length &&
          newIndex >= 0 &&
          newIndex < elements.length &&
          oldIndex != newIndex) {
        final element = elements.removeAt(oldIndex);
        elements.insert(newIndex, element);

        state.hasUnsavedChanges = true;

        // 🚀 使用智能通知替代直接notifyListeners（元素顺序调整）
        intelligentNotify(
          changeType: 'element_order_update',
          eventData: {
            'elementId': elements[newIndex]['id'],
            'oldIndex': oldIndex,
            'newIndex': newIndex,
            'operation': 'move_element_order',
            'timestamp': DateTime.now().toIso8601String(),
          },
          operation: 'move_element_order',
          affectedLayers: ['content'],
          affectedUIComponents: ['canvas', 'element_list'],
        );
      }
    }
  }

  /// 选择元素
  void selectElement(String id, {bool isMultiSelect = false}) {
    if (state.currentPageIndex < 0 ||
        state.currentPageIndex >= state.pages.length) {
      return;
    }

    final page = state.pages[state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      // 🔧 清除图层选择，确保显示元素属性面板
      state.selectedLayerId = null;

      if (isMultiSelect) {
        // 多选模式 - 切换选择状态
        if (state.selectedElementIds.contains(id)) {
          state.selectedElementIds.remove(id);
        } else {
          state.selectedElementIds.add(id);
        }

        // 更新selectedElement
        if (state.selectedElementIds.length == 1) {
          final selectedId = state.selectedElementIds.first;
          final selectedIndex =
              elements.indexWhere((e) => e['id'] == selectedId);
          if (selectedIndex >= 0) {
            state.selectedElement =
                elements[selectedIndex] as Map<String, dynamic>;
          }
        } else {
          state.selectedElement = null; // 多选时不显示单个元素的属性
        }
      } else {
        // 单选模式 - 仅选择当前元素
        state.selectedElementIds = [id];
        state.selectedElement = elements[elementIndex] as Map<String, dynamic>;
      }

      // 🚀 使用智能状态分发器通知选择变化
      intelligentNotify(
        changeType: 'selection_change',
        eventData: {
          'selectedIds': state.selectedElementIds,
          'selectionCount': state.selectedElementIds.length,
          'elementId': id,
          'isMultiSelect': isMultiSelect,
          'operation': 'select_element',
        },
        operation: 'select_element',
        affectedElements: [id],
        affectedLayers: ['interaction'],
        affectedUIComponents: ['property_panel', 'toolbar'],
      );
    }
  }

  /// 选择多个元素
  void selectElements(List<String> ids) {
    if (ids.isEmpty) {
      clearSelection();
      return;
    }

    final previousIds = List<String>.from(state.selectedElementIds);
    state.selectedElementIds = ids;

    // 如果只选中了一个元素，设置selectedElement
    if (ids.length == 1) {
      state.selectedElement = state.currentPageElements.firstWhere(
        (e) => e['id'] == ids.first,
        orElse: () => {},
      );
    } else {
      state.selectedElement = null;
    }

    // 🚀 使用智能状态分发器通知选择变化
    intelligentNotify(
      changeType: 'selection_change',
      eventData: {
        'selectedIds': ids,
        'previousIds': previousIds,
        'selectionCount': ids.length,
        'operation': 'select_elements',
      },
      operation: 'select_elements',
      affectedLayers: ['interaction'],
      affectedUIComponents: ['property_panel', 'toolbar'],
    );
  }

  /// 更新元素透明度
  void updateElementOpacity(String id, double opacity,
      {bool isInteractive = false}) {
    // 交互式操作（如滑动）时不记录撤销操作，只更新UI
    if (isInteractive) {
      if (state.currentPageIndex >= 0 &&
          state.currentPageIndex < state.pages.length) {
        final page = state.pages[state.currentPageIndex];
        final elements = page['elements'] as List<dynamic>;
        final elementIndex = elements.indexWhere((e) => e['id'] == id);

        if (elementIndex >= 0) {
          final element = elements[elementIndex] as Map<String, dynamic>;
          element['opacity'] = opacity;

          // 如果是当前选中的元素，更新selectedElement
          if (state.selectedElementIds.contains(id)) {
            state.selectedElement = element;
          }

          // 🚀 使用智能通知替代直接notifyListeners（交互式透明度更新）
          intelligentNotify(
            changeType: 'element_update',
            eventData: {
              'elementId': id,
              'property': 'opacity',
              'value': opacity,
              'isInteractive': true,
              'operation': 'update_element_opacity_interactive',
            },
            operation: 'update_element_opacity_interactive',
            affectedElements: [id],
            affectedLayers: ['content'],
            affectedUIComponents: ['property_panel'],
          );
        }
      }
      return;
    }

    // 非交互式（最终）更新，使用正常的属性更新和撤销/重做
    updateElementProperty(id, 'opacity', opacity);
  }

  /// 更新元素属性
  void updateElementProperties(String id, Map<String, dynamic> properties) {
    updateElementPropertiesInternal(id, properties, createUndoOperation: true);
  }

  /// 更新元素属性（内部方法，可控制是否创建撤销操作）
  void updateElementPropertiesInternal(
      String id, Map<String, dynamic> properties,
      {bool createUndoOperation = true}) {
    if (state.currentPageIndex >= state.pages.length) {
      EditPageLogger.controllerWarning('当前页面索引无效，无法更新元素属性');
      return;
    }

    final page = state.pages[state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      final element = elements[elementIndex] as Map<String, dynamic>;
      final oldProperties = Map<String, dynamic>.from(element);

      // 更新属性
      final newProperties = <String, dynamic>{...element};
      properties.forEach((key, value) {
        if (key == 'content' && element.containsKey('content')) {
          // 对于content对象，合并而不是替换
          newProperties['content'] = {
            ...(element['content'] as Map<String, dynamic>),
            ...(value as Map<String, dynamic>),
          };
        } else {
          newProperties[key] = value;
        }
      });

      // 直接更新元素数据
      elements[elementIndex] = newProperties;

      // 如果是当前选中的元素，更新selectedElement
      if (state.selectedElementIds.contains(id)) {
        state.selectedElement = newProperties;
      }

      state.hasUnsavedChanges = true;

      // 根据参数决定是否创建撤销操作
      if (createUndoOperation) {
        // 检查是否只是位置变化
        final isTranslationOnly =
            properties.keys.every((key) => key == 'x' || key == 'y');

        UndoableOperation operation;

        if (isTranslationOnly) {
          // 创建位置变化操作
          operation = ElementTranslationOperation(
            elementIds: [id],
            oldPositions: [
              {
                'x': oldProperties['x'],
                'y': oldProperties['y'],
              }
            ],
            newPositions: [
              {
                'x': newProperties['x'],
                'y': newProperties['y'],
              }
            ],
            updateElement: (elementId, positionProps) {
              updateElementPropertiesInternal(elementId, positionProps,
                  createUndoOperation: false);
            },
          );
        } else {
          // 创建通用属性变化操作
          operation = ElementPropertyOperation(
            elementId: id,
            oldProperties: oldProperties,
            newProperties: newProperties,
            updateElement: (id, props) {
              if (state.currentPageIndex >= 0 &&
                  state.currentPageIndex < state.pages.length) {
                final page = state.pages[state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                final elementIndex = elements.indexWhere((e) => e['id'] == id);

                if (elementIndex >= 0) {
                  elements[elementIndex] = props;

                  if (state.selectedElementIds.contains(id)) {
                    state.selectedElement = props;
                  }

                  state.hasUnsavedChanges = true;

                  // 🚀 使用智能通知替代直接notifyListeners（撤销操作中的元素属性更新）
                  intelligentNotify(
                    changeType: 'element_undo_redo',
                    eventData: {
                      'elementId': id,
                      'operation': 'element_property_undo_redo',
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                    operation: 'element_property_undo_redo',
                    affectedElements: [id],
                    affectedLayers: ['content'],
                    affectedUIComponents: ['property_panel'],
                  );
                }
              }
            },
          );
        }

        undoRedoManager.addOperation(operation, executeImmediately: false);
      }

      // 🚀 使用智能状态分发器通知元素属性变化
      intelligentNotify(
        changeType: 'element_update',
        eventData: {
          'elementId': id,
          'properties': properties.keys.toList(),
          'operation': 'update_element_properties',
          'hasUndoOperation': createUndoOperation,
        },
        operation: 'update_element_properties',
        affectedElements: [id],
        affectedLayers: ['content'],
        affectedUIComponents: ['property_panel'],
      );
    }
  }

  /// 更新元素属性（不创建撤销操作）- 供其他撤销操作处理器使用
  void updateElementPropertiesWithoutUndo(
      String id, Map<String, dynamic> properties) {
    updateElementPropertiesInternal(id, properties, createUndoOperation: false);
  }

  /// 更新单个元素属性
  void updateElementProperty(String id, String property, dynamic value) {
    updateElementProperties(id, {property: value});
  }

  /// 更新元素顺序
  void updateElementsOrder() {
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      state.hasUnsavedChanges = true;

      // 🚀 使用智能状态分发器替代直接的notifyListeners
      intelligentNotify(
        changeType: 'element_order_update',
        eventData: {
          'operation': 'update_elements_order',
          'pageIndex': state.currentPageIndex,
          'timestamp': DateTime.now().toIso8601String(),
        },
        operation: 'update_elements_order',
        affectedLayers: ['content'],
        affectedUIComponents: ['canvas', 'element_list'],
      );
    }
  }

  /// 更新参考线管理器元素数据 - 由实现类提供
  void updateGuidelineManagerElements();

  /// 添加元素的通用方法
  void _addElement(Map<String, dynamic> element) {
    EditPageLogger.controllerDebug(
      '添加元素到页面',
      data: {
        'elementId': element['id'],
        'elementType': element['type'],
        'currentPageIndex': state.currentPageIndex,
      },
    );

    final operation = AddElementOperation(
        element: element,
        addElement: (e) {
          EditPageLogger.controllerDebug('执行添加元素操作');
          if (state.currentPageIndex >= 0 &&
              state.currentPageIndex < state.pages.length) {
            final page = state.pages[state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.add(e);

            EditPageLogger.controllerDebug(
                '🚀 ElementManagement: Element added to page. Total elements now: ${elements.length}');

            // 选中新添加的元素并清除图层选择
            state.selectedElementIds = [e['id'] as String];
            state.selectedElement = e;
            state.selectedLayerId = null; // 🔧 清除图层选择，确保显示元素属性
            state.hasUnsavedChanges = true;

            EditPageLogger.controllerDebug(
                '🚀 ElementManagement: Element selected and triggering intelligent notification');

            // 🚀 使用智能状态分发器替代直接的notifyListeners
            intelligentNotify(
              changeType: 'element_add',
              eventData: {
                'elementId': e['id'],
                'elementType': e['type'],
                'elementCount': elements.length,
                'isSelected': true,
                'operation': 'add_element',
                'timestamp': DateTime.now().toIso8601String(),
              },
              operation: 'add_element',
              affectedElements: [e['id'] as String],
              affectedLayers: ['content', 'interaction'],
              affectedUIComponents: [
                'canvas',
                'property_panel',
                'element_list'
              ],
            );

            // 🔧 新增：更新参考线管理器的元素数据
            updateGuidelineManagerElements();
          } else {
            EditPageLogger.controllerError('无效的页面索引');
          }
        },
        removeElement: (id) {
          if (state.currentPageIndex >= 0 &&
              state.currentPageIndex < state.pages.length) {
            final page = state.pages[state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['id'] == id);

            // 如果删除的是当前选中的元素，清除选择
            if (state.selectedElementIds.contains(id)) {
              state.selectedElementIds.remove(id);
              if (state.selectedElementIds.isEmpty) {
                state.selectedElement = null;
              }
            }

            state.hasUnsavedChanges = true;

            // 🚀 使用智能状态分发器替代直接的notifyListeners
            intelligentNotify(
              changeType: 'element_remove',
              eventData: {
                'elementId': id,
                'remainingElementCount': elements.length,
                'wasSelected': state.selectedElementIds.isEmpty,
                'operation': 'remove_element_undo',
                'timestamp': DateTime.now().toIso8601String(),
              },
              operation: 'remove_element',
              affectedElements: [id],
              affectedLayers: ['content', 'interaction'],
              affectedUIComponents: [
                'canvas',
                'property_panel',
                'element_list'
              ],
            );

            // 🔧 新增：更新参考线管理器的元素数据
            updateGuidelineManagerElements();
          }
        });

    // Add the operation to the undo/redo manager
    undoRedoManager.addOperation(operation);
  }

  /// 执行批量更新
  void _executeBatchUpdate(Map<String, Map<String, dynamic>> batchUpdates,
      BatchUpdateOptions options) {
    if (state.currentPageIndex >= state.pages.length) return;

    final page = state.pages[state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;

    final oldProperties = <String, Map<String, dynamic>>{};
    final newProperties = <String, Map<String, dynamic>>{};
    final updatedElementIds = <String>{};

    for (final entry in batchUpdates.entries) {
      final elementId = entry.key;
      final updates = entry.value;

      final elementIndex = elements.indexWhere((e) => e['id'] == elementId);
      if (elementIndex >= 0) {
        final element = elements[elementIndex] as Map<String, dynamic>;
        final oldElement = Map<String, dynamic>.from(element);
        final newElement = Map<String, dynamic>.from(element);

        // 应用更新
        updates.forEach((key, value) {
          if (key == 'content' && element.containsKey('content')) {
            final content = newElement['content'] as Map<String, dynamic>;
            final updateContent = value as Map<String, dynamic>;
            updateContent.forEach((contentKey, contentValue) {
              content[contentKey] = contentValue;
            });
          } else {
            newElement[key] = value;
          }
        });

        oldProperties[elementId] = oldElement;
        elements[elementIndex] = newElement;
        newProperties[elementId] = newElement;
        updatedElementIds.add(elementId);

        if (state.selectedElementIds.contains(elementId)) {
          state.selectedElement = newElement;
        }
      }
    }

    if (updatedElementIds.isNotEmpty) {
      if (options.recordUndoOperation) {
        final operations = <UndoableOperation>[];

        for (final elementId in updatedElementIds) {
          final oldProps = oldProperties[elementId]!;
          final newProps = newProperties[elementId]!;

          operations.add(ElementPropertyOperation(
            elementId: elementId,
            oldProperties: oldProps,
            newProperties: newProps,
            updateElement: (id, props) {
              if (state.currentPageIndex >= 0 &&
                  state.currentPageIndex < state.pages.length) {
                final page = state.pages[state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                final elementIndex = elements.indexWhere((e) => e['id'] == id);

                if (elementIndex >= 0) {
                  elements[elementIndex] = props;

                  if (state.selectedElementIds.contains(id)) {
                    state.selectedElement = props;
                  }

                  state.hasUnsavedChanges = true;

                  // 🚀 使用智能通知替代直接notifyListeners（撤销操作中的元素属性更新）
                  intelligentNotify(
                    changeType: 'element_undo_redo',
                    eventData: {
                      'elementId': id,
                      'operation': 'element_property_undo_redo',
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                    operation: 'element_property_undo_redo',
                    affectedElements: [id],
                    affectedLayers: ['content'],
                    affectedUIComponents: ['property_panel'],
                  );
                }
              }
            },
          ));
        }

        final batchOperation = BatchOperation(
          operations: operations,
          operationDescription: '批量更新${updatedElementIds.length}个元素',
        );

        undoRedoManager.addOperation(batchOperation, executeImmediately: false);
      }

      state.hasUnsavedChanges = true;

      // 🚀 使用智能状态分发器替代直接的notifyListeners
      intelligentNotify(
        changeType: 'element_batch_update',
        eventData: {
          'elementIds': updatedElementIds.toList(),
          'elementCount': updatedElementIds.length,
          'operation': 'batch_update',
          'hasUndoOperation': options.recordUndoOperation,
          'timestamp': DateTime.now().toIso8601String(),
        },
        operation: 'batch_update',
        affectedElements: updatedElementIds.toList(),
        affectedLayers: ['content'],
        affectedUIComponents: ['property_panel', 'canvas'],
      );
    }
  }

  /// 获取有效的图层ID
  String _getValidLayerId() {
    // 首先检查selectedLayerId是否有效
    if (state.selectedLayerId != null) {
      final isValid =
          state.layers.any((layer) => layer['id'] == state.selectedLayerId);
      if (isValid) {
        return state.selectedLayerId!;
      }
    }

    // 如果selectedLayerId无效或为空，使用第一个可用图层
    if (state.layers.isNotEmpty) {
      final firstLayerId = state.layers.first['id'] as String;
      // 更新selectedLayerId为有效值
      state.selectedLayerId = firstLayerId;
      return firstLayerId;
    } // 如果没有图层，创建一个默认图层
    final defaultLayer = {
      'id': 'layer_${uuid.v4()}',
      'name': l10n!.defaultLayer,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 添加到当前页面的图层列表
    if (state.currentPage != null) {
      if (!state.currentPage!.containsKey('layers')) {
        state.currentPage!['layers'] = <Map<String, dynamic>>[];
      }
      final layers = state.currentPage!['layers'] as List<dynamic>;
      layers.add(defaultLayer);
    }

    final layerId = defaultLayer['id'] as String;
    state.selectedLayerId = layerId;
    return layerId;
  }
}
