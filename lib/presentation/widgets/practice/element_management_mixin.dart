import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'batch_update_options.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 元素管理混入类 - 负责元素的增删改查操作
mixin ElementManagementMixin on ChangeNotifier {
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  Uuid get uuid;

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
      'name': '集字元素',
      'content': {
        'characters': characters,
        'fontSize': 24.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'gridLines': false,
        'showBackground': true,
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
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': '集字元素',
      'isFromCharacterManagement': isFromCharacterManagement,
      'content': {
        'characters': characters,
        'fontSize': isFromCharacterManagement ? 200.0 : 24.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'gridLines': false,
        'showBackground': true,
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
      'name': '集字元素',
      'content': {
        'characters': '',
        'fontSize': 24.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'direction': 'horizontal',
        'charSpacing': 10.0,
        'lineSpacing': 10.0,
        'gridLines': false,
        'showBackground': true,
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
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': '图片元素',
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
      'name': '图片元素',
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
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': '图片元素',
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
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'name': '文本元素',
      'content': {
        'text': '属性面板编辑文本',
        'fontSize': 24.0,
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
      'type': 'text',
      'x': x,
      'y': y,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'layerId': _getValidLayerId(),
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '文本元素', // 默认名称
      'content': {
        'text': '属性面板编辑文本',
        'fontFamily': 'sans-serif',
        'fontSize': 24.0,
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
      debugPrint('【元素管理】batchUpdateElementProperties: 当前页面索引无效，无法批量更新元素属性');
      return;
    }

    final batchOptions = options ?? const BatchUpdateOptions();
    _executeBatchUpdate(batchUpdates, batchOptions);
  }

  void checkDisposed();

  /// 清除选择
  void clearSelection() {
    state.selectedElementIds.clear();
    state.selectedElement = null;
    state.selectedLayerId =
        null; // 🔧 Also clear layer selection to properly switch to page properties
    notifyListeners();
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

      debugPrint('【Undo/Redo】删除元素: $id, 类型: ${element['type']}');

      // 创建删除操作
      final operation = DeleteElementOperation(
        element: element,
        addElement: (e) {
          debugPrint('【Undo/Redo】撤销删除 - 恢复元素: ${e['id']}');
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
            notifyListeners();
          }
        },
        removeElement: (elementId) {
          debugPrint('【Undo/Redo】执行删除元素: $elementId');
          if (state.currentPageIndex >= 0 &&
              state.currentPageIndex < state.pages.length) {
            final page = state.pages[state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['id'] == elementId);

            // 如果删除的是当前选中的元素，清除选择
            if (state.selectedElementIds.contains(elementId)) {
              state.selectedElementIds.remove(elementId);
              if (state.selectedElementIds.isEmpty) {
                state.selectedElement = null;
              }
            }

            state.hasUnsavedChanges = true;
            notifyListeners();
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

    for (final id in state.selectedElementIds) {
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
                notifyListeners();
              }
            },
            removeElement: (id) {
              if (state.currentPageIndex >= 0 &&
                  state.currentPageIndex < state.pages.length) {
                final page = state.pages[state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                elements.removeWhere((e) => e['id'] == id);
                state.hasUnsavedChanges = true;
                notifyListeners();
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

      state.selectedElementIds.clear();
      state.selectedElement = null;

      undoRedoManager.addOperation(batchOperation);
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
        notifyListeners();
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

      notifyListeners();
    }
  }

  /// 选择多个元素
  void selectElements(List<String> ids) {
    if (ids.isEmpty) {
      clearSelection();
      return;
    }

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

    notifyListeners();
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

          // 不修改hasUnsavedChanges，因为这是临时状态
          notifyListeners();
        }
      }
      return;
    }

    // 非交互式（最终）更新，使用正常的属性更新和撤销/重做
    updateElementProperty(id, 'opacity', opacity);
  }

  /// 更新元素属性
  void updateElementProperties(String id, Map<String, dynamic> properties) {
    if (state.currentPageIndex >= state.pages.length) {
      debugPrint('【控制器】updateElementProperties: 当前页面索引无效，无法更新元素属性');
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
            if (state.currentPageIndex >= 0 &&
                state.currentPageIndex < state.pages.length) {
              final page = state.pages[state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;
              final elementIndex =
                  elements.indexWhere((e) => e['id'] == elementId);

              if (elementIndex >= 0) {
                final element = elements[elementIndex] as Map<String, dynamic>;
                positionProps.forEach((key, value) {
                  element[key] = value;
                });

                // 如果是当前选中的元素，更新selectedElement
                if (state.selectedElementIds.contains(elementId)) {
                  state.selectedElement = element;
                }

                state.hasUnsavedChanges = true;
                notifyListeners();
              }
            }
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

                // 如果是当前选中的元素，更新selectedElement
                if (state.selectedElementIds.contains(id)) {
                  state.selectedElement = props;
                }

                state.hasUnsavedChanges = true;
                notifyListeners();
              }
            }
          },
        );
      }

      undoRedoManager.addOperation(operation);
    }
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
      notifyListeners();
    }
  }

  /// 添加元素的通用方法
  void _addElement(Map<String, dynamic> element) {
    debugPrint('🚀 ElementManagement: Adding element to page');
    debugPrint('🚀 ElementManagement: Element ID: ${element['id']}');
    debugPrint('🚀 ElementManagement: Element type: ${element['type']}');
    debugPrint(
        '🚀 ElementManagement: Current page index: ${state.currentPageIndex}');

    final operation = AddElementOperation(
        element: element,
        addElement: (e) {
          debugPrint('🚀 ElementManagement: Executing add element operation');
          if (state.currentPageIndex >= 0 &&
              state.currentPageIndex < state.pages.length) {
            final page = state.pages[state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.add(e);

            debugPrint(
                '🚀 ElementManagement: Element added to page. Total elements now: ${elements.length}');

            // 选中新添加的元素并清除图层选择
            state.selectedElementIds = [e['id'] as String];
            state.selectedElement = e;
            state.selectedLayerId = null; // 🔧 清除图层选择，确保显示元素属性
            state.hasUnsavedChanges = true;

            debugPrint(
                '🚀 ElementManagement: Element selected and notifying listeners');
            notifyListeners();
          } else {
            debugPrint('🚀 ElementManagement: ERROR - Invalid page index');
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
            notifyListeners();
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
                }
              }
            },
          ));
        }

        final batchOperation = BatchOperation(
          operations: operations,
          operationDescription: '批量更新${updatedElementIds.length}个元素',
        );

        undoRedoManager.addOperation(batchOperation);
      }

      state.hasUnsavedChanges = true;
      notifyListeners();
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
    }

    // 如果没有图层，创建一个默认图层
    final defaultLayer = {
      'id': 'layer_${uuid.v4()}',
      'name': '默认图层',
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
