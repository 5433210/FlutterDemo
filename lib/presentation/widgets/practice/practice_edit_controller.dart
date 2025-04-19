import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'practice_edit_state.dart';
import 'undo_redo_manager.dart';

/// 字帖编辑控制器
class PracticeEditController extends ChangeNotifier {
  // 状态
  final PracticeEditState _state = PracticeEditState();

  // 撤销/重做管理器
  late final UndoRedoManager _undoRedoManager;

  // UUID生成器
  final Uuid _uuid = const Uuid();

  /// 构造函数
  PracticeEditController() {
    _undoRedoManager = UndoRedoManager(
      onStateChanged: () {
        // 更新撤销/重做状态
        _state.canUndo = _undoRedoManager.canUndo;
        _state.canRedo = _undoRedoManager.canRedo;
        notifyListeners();
      },
    );

    // 初始化默认数据
    _initDefaultData();
  }

  /// 获取当前状态
  PracticeEditState get state => _state;

  /// 获取撤销/重做管理器
  UndoRedoManager get undoRedoManager => _undoRedoManager;

  /// 添加集字元素
  void addCollectionElement(String characters) {
    final element = {
      'id': 'collection_${_uuid.v4()}',
      'type': 'collection',
      'x': 100.0,
      'y': 100.0,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
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
  void addCollectionElementAt(double x, double y, String characters) {
    final element = {
      'id': 'collection_${_uuid.v4()}',
      'type': 'collection',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
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

  /// 添加空集字元素在指定位置（不显示对话框）
  void addEmptyCollectionElementAt(double x, double y) {
    final element = {
      'id': 'collection_${_uuid.v4()}',
      'type': 'collection',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
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
  }

  /// 添加空图片元素在指定位置（不显示对话框）
  void addEmptyImageElementAt(double x, double y) {
    final element = {
      'id': 'image_${_uuid.v4()}',
      'type': 'image',
      'x': x,
      'y': y,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
      'content': {
        'imageUrl': '',
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    _addElement(element);
  }

  /// 添加图片元素
  void addImageElement(String imageUrl) {
    final element = {
      'id': 'image_${_uuid.v4()}',
      'type': 'image',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
      'content': {
        'imageUrl': imageUrl,
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    _addElement(element);
  }

  /// 添加图片元素在指定位置
  void addImageElementAt(double x, double y, String imageUrl) {
    final element = {
      'id': 'image_${_uuid.v4()}',
      'type': 'image',
      'x': x,
      'y': y,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
      'content': {
        'imageUrl': imageUrl,
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    _addElement(element);
  }

  /// 添加图层
  void addLayer() {
    final layerIndex = _state.layers.length;
    final layer = {
      'id': _uuid.v4(),
      'name': '图层${layerIndex + 1}',
      'order': layerIndex,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    final operation = AddLayerOperation(
      layer: layer,
      addLayer: (l) {
        _state.layers.add(l);
        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
      removeLayer: (id) {
        final index = _state.layers.indexWhere((l) => l['id'] == id);
        if (index >= 0) {
          _state.layers.removeAt(index);
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 添加新图层
  void addNewLayer() {
    // 创建新图层
    final newLayer = {
      'id': _uuid.v4(),
      'name': '图层${_state.layers.length + 1}',
      'order': _state.layers.length,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 添加到图层列表
    _state.layers.add(newLayer);
    _state.hasUnsavedChanges = true;

    notifyListeners();
  }

  void addNewPage() {
    if (_state.pages.isNotEmpty) {
      // Create a new page with default properties
      final newPage = {
        'id': 'page_${DateTime.now().millisecondsSinceEpoch}',
        'name': '页面${_state.pages.length + 1}',
        'width': 595.0, // A4纸宽度
        'height': 842.0, // A4纸高度
        'backgroundColor': '#FFFFFF',
        'backgroundOpacity': 1.0,
        'elements': <Map<String, dynamic>>[],
      };

      final operation = AddPageOperation(
        page: newPage,
        addPage: (p) {
          _state.pages.add(p);
          _state.currentPageIndex = _state.pages.length - 1;
          // Clear element and layer selections to show page properties
          _state.selectedElementIds.clear();
          _state.selectedElement = null;
          _state.selectedLayerId = null;
          _state.hasUnsavedChanges = true;
          notifyListeners();
        },
        removePage: (id) {
          final index = _state.pages.indexWhere((p) => p['id'] == id);
          if (index >= 0) {
            _state.pages.removeAt(index);
            if (_state.currentPageIndex >= _state.pages.length) {
              _state.currentPageIndex =
                  _state.pages.isEmpty ? -1 : _state.pages.length - 1;
            }
            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        },
      );

      _undoRedoManager.addOperation(operation);
    }
  }

  /// 添加页面
  void addPage() {
    final pageIndex = _state.pages.length;
    final page = {
      'id': _uuid.v4(),
      'name': '页面${pageIndex + 1}',
      'index': pageIndex,
      'width': 595.0, // A4纸宽度
      'height': 842.0, // A4纸高度
      'backgroundColor': '#FFFFFF',
      'backgroundOpacity': 1.0,
      'elements': <Map<String, dynamic>>[],
    };

    final operation = AddPageOperation(
      page: page,
      addPage: (p) {
        _state.pages.add(p);
        _state.currentPageIndex = _state.pages.length - 1;
        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
      removePage: (id) {
        final index = _state.pages.indexWhere((p) => p['id'] == id);
        if (index >= 0) {
          _state.pages.removeAt(index);
          if (_state.currentPageIndex >= _state.pages.length) {
            _state.currentPageIndex =
                _state.pages.isEmpty ? -1 : _state.pages.length - 1;
          }
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 添加文本元素
  void addTextElement() {
    final element = {
      'id': 'text_${_uuid.v4()}',
      'type': 'text',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
      'content': {
        'text': '双击编辑文本',
        'fontFamily': 'sans-serif',
        'fontSize': 24.0,
        'textColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'alignment': 'left',
        'lineHeight': 1.2,
        'letterSpacing': 0.0,
      },
    };

    _addElement(element);
  }

  /// 添加文本元素在指定位置
  void addTextElementAt(double x, double y) {
    final element = {
      'id': 'text_${_uuid.v4()}',
      'type': 'text',
      'x': x,
      'y': y,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'layerId': _state.layers.first['id'],
      'opacity': 1.0,
      'content': {
        'text': '双击编辑文本',
        'fontFamily': 'sans-serif',
        'fontSize': 24.0,
        'textColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'alignment': 'left',
        'lineHeight': 1.2,
        'letterSpacing': 0.0,
      },
    };

    _addElement(element);
  }

  /// 清除所有选择
  void clearSelection() {
    state.selectedElementIds.clear();
    state.selectedElement = null;
    notifyListeners();
  }

  /// 删除所有图层
  void deleteAllLayers() {
    if (_state.layers.length <= 1) return;

    // 创建默认图层
    final defaultLayer = {
      'id': _uuid.v4(),
      'name': '图层1',
      'order': 0,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 所有当前图层
    final oldLayers = List<Map<String, dynamic>>.from(_state.layers
        .map((l) => Map<String, dynamic>.from(l as Map<String, dynamic>)));

    // 查找所有元素
    final allElements = <Map<String, dynamic>>[];
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final page = _state.pages[_state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;

      for (final element in elements) {
        allElements
            .add(Map<String, dynamic>.from(element as Map<String, dynamic>));
      }
    }

    final operation = BatchOperation(
      operations: [
        // 自定义操作：删除所有图层并添加默认图层
        _createCustomOperation(
          execute: () {
            _state.layers.clear();
            _state.layers.add(defaultLayer);

            // 清空元素
            if (_state.currentPageIndex >= 0 &&
                _state.currentPageIndex < _state.pages.length) {
              final page = _state.pages[_state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;
              elements.clear();
            }

            // 清除选择
            _state.selectedElementIds.clear();
            _state.selectedElement = null;

            _state.hasUnsavedChanges = true;
            notifyListeners();
          },
          undo: () {
            _state.layers.clear();
            _state.layers.addAll(oldLayers);

            // 恢复元素
            if (_state.currentPageIndex >= 0 &&
                _state.currentPageIndex < _state.pages.length) {
              final page = _state.pages[_state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;
              elements.clear();
              elements.addAll(allElements);
            }

            _state.hasUnsavedChanges = true;
            notifyListeners();
          },
          description: '删除所有图层',
        ),
      ],
      operationDescription: '删除所有图层',
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 删除元素
  void deleteElement(String id) {
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final page = _state.pages[_state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;
      elements.removeWhere((e) => e['id'] == id);

      // 如果删除的是当前选中的元素，清除选择
      if (_state.selectedElementIds.contains(id)) {
        _state.selectedElementIds.remove(id);
        if (_state.selectedElementIds.isEmpty) {
          _state.selectedElement = null;
        }
      }

      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 删除图层
  void deleteLayer(String layerId) {
    final layerIndex = _state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;
    if (_state.layers.length <= 1) return; // 不允许删除最后一个图层

    final layer = _state.layers[layerIndex];

    // 查找该图层上的所有元素
    final elementsOnLayer = <Map<String, dynamic>>[];
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final page = _state.pages[_state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;

      for (final element in elements) {
        if (element['layerId'] == layerId) {
          elementsOnLayer
              .add(Map<String, dynamic>.from(element as Map<String, dynamic>));
        }
      }
    }

    final operation = DeleteLayerOperation(
      layer: Map<String, dynamic>.from(layer),
      layerIndex: layerIndex,
      elementsOnLayer: elementsOnLayer,
      insertLayer: (l, index) {
        _state.layers.insert(index, l);
        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
      removeLayer: (id) {
        final index = _state.layers.indexWhere((l) => l['id'] == id);
        if (index >= 0) {
          _state.layers.removeAt(index);

          // 删除图层上的所有元素
          if (_state.currentPageIndex >= 0 &&
              _state.currentPageIndex < _state.pages.length) {
            final page = _state.pages[_state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['layerId'] == id);

            // 清除相关选择
            _state.selectedElementIds.removeWhere((elementId) {
              final elementIndex =
                  elements.indexWhere((e) => e['id'] == elementId);
              return elementIndex < 0;
            });

            if (_state.selectedElementIds.isEmpty) {
              _state.selectedElement = null;
            }
          }

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      addElements: (elements) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final pageElements = page['elements'] as List<dynamic>;
          pageElements.addAll(elements);
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 删除页面
  void deletePage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _state.pages.length) return;
    if (_state.pages.length <= 1) return; // 不允许删除最后一个页面

    final page = _state.pages[pageIndex];

    final operation = DeletePageOperation(
      page: Map<String, dynamic>.from(page),
      pageIndex: pageIndex,
      insertPage: (p, index) {
        _state.pages.insert(index, p);
        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
      removePage: (id) {
        final index = _state.pages.indexWhere((p) => p['id'] == id);
        if (index >= 0) {
          _state.pages.removeAt(index);
          if (_state.currentPageIndex >= _state.pages.length) {
            _state.currentPageIndex =
                _state.pages.isEmpty ? -1 : _state.pages.length - 1;
          }
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 删除选中的元素
  void deleteSelectedElements() {
    if (_state.selectedElementIds.isEmpty) return;

    final operations = <UndoableOperation>[];

    for (final id in _state.selectedElementIds) {
      if (_state.currentPageIndex >= 0 &&
          _state.currentPageIndex < _state.pages.length) {
        final page = _state.pages[_state.currentPageIndex];
        final elements = page['elements'] as List<dynamic>;
        final elementIndex = elements.indexWhere((e) => e['id'] == id);

        if (elementIndex >= 0) {
          final element = elements[elementIndex];

          final operation = DeleteElementOperation(
            element: Map<String, dynamic>.from(element as Map<String, dynamic>),
            addElement: (e) {
              if (_state.currentPageIndex >= 0 &&
                  _state.currentPageIndex < _state.pages.length) {
                final page = _state.pages[_state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                elements.add(e);
                _state.hasUnsavedChanges = true;
                notifyListeners();
              }
            },
            removeElement: (id) {
              if (_state.currentPageIndex >= 0 &&
                  _state.currentPageIndex < _state.pages.length) {
                final page = _state.pages[_state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                elements.removeWhere((e) => e['id'] == id);
                _state.hasUnsavedChanges = true;
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

      _state.selectedElementIds.clear();
      _state.selectedElement = null;

      _undoRedoManager.addOperation(batchOperation);
    }
  }

  /// 组合选中的元素
  void groupSelectedElements() {
    if (_state.selectedElementIds.length <= 1) return;

    final page = _state.pages[_state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;

    // 收集要组合的元素
    final selectedElements = <Map<String, dynamic>>[];
    for (final id in _state.selectedElementIds) {
      final element = elements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => null,
      );
      if (element != null) {
        selectedElements
            .add(Map<String, dynamic>.from(element as Map<String, dynamic>));
      }
    }

    if (selectedElements.isEmpty) return;

    // 计算组合元素的边界
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final element in selectedElements) {
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x + width);
      maxY = math.max(maxY, y + height);
    }

    // 创建相对于组边界的子元素
    final groupChildren = selectedElements.map((e) {
      final x = (e['x'] as num).toDouble() - minX;
      final y = (e['y'] as num).toDouble() - minY;

      return {
        ...e,
        'x': x,
        'y': y,
      };
    }).toList();

    // 创建组合元素
    final groupElement = {
      'id': 'group_${_uuid.v4()}',
      'type': 'group',
      'x': minX,
      'y': minY,
      'width': maxX - minX,
      'height': maxY - minY,
      'rotation': 0.0,
      'layerId': selectedElements.first['layerId'],
      'opacity': 1.0,
      'content': {
        'children': groupChildren,
      },
    };

    final operation = GroupElementsOperation(
      elements: selectedElements,
      groupElement: groupElement,
      addElement: (e) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.add(e);

          // 选中新的组合元素
          _state.selectedElementIds = [e['id'] as String];
          _state.selectedElement = e;

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      removeElement: (id) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => e['id'] == id);

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      removeElements: (ids) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => ids.contains(e['id']));

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 重做操作
  void redo() {
    if (_undoRedoManager.canRedo) {
      _undoRedoManager.redo();
    }
  }

  /// 重命名图层
  void renameLayer(String layerId, String newName) {
    final layerIndex = _state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = _state.layers[layerIndex] as Map<String, dynamic>;
    final oldProperties = Map<String, dynamic>.from(layer);
    final newProperties =
        Map<String, dynamic>.from({...layer, 'name': newName});

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        final index = _state.layers.indexWhere((l) => l['id'] == id);
        if (index >= 0) {
          _state.layers[index] = props;
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 重新排序图层
  void reorderLayer(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _state.layers.length ||
        newIndex < 0 ||
        newIndex >= _state.layers.length) {
      return;
    }

    final layer = _state.layers.removeAt(oldIndex);
    _state.layers.insert(newIndex, layer);
    _state.hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _state.layers.length ||
        newIndex >= _state.layers.length) {
      return;
    }

    final operation = ReorderLayerOperation(
      oldIndex: oldIndex,
      newIndex: newIndex,
      reorderLayer: (oldIndex, newIndex) {
        final layer = _state.layers.removeAt(oldIndex);
        _state.layers.insert(newIndex, layer);

        // 更新order属性
        for (int i = 0; i < _state.layers.length; i++) {
          final layer = _state.layers[i] as Map<String, dynamic>;
          layer['order'] = i;
        }

        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 重新排序页面
  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _state.pages.length ||
        newIndex >= _state.pages.length) {
      return;
    }

    // 调整索引，处理ReorderableListView的特殊情况
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final operation = ReorderPageOperation(
      oldIndex: oldIndex,
      newIndex: newIndex,
      reorderPage: (oldIndex, newIndex) {
        final page = _state.pages.removeAt(oldIndex);
        _state.pages.insert(newIndex, page);

        // 更新所有页面的index属性
        for (int i = 0; i < _state.pages.length; i++) {
          final page = _state.pages[i];
          if (page.containsKey('index')) {
            page['index'] = i;
          }
        }

        // 更新currentPageIndex，如果当前选中页面被移动
        if (_state.currentPageIndex == oldIndex) {
          _state.currentPageIndex = newIndex;
        } else if (_state.currentPageIndex > oldIndex &&
            _state.currentPageIndex <= newIndex) {
          _state.currentPageIndex--;
        } else if (_state.currentPageIndex < oldIndex &&
            _state.currentPageIndex >= newIndex) {
          _state.currentPageIndex++;
        }

        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 选择元素
  void selectElement(String id, {bool isMultiSelect = false}) {
    if (_state.currentPageIndex < 0 ||
        _state.currentPageIndex >= _state.pages.length) {
      return;
    }

    final page = _state.pages[_state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      if (isMultiSelect) {
        // 多选模式 - 切换选择状态
        if (_state.selectedElementIds.contains(id)) {
          _state.selectedElementIds.remove(id);
        } else {
          _state.selectedElementIds.add(id);
        }

        // 更新selectedElement
        if (_state.selectedElementIds.length == 1) {
          final selectedId = _state.selectedElementIds.first;
          final selectedIndex =
              elements.indexWhere((e) => e['id'] == selectedId);
          if (selectedIndex >= 0) {
            _state.selectedElement =
                elements[selectedIndex] as Map<String, dynamic>;
          }
        } else {
          _state.selectedElement = null; // 多选时不显示单个元素的属性
        }
      } else {
        // 单选模式 - 仅选择当前元素
        _state.selectedElementIds = [id];
        _state.selectedElement = elements[elementIndex] as Map<String, dynamic>;
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

  /// 选择图层
  void selectLayer(String layerId) {
    // 实际上只是一个UI状态，不需要操作历史记录
    _state.selectedLayerId = layerId;
    notifyListeners();
  }

  /// 选择页面
  void selectPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _state.pages.length) {
      _state.currentPageIndex = pageIndex;
      // Clear element and layer selections to show page properties
      _state.selectedElementIds.clear();
      _state.selectedElement = null;
      _state.selectedLayerId = null;
      notifyListeners();
    }
  }

  // 设置当前页面
  void setCurrentPage(int index) {
    if (index >= 0 && index < state.pages.length) {
      state.currentPageIndex = index;
      // Clear element and layer selections to show page properties
      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.selectedLayerId = null;
      notifyListeners();
    }
  }

  /// 设置图层锁定状态
  void setLayerLocked(String layerId, bool isLocked) {
    final layerIndex = _state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = _state.layers[layerIndex] as Map<String, dynamic>;
    final oldProperties = Map<String, dynamic>.from(layer);
    final newProperties =
        Map<String, dynamic>.from({...layer, 'isLocked': isLocked});

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        final index = _state.layers.indexWhere((l) => l['id'] == id);
        if (index >= 0) {
          _state.layers[index] = props;
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 设置图层可见性
  void setLayerVisibility(String layerId, bool isVisible) {
    final layerIndex = _state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = _state.layers[layerIndex] as Map<String, dynamic>;
    final oldProperties = Map<String, dynamic>.from(layer);
    final newProperties =
        Map<String, dynamic>.from({...layer, 'isVisible': isVisible});

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        final index = _state.layers.indexWhere((l) => l['id'] == id);
        if (index >= 0) {
          _state.layers[index] = props;
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 显示所有图层
  void showAllLayers() {
    final operations = <UndoableOperation>[];

    for (final layer in _state.layers) {
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
              final index = _state.layers.indexWhere((l) => l['id'] == id);
              if (index >= 0) {
                _state.layers[index] = props;
                _state.hasUnsavedChanges = true;
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

      _undoRedoManager.addOperation(batchOperation);
    } else {
      // 如果没有需要修改的图层，直接通知UI刷新
      notifyListeners();
    }
  }

  /// Toggles the lock state of an element
  void toggleElementLock(String elementId) {
    // Implement the logic to toggle element lock state
    // For example:
    final currentPage = state.pages[state.currentPageIndex];
    final elements = List<Map<String, dynamic>>.from(currentPage['elements']);

    for (int i = 0; i < elements.length; i++) {
      if (elements[i]['id'] == elementId) {
        elements[i]['isLocked'] = !(elements[i]['isLocked'] ?? false);
        break;
      }
    }

    // Update the current page with modified elements
    final updatedPage = {...currentPage, 'elements': elements};
    _state.pages[_state.currentPageIndex] = updatedPage;
    _state.hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 切换网格显示
  void toggleGrid() {
    _state.gridVisible = !_state.gridVisible;
    notifyListeners();
  }

  /// 切换图层锁定状态
  void toggleLayerLock(String layerId, bool isLocked) {
    final layerIndex =
        _state.layers.indexWhere((layer) => layer['id'] == layerId);
    if (layerIndex >= 0) {
      _state.layers[layerIndex]['isLocked'] = isLocked;
      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 切换图层可见性
  void toggleLayerVisibility(String layerId, bool isVisible) {
    final layerIndex =
        _state.layers.indexWhere((layer) => layer['id'] == layerId);
    if (layerIndex >= 0) {
      _state.layers[layerIndex]['isVisible'] = isVisible;
      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 切换吸附功能
  void toggleSnap() {
    _state.snapEnabled = !_state.snapEnabled;
    notifyListeners();
  }

  /// 撤销操作
  void undo() {
    if (_undoRedoManager.canUndo) {
      _undoRedoManager.undo();
    }
  }

  /// 解组元素
  void ungroupElements(String groupId) {
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final page = _state.pages[_state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;
      final index = elements.indexWhere((e) => e['id'] == groupId);

      if (index >= 0 && elements[index]['type'] == 'group') {
        final group = elements[index];
        final groupElements = group['elements'] as List<dynamic>;

        // 删除组
        elements.removeAt(index);

        // 添加组中的所有元素
        for (final element in groupElements) {
          elements.add(element);
        }

        // 更新选中的元素
        _state.selectedElementIds =
            groupElements.map<String>((e) => e['id'] as String).toList();
        _state.selectedElement = null;
        _state.hasUnsavedChanges = true;

        notifyListeners();
      }
    }
  }

  /// 取消组合选中的元素
  void ungroupSelectedElement() {
    if (_state.selectedElementIds.length != 1) {
      return;
    }

    // Check if the selected element is a group
    if (_state.selectedElement == null ||
        _state.selectedElement!['type'] != 'group') {
      return;
    }

    final groupElement = Map<String, dynamic>.from(_state.selectedElement!);
    final content = groupElement['content'] as Map<String, dynamic>;
    final children = content['children'] as List<dynamic>;

    if (children.isEmpty) return;

    // 转换子元素的坐标为全局坐标
    final groupX = (groupElement['x'] as num).toDouble();
    final groupY = (groupElement['y'] as num).toDouble();

    final childElements = children.map((child) {
      final childMap = Map<String, dynamic>.from(child as Map<String, dynamic>);
      final x = (childMap['x'] as num).toDouble() + groupX;
      final y = (childMap['y'] as num).toDouble() + groupY;

      return {
        ...childMap,
        'id': '${childMap['type']}_${_uuid.v4()}', // 生成新ID避免冲突
        'x': x,
        'y': y,
      };
    }).toList();

    final operation = UngroupElementOperation(
      groupElement: groupElement,
      childElements: childElements,
      addElement: (e) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.add(e);

          // 选中组合元素
          _state.selectedElementIds = [e['id'] as String];
          _state.selectedElement = e;

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      removeElement: (id) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          elements.removeWhere((e) => e['id'] == id);

          // 如果是当前选中的元素，清除选择
          if (_state.selectedElementIds.contains(id)) {
            _state.selectedElementIds.clear();
            _state.selectedElement = null;
          }

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      addElements: (elements) {
        if (_state.currentPageIndex >= 0 &&
            _state.currentPageIndex < _state.pages.length) {
          final page = _state.pages[_state.currentPageIndex];
          final pageElements = page['elements'] as List<dynamic>;
          pageElements.addAll(elements);

          // 选中所有子元素
          _state.selectedElementIds =
              elements.map((e) => e['id'] as String).toList();
          _state.selectedElement = null; // 多选时不显示单个元素的属性

          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 更新元素透明度
  void updateElementOpacity(String id, double opacity,
      {bool isInteractive = false}) {
    // During interactive operations like sliding, we don't record undo operations
    // Only update the UI
    if (isInteractive) {
      if (_state.currentPageIndex >= 0 &&
          _state.currentPageIndex < _state.pages.length) {
        final page = _state.pages[_state.currentPageIndex];
        final elements = page['elements'] as List<dynamic>;
        final elementIndex = elements.indexWhere((e) => e['id'] == id);

        if (elementIndex >= 0) {
          final element = elements[elementIndex] as Map<String, dynamic>;
          element['opacity'] = opacity;

          // If it's the currently selected element, update selectedElement
          if (_state.selectedElementIds.contains(id)) {
            _state.selectedElement = element;
          }

          // Don't modify hasUnsavedChanges here since this is a temporary state
          notifyListeners();
        }
      }
      return;
    }

    // For non-interactive (final) update, use the normal property update with undo/redo
    updateElementProperty(id, 'opacity', opacity);
  }

  /// 更新元素位置（带吸附功能）
  void updateElementPositionWithSnap(String id, Offset delta) {
    final elementIndex =
        state.currentPageElements.indexWhere((e) => e['id'] == id);
    if (elementIndex < 0) return;

    final element = state.currentPageElements[elementIndex];

    // 当前位置
    double x = (element['x'] as num).toDouble();
    double y = (element['y'] as num).toDouble();

    // 新位置
    double newX = x + delta.dx;
    double newY = y + delta.dy;

    // 如果启用了吸附功能，这里可以添加吸附逻辑
    if (state.snapEnabled) {
      // 简单的网格吸附示例 (假设gridSize已定义)
      const gridSize = 10.0; // 可以从state获取或设为参数
      newX = (newX / gridSize).round() * gridSize;
      newY = (newY / gridSize).round() * gridSize;
    }

    // 更新元素位置
    updateElementProperties(id, {'x': newX, 'y': newY});
  }

  /// 更新元素属性
  void updateElementProperties(String id, Map<String, dynamic> properties) {
    if (_state.currentPageIndex >= _state.pages.length) return;

    final page = _state.pages[_state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      final element = elements[elementIndex] as Map<String, dynamic>;
      final oldProperties = Map<String, dynamic>.from(element);

      // 更新属性
      final newProperties = {...element};
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

      final operation = ElementPropertyOperation(
        elementId: id,
        oldProperties: oldProperties,
        newProperties: newProperties,
        updateElement: (id, props) {
          if (_state.currentPageIndex >= 0 &&
              _state.currentPageIndex < _state.pages.length) {
            final page = _state.pages[_state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            final elementIndex = elements.indexWhere((e) => e['id'] == id);

            if (elementIndex >= 0) {
              elements[elementIndex] = props;

              // 如果是当前选中的元素，更新selectedElement
              if (_state.selectedElementIds.contains(id)) {
                _state.selectedElement = props;
              }

              _state.hasUnsavedChanges = true;
              notifyListeners();
            }
          }
        },
      );

      _undoRedoManager.addOperation(operation);
    }
  }

  /// 更新元素属性
  /// 更新单个元素属性
  void updateElementProperty(String id, String property, dynamic value) {
    updateElementProperties(id, {property: value});
  }

  /// 更新元素顺序
  void updateElementsOrder() {
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 更新图层属性
  void updateLayerProperties(String layerId, Map<String, dynamic> properties) {
    final layerIndex = _state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = _state.layers[layerIndex] as Map<String, dynamic>;
    final oldProperties = Map<String, dynamic>.from(layer);

    // 更新属性
    final newProperties = {...layer};
    properties.forEach((key, value) {
      newProperties[key] = value;
    });

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        final index = _state.layers.indexWhere((l) => l['id'] == id);
        if (index >= 0) {
          _state.layers[index] = props;
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  void updatePageProperties(Map<String, dynamic> properties) {
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final pageIndex = _state.currentPageIndex;
      final page = _state.pages[pageIndex];

      // Make sure the background color is properly formatted
      if (properties.containsKey('backgroundColor')) {
        String backgroundColor = properties['backgroundColor'] as String;
        if (!backgroundColor.startsWith('#')) {
          backgroundColor = '#$backgroundColor';
          properties['backgroundColor'] = backgroundColor;
        }
      }

      // Create a copy of the old properties that will be modified
      final oldProperties = <String, dynamic>{};
      properties.forEach((key, value) {
        if (page.containsKey(key)) {
          oldProperties[key] = page[key];
        }
      });

      // Create the operation
      final operation = UpdatePagePropertyOperation(
        pageIndex: pageIndex,
        oldProperties: oldProperties,
        newProperties: Map<String, dynamic>.from(properties),
        updatePage: (index, props) {
          if (index >= 0 && index < _state.pages.length) {
            final page = _state.pages[index];
            // Update page properties
            props.forEach((key, value) {
              page[key] = value;
            });

            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        },
      );

      // Add the operation to the undo/redo manager
      _undoRedoManager.addOperation(operation);
    }
  }

  /// 添加元素的通用方法
  void _addElement(Map<String, dynamic> element) {
    final operation = AddElementOperation(
        element: element,
        addElement: (e) {
          if (_state.currentPageIndex >= 0 &&
              _state.currentPageIndex < _state.pages.length) {
            final page = _state.pages[_state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.add(e);

            // 选中新添加的元素
            _state.selectedElementIds = [e['id'] as String];
            _state.selectedElement = e;
            _state.hasUnsavedChanges = true;

            notifyListeners();
          }
        },
        removeElement: (id) {
          if (_state.currentPageIndex >= 0 &&
              _state.currentPageIndex < _state.pages.length) {
            final page = _state.pages[_state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['id'] == id);

            // 如果删除的是当前选中的元素，清除选择
            if (_state.selectedElementIds.contains(id)) {
              _state.selectedElementIds.remove(id);
              if (_state.selectedElementIds.isEmpty) {
                _state.selectedElement = null;
              }
            }

            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        });

    // Add the operation to the undo/redo manager
    _undoRedoManager.addOperation(operation);
  }

  /// 创建自定义操作
  UndoableOperation _createCustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required String description,
  }) {
    return _CustomOperation(
      execute: execute,
      undo: undo,
      description: description,
    );
  }

  /// 初始化默认数据
  void _initDefaultData() {
    // 创建默认页面
    final defaultPage = {
      'id': _uuid.v4(),
      'name': '页面1',
      'index': 0,
      'width': 595.0, // A4纸宽度
      'height': 842.0, // A4纸高度
      'backgroundColor': '#FFFFFF',
      'backgroundOpacity': 1.0,
      'elements': <Map<String, dynamic>>[],
    };

    // 创建默认图层
    final defaultLayer = {
      'id': _uuid.v4(),
      'name': '图层1',
      'order': 0,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 添加到状态中
    _state.pages.add(defaultPage);
    _state.layers.add(defaultLayer);
    _state.currentPageIndex = 0;

    // 通知监听器
    notifyListeners();
  }
}

/// 自定义操作
class _CustomOperation implements UndoableOperation {
  final VoidCallback _executeCallback;
  final VoidCallback _undoCallback;
  @override
  final String description;

  _CustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required this.description,
  })  : _executeCallback = execute,
        _undoCallback = undo;

  @override
  void execute() {
    _executeCallback();
  }

  @override
  void undo() {
    _undoCallback();
  }
}
