import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';

import '../../../application/services/practice/practice_service.dart';
import 'canvas_capture.dart';
import 'practice_edit_state.dart';
import 'thumbnail_generator.dart';
import 'undo_redo_manager.dart';

/// 字帖编辑控制器
class PracticeEditController extends ChangeNotifier {
  // 状态
  final PracticeEditState _state = PracticeEditState();

  // 撤销/重做管理器
  late final UndoRedoManager _undoRedoManager;

  // UUID生成器
  final Uuid _uuid = const Uuid();

  // 字帖ID和标题
  String? _practiceId;
  String? _practiceTitle;

  // 服务实例
  final PracticeService _practiceService;

  // 预览模式下的画布 GlobalKey
  GlobalKey? _canvasKey;

  // 每个页面的 GlobalKey 映射表
  final Map<String, GlobalKey> _pageKeys = {};

  // 预览模式回调函数
  Function(bool)? _previewModeCallback;

  /// 构造函数
  PracticeEditController(this._practiceService) {
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

  /// 获取画布 GlobalKey
  GlobalKey? get canvasKey => _canvasKey;

  /// 获取画布缩放值
  double get canvasScale => _state.canvasScale;

  /// 检查字帖是否已保存过
  bool get isSaved => _practiceId != null;

  /// 获取当前字帖ID
  String? get practiceId => _practiceId;

  /// 获取当前字帖标题
  String? get practiceTitle => _practiceTitle;

  /// 获取当前状态
  PracticeEditState get state => _state;

  /// 获取撤销/重做管理器
  UndoRedoManager get undoRedoManager => _undoRedoManager;

  /// 添加集字元素
  void addCollectionElement(String characters) {
    _checkDisposed();
    final element = {
      'id': 'collection_${_uuid.v4()}',
      'type': 'collection',
      'x': 100.0,
      'y': 100.0,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '集字元素', // 默认名称
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
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '集字元素', // 默认名称
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
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '集字元素', // 默认名称
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
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '图片元素', // 默认名称
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
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '图片元素', // 默认名称
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
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '图片元素', // 默认名称
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
    if (_state.currentPage == null) return;

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
        // 获取当前页面的图层列表
        if (_state.currentPage != null) {
          if (!_state.currentPage!['layers'].containsKey('layers')) {
            _state.currentPage!['layers'] = <Map<String, dynamic>>[];
          }
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          layers.add(l);
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      removeLayer: (id) {
        // 从当前页面的图层列表中移除
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final index = layers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            layers.removeAt(index);
            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 添加新图层
  void addNewLayer() {
    if (_state.currentPage == null) return;

    // 创建新图层
    final newLayer = {
      'id': _uuid.v4(),
      'name': '图层${_state.layers.length + 1}',
      'order': _state.layers.length,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 添加到当前页面的图层列表
    if (!_state.currentPage!.containsKey('layers')) {
      _state.currentPage!['layers'] = <Map<String, dynamic>>[];
    }
    final layers = _state.currentPage!['layers'] as List<dynamic>;
    layers.add(newLayer);
    _state.hasUnsavedChanges = true;

    notifyListeners();
  }

  void addNewPage() {
    if (_state.pages.isNotEmpty) {
      // 创建默认图层
      final defaultLayer = {
        'id': _uuid.v4(),
        'name': '图层1',
        'order': 0,
        'isVisible': true,
        'isLocked': false,
        'opacity': 1.0,
      };

      // Create a new page with default properties
      final newPage = {
        'id': 'page_${DateTime.now().millisecondsSinceEpoch}',
        'name': '页面${_state.pages.length + 1}',
        'width': 210.0, // A4纸宽度（毫米）
        'height': 297.0, // A4纸高度（毫米）
        'orientation': 'portrait', // 默认纵向
        'dpi': 300, // 默认DPI
        'backgroundColor': '#FFFFFF',
        'backgroundOpacity': 1.0,
        'background': {
          'type': 'color',
          'value': '#FFFFFF',
        },
        'elements': <Map<String, dynamic>>[],
        'layers': <Map<String, dynamic>>[defaultLayer], // 每个页面都有自己的图层
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
  void addPage(Map<String, dynamic> page) {
    _state.pages.add(page);
    _state.currentPageIndex = _state.pages.length - 1;

    // 标记为未保存
    _state.markUnsaved();

    notifyListeners();

    // 记录操作以便撤销
    _undoRedoManager.addOperation(_createCustomOperation(
      execute: () => _state.pages.removeLast(),
      undo: () => _state.pages.add(page),
      description: '添加页面',
    ));
  }

  /// 添加文本元素
  void addTextElement() {
    _checkDisposed();
    final element = {
      'id': 'text_${_uuid.v4()}',
      'type': 'text',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '文本元素', // 默认名称
      'content': {
        'text': '属性页\n输入文本',
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
      'layerId': _state.selectedLayerId ?? _state.layers.first['id'],
      'opacity': 1.0,
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '文本元素', // 默认名称
      'content': {
        'text': '双击编辑文本',
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
  }

  /// Aligns the specified elements according to the given alignment type.
  ///
  /// [elementIds] is a list of element IDs to align.
  /// [alignment] can be 'left', 'right', 'centerH', 'top', 'bottom', or 'centerV'.
  void alignElements(List<String> elementIds, String alignment) {
    if (elementIds.length < 2) return; // Need at least 2 elements to align

    // Get all elements to be aligned
    final elements = <Map<String, dynamic>>[];
    for (final id in elementIds) {
      final element = _state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        elements.add(element);
      }
    }

    if (elements.length < 2) return;

    // Save original positions for undo operation
    final originalPositions = <String, Map<String, double>>{};
    for (final element in elements) {
      final id = element['id'] as String;
      originalPositions[id] = {
        'x': (element['x'] as num).toDouble(),
        'y': (element['y'] as num).toDouble(),
      };
    }

    // Calculate alignment positions
    double alignValue = 0;

    switch (alignment) {
      case 'left':
        // Align to leftmost element
        alignValue =
            elements.map((e) => (e['x'] as num).toDouble()).reduce(math.min);
        for (final element in elements) {
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            _state.currentPageElements[index]['x'] = alignValue;
          }
        }
        break;

      case 'right':
        // Align to rightmost edge
        alignValue = elements
            .map((e) =>
                (e['x'] as num).toDouble() + (e['width'] as num).toDouble())
            .reduce(math.max);
        for (final element in elements) {
          final width = (element['width'] as num).toDouble();
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            _state.currentPageElements[index]['x'] = alignValue - width;
          }
        }
        break;

      case 'centerH':
        // Align to horizontal center
        final centerValues = elements.map((e) =>
            (e['x'] as num).toDouble() + (e['width'] as num).toDouble() / 2);
        final avgCenter =
            centerValues.reduce((a, b) => a + b) / centerValues.length;

        for (final element in elements) {
          final width = (element['width'] as num).toDouble();
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            _state.currentPageElements[index]['x'] = avgCenter - width / 2;
          }
        }
        break;

      case 'top':
        // Align to topmost element
        alignValue =
            elements.map((e) => (e['y'] as num).toDouble()).reduce(math.min);
        for (final element in elements) {
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            _state.currentPageElements[index]['y'] = alignValue;
          }
        }
        break;

      case 'bottom':
        // Align to bottommost edge
        alignValue = elements
            .map((e) =>
                (e['y'] as num).toDouble() + (e['height'] as num).toDouble())
            .reduce(math.max);
        for (final element in elements) {
          final height = (element['height'] as num).toDouble();
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            _state.currentPageElements[index]['y'] = alignValue - height;
          }
        }
        break;

      case 'centerV':
        // Align to vertical center
        final centerValues = elements.map((e) =>
            (e['y'] as num).toDouble() + (e['height'] as num).toDouble() / 2);
        final avgCenter =
            centerValues.reduce((a, b) => a + b) / centerValues.length;

        for (final element in elements) {
          final height = (element['height'] as num).toDouble();
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == element['id']);
          if (index >= 0) {
            _state.currentPageElements[index]['y'] = avgCenter - height / 2;
          }
        }
        break;
    }

    // Create an operation for undo/redo
    final operation = _createCustomOperation(
      execute: () {
        // Apply the alignment positions
        for (final element in elements) {
          final id = element['id'] as String;
          final index =
              _state.currentPageElements.indexWhere((e) => e['id'] == id);
          if (index >= 0) {
            switch (alignment) {
              case 'left':
                _state.currentPageElements[index]['x'] = alignValue;
                break;
              case 'right':
                _state.currentPageElements[index]['x'] = alignValue -
                    (_state.currentPageElements[index]['width'] as num)
                        .toDouble();
                break;
              case 'centerH':
                final width =
                    (_state.currentPageElements[index]['width'] as num)
                        .toDouble();
                final centerValues = elements.map((e) =>
                    (e['x'] as num).toDouble() +
                    (e['width'] as num).toDouble() / 2);
                final avgCenter =
                    centerValues.reduce((a, b) => a + b) / centerValues.length;
                _state.currentPageElements[index]['x'] = avgCenter - width / 2;
                break;
              case 'top':
                _state.currentPageElements[index]['y'] = alignValue;
                break;
              case 'bottom':
                _state.currentPageElements[index]['y'] = alignValue -
                    (_state.currentPageElements[index]['height'] as num)
                        .toDouble();
                break;
              case 'centerV':
                final height =
                    (_state.currentPageElements[index]['height'] as num)
                        .toDouble();
                final centerValues = elements.map((e) =>
                    (e['y'] as num).toDouble() +
                    (e['height'] as num).toDouble() / 2);
                final avgCenter =
                    centerValues.reduce((a, b) => a + b) / centerValues.length;
                _state.currentPageElements[index]['y'] = avgCenter - height / 2;
                break;
            }
          }
        }
        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
      undo: () {
        // Restore original positions
        for (final entry in originalPositions.entries) {
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == entry.key);
          if (index >= 0) {
            _state.currentPageElements[index]['x'] = entry.value['x']!;
            _state.currentPageElements[index]['y'] = entry.value['y']!;
          }
        }
        _state.hasUnsavedChanges = true;
        notifyListeners();
      },
      description: 'Align elements ($alignment)',
    );

    _undoRedoManager.addOperation(operation);

    // The operation will be executed when it's added to the manager,
    // so we don't need to call notifyListeners() here
  }

  /// 从 RepaintBoundary 捕获图像
  Future<Uint8List?> captureFromRepaintBoundary(GlobalKey key) async {
    try {
      // 获取 RenderRepaintBoundary
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('无法获取 RenderRepaintBoundary');
        return null;
      }

      // 捕获图像
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      debugPrint('无法将图像转换为字节数据');
      return null;
    } catch (e, stack) {
      debugPrint('从 RepaintBoundary 捕获图像失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }

  /// 检查标题是否已存在
  Future<bool> checkTitleExists(String title) async {
    // 如果是当前字帖的标题，不算冲突
    if (_practiceTitle == title) {
      return false;
    }

    try {
      // 查询是否有相同标题的字帖，排除当前ID
      return await _practiceService.isTitleExists(title,
          excludeId: _practiceId);
    } catch (e) {
      debugPrint('检查标题是否存在时出错: $e');
      // 发生错误时假设标题不存在
      return false;
    }
  }

  /// 清除所有选择
  void clearSelection() {
    state.selectedElementIds.clear();
    state.selectedElement = null;
    notifyListeners();
  }

  /// 清空撤销/重做历史
  void clearUndoRedoHistory() {
    _undoRedoManager.clearHistory();
  }

  /// 删除所有图层
  void deleteAllLayers() {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    if (layers.length <= 1) return;

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
    final oldLayers = List<Map<String, dynamic>>.from(
        layers.map((l) => Map<String, dynamic>.from(l)));

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
            if (_state.currentPage != null &&
                _state.currentPage!.containsKey('layers')) {
              final layers = _state.currentPage!['layers'] as List<dynamic>;
              layers.clear();
              layers.add(defaultLayer);

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
            }
          },
          undo: () {
            if (_state.currentPage != null &&
                _state.currentPage!.containsKey('layers')) {
              final layers = _state.currentPage!['layers'] as List<dynamic>;
              layers.clear();
              layers.addAll(oldLayers);

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
            }
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
    if (_state.currentPage == null) return;

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
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          layers.insert(index, l);
          _state.hasUnsavedChanges = true;
          notifyListeners();
        }
      },
      removeLayer: (id) {
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final index = layers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            layers.removeAt(index);

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
  void deletePage(int index) {
    if (index < 0 || index >= _state.pages.length) return;

    final deletedPage = _state.pages[index];
    _state.pages.removeAt(index);

    // 更新当前页面索引
    if (_state.pages.isEmpty) {
      _state.currentPageIndex = -1;
    } else if (_state.currentPageIndex >= _state.pages.length) {
      _state.currentPageIndex = _state.pages.length - 1;
    }

    // 标记为未保存
    _state.markUnsaved();

    notifyListeners();

    // 记录操作以便撤销
    _undoRedoManager.addOperation(_createCustomOperation(
      execute: () => _state.pages.insert(index, deletedPage),
      undo: () => _state.pages.removeAt(index),
      description: '删除页面',
    ));
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

  /// 释放资源
  @override
  void dispose() {
    // 清除所有引用
    _canvasKey = null;
    _pageKeys.clear();
    _previewModeCallback = null;

    // 标记为已销毁
    _state.isDisposed = true;

    super.dispose();
  }

  /// 将多个元素均匀分布
  void distributeElements(List<String> elementIds, String direction) {
    _checkDisposed();

    if (elementIds.length < 3) return; // 至少需要3个元素才能分布

    // 获取元素
    final elements = elementIds
        .map((id) => _state.currentPageElements.firstWhere((e) => e['id'] == id,
            orElse: () => <String, dynamic>{}))
        .where((e) => e.isNotEmpty)
        .toList();

    if (elements.length < 3) return;

    // 记录变更前的状态
    final oldState = Map<String, Map<String, dynamic>>.fromEntries(
      elements.map(
          (e) => MapEntry(e['id'] as String, Map<String, dynamic>.from(e))),
    );

    if (direction == 'horizontal') {
      // 按X坐标排序
      elements.sort((a, b) => (a['x'] as num).compareTo(b['x'] as num));

      // 获取第一个和最后一个元素的位置
      final firstX = elements.first['x'] as num;
      final lastX = elements.last['x'] as num;

      // 计算间距
      final totalSpacing = lastX - firstX;
      final step = totalSpacing / (elements.length - 1);

      // 分布元素
      for (int i = 1; i < elements.length - 1; i++) {
        final element = elements[i];
        final newX = firstX + (step * i);

        // 更新元素位置
        final elementIndex = _state.currentPageElements
            .indexWhere((e) => e['id'] == element['id']);
        if (elementIndex != -1) {
          _state.currentPageElements[elementIndex]['x'] = newX;
        }
      }
    } else if (direction == 'vertical') {
      // 按Y坐标排序
      elements.sort((a, b) => (a['y'] as num).compareTo(b['y'] as num));

      // 获取第一个和最后一个元素的位置
      final firstY = elements.first['y'] as num;
      final lastY = elements.last['y'] as num;

      // 计算间距
      final totalSpacing = lastY - firstY;
      final step = totalSpacing / (elements.length - 1);

      // 分布元素
      for (int i = 1; i < elements.length - 1; i++) {
        final element = elements[i];
        final newY = firstY + (step * i);

        // 更新元素位置
        final elementIndex = _state.currentPageElements
            .indexWhere((e) => e['id'] == element['id']);
        if (elementIndex != -1) {
          _state.currentPageElements[elementIndex]['y'] = newY;
        }
      }
    }

    // 记录变更后的状态
    final newState = Map<String, Map<String, dynamic>>.fromEntries(
      elements.map((e) {
        final index = _state.currentPageElements
            .indexWhere((elem) => elem['id'] == e['id']);
        return MapEntry(
            e['id'] as String,
            index != -1
                ? Map<String, dynamic>.from(_state.currentPageElements[index])
                : Map<String, dynamic>.from(e));
      }),
    );

    // 添加撤销操作
    final operation = _createCustomOperation(
      execute: () {
        // Apply the new state
        for (var entry in newState.entries) {
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == entry.key);
          if (index != -1) {
            _state.currentPageElements[index]['x'] = entry.value['x'];
            _state.currentPageElements[index]['y'] = entry.value['y'];
          }
        }
        notifyListeners();
      },
      undo: () {
        // Apply the old state
        for (var entry in oldState.entries) {
          final index = _state.currentPageElements
              .indexWhere((e) => e['id'] == entry.key);
          if (index != -1) {
            _state.currentPageElements[index]['x'] = entry.value['x'];
            _state.currentPageElements[index]['y'] = entry.value['y'];
          }
        }
        notifyListeners();
      },
      description: '均匀分布元素',
    );

    _undoRedoManager.addOperation(operation);

    notifyListeners();
  }

  void duplicateLayer(String layerId) {
    if (_state.currentPage == null) return;

    final layerIndex = _state.layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final originalLayer = _state.layers[layerIndex];

    // Create a duplicate layer with a new ID
    final newLayerId = _uuid.v4();
    final duplicatedLayer = {
      ...Map<String, dynamic>.from(originalLayer),
      'id': newLayerId,
      'name': '${originalLayer['name']} (复制)',
      'order': _state.layers.length, // Place at the end of the layers list
    };

    // Find all elements on the original layer
    final elementsOnLayer = <Map<String, dynamic>>[];
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final page = _state.pages[_state.currentPageIndex];
      final pageElements = page['elements'] as List<dynamic>;

      // Create copies of all elements in the layer with new IDs
      for (final element in pageElements) {
        if (element['layerId'] == layerId) {
          final elementCopy =
              Map<String, dynamic>.from(element as Map<String, dynamic>);
          // Create new ID for the element
          final String elementType = elementCopy['type'] as String;
          elementCopy['id'] = '${elementType}_${_uuid.v4()}';
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
            if (_state.currentPage != null) {
              final layers = _state.currentPage!['layers'] as List<dynamic>;
              layers.add(l);
              _state.hasUnsavedChanges = true;
            }
          },
          removeLayer: (id) {
            if (_state.currentPage != null) {
              final layers = _state.currentPage!['layers'] as List<dynamic>;
              layers.removeWhere((l) => l['id'] == id);
              _state.hasUnsavedChanges = true;
            }
          },
        ),

        // Add all duplicated elements
        _createCustomOperation(
          execute: () {
            if (_state.currentPageIndex >= 0 &&
                _state.currentPageIndex < _state.pages.length) {
              final page = _state.pages[_state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;
              elements.addAll(elementsOnLayer);

              // Select the new layer
              _state.selectedLayerId = newLayerId;
              _state.hasUnsavedChanges = true;
            }
            notifyListeners();
          },
          undo: () {
            if (_state.currentPageIndex >= 0 &&
                _state.currentPageIndex < _state.pages.length) {
              final page = _state.pages[_state.currentPageIndex];
              final elements = page['elements'] as List<dynamic>;

              // Remove all elements from the duplicated layer
              final elementIds = elementsOnLayer.map((e) => e['id']).toList();
              elements.removeWhere((e) => elementIds.contains(e['id']));

              _state.hasUnsavedChanges = true;
            }
            notifyListeners();
          },
          description: '添加复制图层中的元素',
        ),
      ],
      operationDescription: '复制图层',
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 进入组编辑模式
  void enterGroupEditMode(String groupId) {
    _checkDisposed();
    // 设置当前编辑的组ID
    // _state.currentEditingGroupId = groupId;
    // 清除当前选择
    _state.selectedElementIds.clear();
    // 通知UI更新
    notifyListeners();
  }

  /// 获取页面的 GlobalKey 列表
  /// 为每个页面返回不同的 GlobalKey
  List<GlobalKey> getPageKeys() {
    debugPrint('=== 获取页面的 GlobalKey 列表 ===');
    debugPrint('页面数量: ${_state.pages.length}');

    if (_canvasKey == null) {
      debugPrint('错误: _canvasKey 为 null');
      return [];
    }

    // 检查主画布 key 是否有效
    debugPrint(
        '主画布 _canvasKey: ${_canvasKey.toString()}, 是否有 currentContext: ${_canvasKey?.currentContext != null}');
    if (_canvasKey?.currentContext != null) {
      final renderObject = _canvasKey!.currentContext!.findRenderObject();
      debugPrint('_canvasKey 的 RenderObject 类型: ${renderObject?.runtimeType}');

      if (renderObject is RenderRepaintBoundary) {
        debugPrint('_canvasKey 是有效的 RenderRepaintBoundary');
      } else {
        debugPrint('警告: _canvasKey 不是 RenderRepaintBoundary');
      }
    } else {
      debugPrint('警告: _canvasKey 没有 currentContext');
    }

    // 创建页面 key 列表
    final List<GlobalKey> keys = [];

    // 当前页面使用主画布 key
    final currentPageIndex = _state.currentPageIndex;

    for (int i = 0; i < _state.pages.length; i++) {
      final page = _state.pages[i];
      final pageId = page['id'] as String;

      if (i == currentPageIndex) {
        // 当前页面使用主画布 key
        debugPrint('页面 $i (ID: $pageId) 使用主画布 key: ${_canvasKey.toString()}');
        keys.add(_canvasKey!);
      } else {
        // 其他页面使用临时 key
        final tempKey = GlobalKey();
        debugPrint('页面 $i (ID: $pageId) 使用临时 key: ${tempKey.toString()}');
        keys.add(tempKey);
      }
    }

    debugPrint('返回 ${keys.length} 个 GlobalKey');
    return keys;
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
        orElse: () => <String, dynamic>{},
      );
      if (element.isNotEmpty) {
        selectedElements.add(Map<String, dynamic>.from(element));
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
      'isLocked': false, // 锁定标志
      'isHidden': false, // 隐藏标志
      'name': '组合元素', // 默认名称
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

  /// 加载字帖
  Future<bool> loadPractice(String id) async {
    try {
      final practice = await _practiceService.loadPractice(id);
      if (practice == null) return false;

      // 更新字帖数据
      _practiceId = practice['id'] as String;
      _practiceTitle = practice['title'] as String;
      _state.pages = List<Map<String, dynamic>>.from(practice['pages'] as List);

      // 如果有页面，选择第一个页面
      if (_state.pages.isNotEmpty) {
        _state.currentPageIndex = 0;
      } else {
        _state.currentPageIndex = -1;
      }

      // 清除选择
      _state.selectedElementIds.clear();
      _state.selectedElement = null;
      _state.selectedLayerId = null;

      // 标记为已保存
      _state.markSaved();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('加载字帖失败: $e');
      return false;
    }
  }

  @override
  void notifyListeners() {
    if (_state.isDisposed) {
      debugPrint('警告: 尝试在控制器销毁后调用 notifyListeners()');
      return;
    }
    super.notifyListeners();
  }

  /// 重做操作
  void redo() {
    if (_undoRedoManager.canRedo) {
      _undoRedoManager.redo();
    }
  }

  /// 重命名图层
  void renameLayer(String layerId, String newName) {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = layers[layerIndex];
    final oldProperties = Map<String, dynamic>.from(layer);
    final newProperties =
        Map<String, dynamic>.from({...layer, 'name': newName});

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final index = layers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            layers[index] = props;
            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 重新排序图层
  void reorderLayer(int oldIndex, int newIndex) {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;

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

    _state.hasUnsavedChanges = true;
    notifyListeners();
  }

  /// 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;

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
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final layer = layers.removeAt(oldIndex);
          layers.insert(newIndex, layer);

          // 更新order属性
          for (int i = 0; i < layers.length; i++) {
            final layer = layers[i];
            layer['order'] = i;
          }
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

  /// 重置画布缩放
  void resetZoom() {
    _state.canvasScale = 1.0;
    notifyListeners();
  }

  /// 另存为新字帖
  /// 始终提示用户输入标题
  /// 返回值:
  /// - true: 保存成功
  /// - false: 保存失败
  /// - 'title_exists': 标题已存在，需要确认是否覆盖
  Future<dynamic> saveAsNewPractice(String title,
      {bool forceOverwrite = false}) async {
    _checkDisposed();
    // 如果没有页面，则不保存
    if (_state.pages.isEmpty) return false;

    if (title.isEmpty) {
      return false;
    }

    // 如果不是强制覆盖，检查标题是否存在
    if (!forceOverwrite) {
      final exists = await checkTitleExists(title);
      if (exists) {
        // 标题已存在，返回特殊值通知调用者需要确认覆盖
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始另存为新字帖: $title');

      // 生成缩略图
      final thumbnail = await _generateThumbnail();
      debugPrint(
          '缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      // 确保页面数据准备好被保存
      final pagesToSave = _state.pages.map((page) {
        // 创建页面的深拷贝
        final pageCopy = Map<String, dynamic>.from(page);

        // 确保元素列表被正确拷贝
        if (page.containsKey('elements')) {
          final elements = page['elements'] as List<dynamic>;
          pageCopy['elements'] =
              elements.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        // 确保图层列表被正确拷贝
        if (page.containsKey('layers')) {
          final layers = page['layers'] as List<dynamic>;
          pageCopy['layers'] =
              layers.map((l) => Map<String, dynamic>.from(l)).toList();
        }

        return pageCopy;
      }).toList();

      // 另存为新字帖（不使用现有ID）
      final result = await _practiceService.savePractice(
        id: null, // 生成新ID
        title: title,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      // 更新ID和标题
      _practiceId = result['id'] as String;
      _practiceTitle = title;

      // 标记为已保存
      _state.markSaved();
      notifyListeners();

      debugPrint('字帖另存为成功: $title, ID: $_practiceId');
      return true;
    } catch (e) {
      debugPrint('另存为字帖失败: $e');
      return false;
    }
  }

  /// 保存字帖
  /// 如果字帖未保存过，则提示用户输入标题
  /// 返回值:
  /// - true: 保存成功
  /// - false: 保存失败或需要提示用户输入标题
  /// - 'title_exists': 标题已存在，需要确认是否覆盖
  Future<dynamic> savePractice(
      {String? title, bool forceOverwrite = false}) async {
    _checkDisposed();
    // 如果没有页面，则不保存
    if (_state.pages.isEmpty) return false;

    // 如果未提供标题且从未保存过，返回false表示需要提示用户输入标题
    if (title == null && _practiceId == null) {
      return false;
    }

    // 使用当前标题或传入的新标题
    final saveTitle = title ?? _practiceTitle;
    if (saveTitle == null || saveTitle.isEmpty) {
      return false;
    }

    // 如果是新标题（非当前标题），检查标题是否存在
    if (!forceOverwrite && title != null && title != _practiceTitle) {
      final exists = await checkTitleExists(title);
      if (exists) {
        // 标题已存在，返回特殊值通知调用者需要确认覆盖
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始保存字帖: $saveTitle, ID: $_practiceId');

      // 生成缩略图
      final thumbnail = await _generateThumbnail();
      debugPrint(
          '缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      // 确保页面数据准备好被保存
      // 创建页面的深拷贝，确保所有内容都被保存
      final pagesToSave = _state.pages.map((page) {
        // 创建页面的深拷贝
        final pageCopy = Map<String, dynamic>.from(page);

        // 确保元素列表被正确拷贝
        if (page.containsKey('elements')) {
          final elements = page['elements'] as List<dynamic>;
          pageCopy['elements'] =
              elements.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        // 确保图层列表被正确拷贝
        if (page.containsKey('layers')) {
          final layers = page['layers'] as List<dynamic>;
          pageCopy['layers'] =
              layers.map((l) => Map<String, dynamic>.from(l)).toList();
        }

        return pageCopy;
      }).toList();

      // 保存字帖 - 使用现有ID或创建新ID
      final result = await _practiceService.savePractice(
        id: _practiceId, // 如果是null，将创建新字帖
        title: saveTitle,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      // 更新ID和标题
      _practiceId = result['id'] as String;
      _practiceTitle = saveTitle;

      // 标记为已保存
      _state.markSaved();
      notifyListeners();

      debugPrint('字帖保存成功: $saveTitle, ID: $_practiceId');
      return true;
    } catch (e) {
      debugPrint('保存字帖失败: $e');
      return false;
    }
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

  /// 设置画布 GlobalKey
  void setCanvasKey(GlobalKey key) {
    _canvasKey = key;
  }

  // 设置当前页面
  void setCurrentPage(int index) {
    if (index >= 0 && index < state.pages.length) {
      state.currentPageIndex = index;
      // Clear element and layer selections to show page properties
      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.selectedLayerId = null;

      // 确保图层面板显示当前页面的图层
      // 这里我们可以添加页面特定的图层加载逻辑
      // 目前我们使用全局图层，但将来可能需要每个页面有自己的图层

      notifyListeners();
    }
  }

  /// 设置图层锁定状态
  void setLayerLocked(String layerId, bool isLocked) {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = layers[layerIndex];
    final oldProperties = Map<String, dynamic>.from(layer);
    final newProperties =
        Map<String, dynamic>.from({...layer, 'isLocked': isLocked});

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final index = layers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            layers[index] = props;
            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 设置图层可见性
  void setLayerVisibility(String layerId, bool isVisible) {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = layers[layerIndex];
    final oldProperties = Map<String, dynamic>.from(layer);
    final newProperties =
        Map<String, dynamic>.from({...layer, 'isVisible': isVisible});

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final index = layers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            layers[index] = props;
            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 设置预览模式回调函数
  void setPreviewModeCallback(Function(bool) callback) {
    _previewModeCallback = callback;
  }

  /// 显示所有图层
  void showAllLayers() {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
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
              if (_state.currentPage != null &&
                  _state.currentPage!.containsKey('layers')) {
                final layers = _state.currentPage!['layers'] as List<dynamic>;
                final index = layers.indexWhere((l) => l['id'] == id);
                if (index >= 0) {
                  layers[index] = props;
                  _state.hasUnsavedChanges = true;
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
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((layer) => layer['id'] == layerId);
    if (layerIndex >= 0) {
      layers[layerIndex]['isLocked'] = isLocked;
      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 切换图层可见性
  void toggleLayerVisibility(String layerId, bool isVisible) {
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((layer) => layer['id'] == layerId);
    if (layerIndex >= 0) {
      layers[layerIndex]['isVisible'] = isVisible;
      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 切换预览模式
  void togglePreviewMode(bool isPreviewMode) {
    _state.isPreviewMode = isPreviewMode;

    // 调用预览模式回调函数
    if (_previewModeCallback != null) {
      _previewModeCallback!(isPreviewMode);
    }

    notifyListeners();
  }

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
        final group = elements[index] as Map<String, dynamic>;
        final content = group['content'] as Map<String, dynamic>;
        final groupChildren = content['children'] as List<dynamic>;

        // 获取组合元素坐标
        final groupX = (group['x'] as num).toDouble();
        final groupY = (group['y'] as num).toDouble();

        // 删除组
        elements.removeAt(index);

        // 添加组中的所有元素（调整为全局坐标）
        final newElementIds = <String>[];
        for (final childElement in groupChildren) {
          final child =
              Map<String, dynamic>.from(childElement as Map<String, dynamic>);

          // 计算全局坐标
          final childX = (child['x'] as num).toDouble() + groupX;
          final childY = (child['y'] as num).toDouble() + groupY;

          // 创建新元素
          final newElement = {
            ...child,
            'x': childX,
            'y': childY,
          };

          elements.add(newElement);
          newElementIds.add(newElement['id'] as String);
        }

        // 更新选中的元素
        _state.selectedElementIds = newElementIds;
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
      // 使用 state 中的 gridSize
      final gridSize = state.gridSize;
      newX = (newX / gridSize).round() * gridSize;
      newY = (newY / gridSize).round() * gridSize;

      // 打印吸附信息
      debugPrint('吸附功能生效: 将元素 $id 吸附到网格位置 ($newX, $newY)');
    }

    // 更新元素位置
    updateElementProperties(id, {'x': newX, 'y': newY});
  }

  /// 更新元素属性 - 拖动结束时使用，应用吸附并记录撤销/重做
  void updateElementProperties(String id, Map<String, dynamic> properties) {
    if (_state.currentPageIndex >= _state.pages.length) {
      debugPrint('【控制器】updateElementProperties: 当前页面索引无效，无法更新元素属性');
      return;
    }

    final page = _state.pages[_state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      final element = elements[elementIndex] as Map<String, dynamic>;
      final oldProperties = Map<String, dynamic>.from(element);

      // 处理吸附功能
      if (_state.snapEnabled) {
        final gridSize = _state.gridSize;
        bool hasSnapped = false;

        // 处理位置吸附 (x, y)
        if (properties.containsKey('x') || properties.containsKey('y')) {
          // 获取新的位置
          double newX = properties.containsKey('x')
              ? (properties['x'] as num).toDouble()
              : (element['x'] as num).toDouble();
          double newY = properties.containsKey('y')
              ? (properties['y'] as num).toDouble()
              : (element['y'] as num).toDouble();

          // 吸附到网格
          double snappedX = (newX / gridSize).round() * gridSize;
          double snappedY = (newY / gridSize).round() * gridSize;

          // 更新属性中的位置
          if (properties.containsKey('x')) {
            properties['x'] = snappedX;
            if (snappedX != newX) {
              hasSnapped = true;
            }
          }
          if (properties.containsKey('y')) {
            properties['y'] = snappedY;
            if (snappedY != newY) {
              hasSnapped = true;
            }
          }

          if (hasSnapped) {
            debugPrint('吸附功能生效: 将元素 $id 的位置吸附到网格 ($snappedX, $snappedY)');
          }
        }

        // 处理大小吸附 (width, height)
        if (properties.containsKey('width') ||
            properties.containsKey('height')) {
          // 获取新的尺寸
          double newWidth = properties.containsKey('width')
              ? (properties['width'] as num).toDouble()
              : (element['width'] as num).toDouble();
          double newHeight = properties.containsKey('height')
              ? (properties['height'] as num).toDouble()
              : (element['height'] as num).toDouble();

          // 吸附到网格
          double snappedWidth = (newWidth / gridSize).round() * gridSize;
          double snappedHeight = (newHeight / gridSize).round() * gridSize;

          // 确保最小尺寸
          snappedWidth = math.max(snappedWidth, 10.0);
          snappedHeight = math.max(snappedHeight, 10.0);

          // 更新属性中的尺寸
          if (properties.containsKey('width')) {
            properties['width'] = snappedWidth;
            if (snappedWidth != newWidth) {
              hasSnapped = true;
            }
          }
          if (properties.containsKey('height')) {
            properties['height'] = snappedHeight;
            if (snappedHeight != newHeight) {
              hasSnapped = true;
            }
          }

          if (hasSnapped) {
            debugPrint(
                '吸附功能生效: 将元素 $id 的尺寸吸附到网格 (宽=$snappedWidth, 高=$snappedHeight)');
          }
        }
      }

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

      // 处理组合控件的子元素调整
      if (element['type'] == 'group' &&
          (properties.containsKey('x') ||
              properties.containsKey('y') ||
              properties.containsKey('width') ||
              properties.containsKey('height'))) {
        // 获取组合控件的旧尺寸
        final oldWidth = (oldProperties['width'] as num).toDouble();
        final oldHeight = (oldProperties['height'] as num).toDouble();

        // 获取新的尺寸
        final newWidth = properties.containsKey('width')
            ? (properties['width'] as num).toDouble()
            : oldWidth;
        final newHeight = properties.containsKey('height')
            ? (properties['height'] as num).toDouble()
            : oldHeight;

        // 计算缩放比例
        final scaleX = oldWidth > 0 ? newWidth / oldWidth : 1.0;
        final scaleY = oldHeight > 0 ? newHeight / oldHeight : 1.0;

        // 获取子元素列表
        final content = newProperties['content'] as Map<String, dynamic>;
        final children = content['children'] as List<dynamic>;

        // 更新每个子元素的位置和大小
        for (int i = 0; i < children.length; i++) {
          final child = children[i] as Map<String, dynamic>;

          // 获取子元素的当前位置和大小
          final childX = (child['x'] as num).toDouble();
          final childY = (child['y'] as num).toDouble();
          final childWidth = (child['width'] as num).toDouble();
          final childHeight = (child['height'] as num).toDouble();

          // 根据组合控件的变形调整子元素
          // 处理位置变化
          if (properties.containsKey('x') || properties.containsKey('y')) {
            // 当组合控件移动时，子元素保持相对位置不变
            // 不需要更新子元素的相对坐标，因为它们是相对于组合控件的左上角的
          }

          // 处理大小变化
          if (properties.containsKey('width') ||
              properties.containsKey('height')) {
            // 当组合控件缩放时，子元素按比例缩放
            child['x'] = childX * scaleX;
            child['y'] = childY * scaleY;
            child['width'] = childWidth * scaleX;
            child['height'] = childHeight * scaleY;
          }

          // 处理旋转
          if (properties.containsKey('rotation')) {
            // 当组合控件旋转时，子元素的旋转角度也需要更新
            final oldRotation = (oldProperties['rotation'] as num).toDouble();
            final newRotation = (properties['rotation'] as num).toDouble();
            final deltaRotation = newRotation - oldRotation;

            // 更新子元素的旋转角度
            final childRotation = (child['rotation'] as num? ?? 0.0).toDouble();
            child['rotation'] = (childRotation + deltaRotation) % 360.0;
          }
        }
      }

      // 打印更新后的属性
      debugPrint('【控制器】updateElementProperties: 更新后的属性:');
      newProperties.forEach((key, value) {
        if (key != 'content') {
          // 不打印content，太长了
          debugPrint('【控制器】  $key: $value');
        }
      });

      final operation = ElementPropertyOperation(
        elementId: id,
        oldProperties: oldProperties,
        newProperties: newProperties,
        updateElement: (id, props) {
          debugPrint('【控制器】ElementPropertyOperation.updateElement: 开始更新元素');
          if (_state.currentPageIndex >= 0 &&
              _state.currentPageIndex < _state.pages.length) {
            final page = _state.pages[_state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            final elementIndex = elements.indexWhere((e) => e['id'] == id);

            if (elementIndex >= 0) {
              debugPrint(
                  '【控制器】ElementPropertyOperation.updateElement: 找到元素，索引=$elementIndex');
              elements[elementIndex] = props;

              // 如果是当前选中的元素，更新selectedElement
              if (_state.selectedElementIds.contains(id)) {
                debugPrint(
                    '【控制器】ElementPropertyOperation.updateElement: 更新selectedElement');
                _state.selectedElement = props;
              }

              _state.hasUnsavedChanges = true;
              debugPrint(
                  '【控制器】ElementPropertyOperation.updateElement: 调用notifyListeners()');
              notifyListeners();
              debugPrint('【控制器】ElementPropertyOperation.updateElement: 更新完成');
            } else {
              debugPrint(
                  '【控制器】ElementPropertyOperation.updateElement: 找不到元素，ID=$id');
            }
          } else {
            debugPrint('【控制器】ElementPropertyOperation.updateElement: 当前页面索引无效');
          }
        },
      );

      debugPrint('【控制器】updateElementProperties: 添加操作到撤销/重做管理器');
      _undoRedoManager.addOperation(operation);
      debugPrint('=== 元素属性更新完成 ===');
    }
  }

  /// 更新元素属性 - 拖动过程中使用，不应用吸附
  void updateElementPropertiesDuringDrag(
      String id, Map<String, dynamic> properties) {
    if (_state.currentPageIndex >= _state.pages.length) return;

    final page = _state.pages[_state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;
    final elementIndex = elements.indexWhere((e) => e['id'] == id);

    if (elementIndex >= 0) {
      final element = elements[elementIndex] as Map<String, dynamic>;

      // 确保大小不小于最小值
      if (properties.containsKey('width')) {
        double width = (properties['width'] as num).toDouble();
        properties['width'] = math.max(width, 10.0);
      }
      if (properties.containsKey('height')) {
        double height = (properties['height'] as num).toDouble();
        properties['height'] = math.max(height, 10.0);
      }

      // 直接更新元素属性，不应用吸附，不记录撤销/重做
      properties.forEach((key, value) {
        if (key == 'content' && element.containsKey('content')) {
          // 对于content对象，合并而不是替换
          final content = element['content'] as Map<String, dynamic>;
          final newContent = value as Map<String, dynamic>;
          newContent.forEach((contentKey, contentValue) {
            content[contentKey] = contentValue;
          });
        } else {
          element[key] = value;
        }
      });

      // 如果是当前选中的元素，更新selectedElement
      if (_state.selectedElementIds.contains(id)) {
        _state.selectedElement = element;
      }

      // 通知监听器更新UI
      notifyListeners();
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
    if (_state.currentPage == null ||
        !_state.currentPage!.containsKey('layers')) {
      return;
    }

    final layers = _state.currentPage!['layers'] as List<dynamic>;
    final layerIndex = layers.indexWhere((l) => l['id'] == layerId);
    if (layerIndex < 0) return;

    final layer = layers[layerIndex];
    final oldProperties = Map<String, dynamic>.from(layer);

    // 更新属性
    final newProperties = <String, dynamic>{...layer};
    properties.forEach((key, value) {
      newProperties[key] = value;
    });

    final operation = UpdateLayerPropertyOperation(
      layerId: layerId,
      oldProperties: oldProperties,
      newProperties: newProperties,
      updateLayer: (id, props) {
        if (_state.currentPage != null &&
            _state.currentPage!.containsKey('layers')) {
          final layers = _state.currentPage!['layers'] as List<dynamic>;
          final index = layers.indexWhere((l) => l['id'] == id);
          if (index >= 0) {
            layers[index] = props;
            _state.hasUnsavedChanges = true;
            notifyListeners();
          }
        }
      },
    );

    _undoRedoManager.addOperation(operation);
  }

  /// 更新页面
  void updatePage(int index, Map<String, dynamic> updatedPage) {
    if (index < 0 || index >= _state.pages.length) return;

    final oldPage = Map<String, dynamic>.from(_state.pages[index]);
    _state.pages[index] = updatedPage;

    // 标记为未保存
    _state.markUnsaved();

    notifyListeners();

    // 记录操作以便撤销
    _undoRedoManager.addOperation(_createCustomOperation(
      execute: () => _state.pages[index] = updatedPage,
      undo: () => _state.pages[index] = oldPage,
      description: '更新页面',
    ));
  }

  void updatePageProperties(Map<String, dynamic> properties) {
    if (_state.currentPageIndex >= 0 &&
        _state.currentPageIndex < _state.pages.length) {
      final pageIndex = _state.currentPageIndex;
      final page = _state.pages[pageIndex];

      // 更新页面属性

      // 处理背景颜色和透明度 - 只使用新格式
      // 1. 处理旧格式的背景颜色 (向后兼容，但转换为新格式)
      if (properties.containsKey('backgroundColor')) {
        String backgroundColor = properties['backgroundColor'] as String;
        if (!backgroundColor.startsWith('#')) {
          backgroundColor = '#$backgroundColor';
        }

        // 获取当前的背景透明度
        final backgroundOpacity = properties.containsKey('backgroundOpacity')
            ? (properties['backgroundOpacity'] as num).toDouble()
            : page.containsKey('background') &&
                    (page['background'] as Map<String, dynamic>)
                        .containsKey('opacity')
                ? (page['background'] as Map<String, dynamic>)['opacity']
                    as double
                : 1.0;

        // 只设置新格式的背景属性
        properties['background'] = {
          'type': 'color',
          'value': backgroundColor,
          'opacity': backgroundOpacity,
        };

        // 删除旧格式属性
        properties.remove('backgroundColor');
        properties.remove('backgroundType');
        properties.remove('backgroundOpacity');
      }

      // 2. 处理旧格式的背景透明度 (向后兼容，但转换为新格式)
      else if (properties.containsKey('backgroundOpacity')) {
        final backgroundOpacity =
            (properties['backgroundOpacity'] as num).toDouble();

        // 获取当前的背景颜色和类型
        final background = page.containsKey('background')
            ? Map<String, dynamic>.from(
                page['background'] as Map<String, dynamic>)
            : {'type': 'color', 'value': '#FFFFFF'};

        // 更新透明度
        background['opacity'] = backgroundOpacity;

        // 只设置新格式的背景属性
        properties['background'] = background;

        // 删除旧格式属性
        properties.remove('backgroundOpacity');
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

      // 立即执行操作，确保属性立即更新
      operation.execute();

      // Add the operation to the undo/redo manager
      _undoRedoManager.addOperation(operation);
    }
  }

  /// 更新字帖标题
  void updatePracticeTitle(String newTitle) {
    if (_practiceTitle != newTitle) {
      _practiceTitle = newTitle;
      _state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 切换吸附功能
  /// 设置画布缩放值
  void zoomTo(double scale) {
    _state.canvasScale = scale.clamp(0.1, 10.0); // 限制缩放范围
    notifyListeners();
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

  /// 检查控制器是否已销毁，如果已销毁则抛出异常
  void _checkDisposed() {
    if (_state.isDisposed) {
      throw StateError(
          'A PracticeEditController was used after being disposed.');
    }
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

  /// 生成字帖缩略图
  Future<Uint8List?> _generateThumbnail() async {
    _checkDisposed();

    if (_state.pages.isEmpty) {
      return null;
    }

    try {
      // 获取第一页作为缩略图
      final firstPage = _state.pages.first;

      // 缩略图尺寸
      const thumbWidth = 300.0;
      const thumbHeight = 400.0;

      // 临时进入预览模式
      bool wasInPreviewMode = false;
      if (_previewModeCallback != null) {
        // 假设当前不在预览模式
        wasInPreviewMode = false;

        // 切换到预览模式
        _previewModeCallback!(true);

        // 等待一帧，确保 RepaintBoundary 已经渲染
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 如果有画布 GlobalKey，使用 RepaintBoundary 捕获
      Uint8List? thumbnail;
      if (_canvasKey != null) {
        thumbnail = await captureFromRepaintBoundary(_canvasKey!);
      }

      // 恢复原来的预览模式状态
      if (_previewModeCallback != null && !wasInPreviewMode) {
        _previewModeCallback!(false);
      }

      // 如果成功捕获了缩略图，直接返回
      if (thumbnail != null) {
        return thumbnail;
      }

      // 使用 CanvasCapture 捕获预览模式下的页面
      thumbnail = await CanvasCapture.capturePracticePage(
        firstPage,
        width: thumbWidth,
        height: thumbHeight,
      );

      if (thumbnail != null) {
        return thumbnail;
      }

      // 如果 CanvasCapture 失败，尝试使用 ThumbnailGenerator 作为备选方案
      final fallbackThumbnail = await ThumbnailGenerator.generateThumbnail(
        firstPage,
        width: thumbWidth,
        height: thumbHeight,
        title: _practiceTitle,
      );

      return fallbackThumbnail;
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      return null;
    }
  }

  /// 初始化默认数据
  void _initDefaultData() {
    // 创建默认图层
    final defaultLayer = {
      'id': _uuid.v4(),
      'name': '图层1',
      'order': 0,
      'isVisible': true,
      'isLocked': false,
      'opacity': 1.0,
    };

    // 创建默认页面
    final defaultPage = {
      'id': _uuid.v4(),
      'name': '页面1',
      'index': 0,
      'width': 210.0, // A4纸宽度（毫米）
      'height': 297.0, // A4纸高度（毫米）
      'orientation': 'portrait', // 默认纵向
      'dpi': 300, // 默认DPI
      'background': {
        'type': 'color',
        'value': '#FFFFFF',
        'opacity': 1.0,
      },
      'elements': <Map<String, dynamic>>[],
      'layers': <Map<String, dynamic>>[defaultLayer], // 每个页面都有自己的图层
    };

    // 添加到状态中
    _state.pages.add(defaultPage);
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
