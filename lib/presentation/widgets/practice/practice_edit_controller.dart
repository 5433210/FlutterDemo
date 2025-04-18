import 'package:flutter/material.dart';
import '../../../domain/models/practice/practice_element.dart';
import '../../../domain/models/practice/practice_page.dart';
import 'element_operations.dart';
import 'layer_operations.dart';
import 'page_operations.dart';
import 'practice_edit_state.dart';
import 'undo_redo_manager.dart';

/// 编辑控制器类
/// 包含控制编辑状态的方法
class PracticeEditController extends ChangeNotifier {
  // 状态
  PracticeEditState _state;
  
  // 撤销/重做管理器
  final UndoRedoManager _undoRedoManager = UndoRedoManager();
  
  // 构造函数
  PracticeEditController({PracticeEditState? state}) 
      : _state = state ?? PracticeEditState() {
    _initData();
  }
  
  // 获取状态
  PracticeEditState get state => _state;
  
  // 获取撤销/重做管理器
  UndoRedoManager get undoRedoManager => _undoRedoManager;
  
  // 初始化数据
  void _initData() {
    // 初始化图层
    _state.layers = LayerOperations.createDefaultLayers();
    
    // 初始化页面
    _state.pages = PageOperations.createDefaultPages();
  }
  
  // 添加文本元素
  void addTextElement() {
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }

    final defaultLayerId = LayerOperations.getDefaultLayerId(_state.layers);
    
    final newElement = ElementOperations.createTextElement(
      layerId: defaultLayerId,
    );
    
    final elements = _state.currentPageElements;
    elements.add(newElement);
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 选中新添加的元素
    _state.selectedElementIds = [newElement['id'] as String];
    _state.selectedElement = newElement;
    _state.hasUnsavedChanges = true;
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createAddElementOperation(newElement),
    );
    
    notifyListeners();
  }
  
  // 添加图片元素
  void addImageElement(String imageUrl) {
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }

    final defaultLayerId = LayerOperations.getDefaultLayerId(_state.layers);
    
    final newElement = ElementOperations.createImageElement(
      layerId: defaultLayerId,
      imageUrl: imageUrl,
    );
    
    final elements = _state.currentPageElements;
    elements.add(newElement);
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 选中新添加的元素
    _state.selectedElementIds = [newElement['id'] as String];
    _state.selectedElement = newElement;
    _state.hasUnsavedChanges = true;
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createAddElementOperation(newElement),
    );
    
    notifyListeners();
  }
  
  // 添加集字元素
  void addCollectionElement(String characters) {
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }

    final defaultLayerId = LayerOperations.getDefaultLayerId(_state.layers);
    
    final newElement = ElementOperations.createCollectionElement(
      layerId: defaultLayerId,
      characters: characters,
    );
    
    final elements = _state.currentPageElements;
    elements.add(newElement);
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 选中新添加的元素
    _state.selectedElementIds = [newElement['id'] as String];
    _state.selectedElement = newElement;
    _state.hasUnsavedChanges = true;
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createAddElementOperation(newElement),
    );
    
    notifyListeners();
  }
  
  // 删除选中的元素
  void deleteSelectedElements() {
    if (_state.selectedElementIds.isEmpty) return;
    
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }
    
    final elements = _state.currentPageElements;
    
    // 找出要删除的元素
    final elementsToDelete = elements
        .where((element) => _state.selectedElementIds.contains(element['id']))
        .toList();
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createDeleteElementOperation(elementsToDelete),
    );
    
    // 删除元素
    ElementOperations.deleteElements(elements, _state.selectedElementIds);
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 清除选择
    _state.selectedElementIds.clear();
    _state.selectedElement = null;
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 组合选中的元素
  void groupSelectedElements() {
    if (_state.selectedElementIds.length < 2) return;
    
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }
    
    final elements = _state.currentPageElements;
    
    // 找出要组合的元素
    final elementsToGroup = elements
        .where((element) => _state.selectedElementIds.contains(element['id']))
        .toList();
    
    if (elementsToGroup.isEmpty) return;
    
    // 创建组合
    final group = ElementOperations.createGroupElement(
      elements: elementsToGroup,
    );
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createGroupOperation(elementsToGroup, group),
    );
    
    // 删除原始元素
    ElementOperations.deleteElements(elements, _state.selectedElementIds);
    
    // 添加组合
    elements.add(group);
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 选中组合
    _state.selectedElementIds = [group['id'] as String];
    _state.selectedElement = group;
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 取消组合
  void ungroupSelectedElement() {
    if (_state.selectedElementIds.length != 1) return;
    
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }
    
    final elements = _state.currentPageElements;
    final groupId = _state.selectedElementIds.first;
    
    // 找出要取消组合的组
    final group = ElementOperations.findElementById(elements, groupId);
    
    if (group == null || group['type'] != 'group') return;
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createUngroupOperation(
        group, 
        (group['children'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      ),
    );
    
    // 取消组合
    final ungroupedElements = ElementOperations.ungroupElement(
      elements, 
      groupId,
    );
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 选中取消组合后的元素
    _state.selectedElementIds = ungroupedElements
        .map((e) => e['id'] as String)
        .toList();
    _updateSelectedElementProperties();
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 添加图层
  void addLayer() {
    // 取消选择其他图层
    for (var layer in _state.layers) {
      layer['selected'] = false;
    }
    
    // 添加新图层
    final newLayer = LayerOperations.createLayer(selected: true);
    _state.layers.add(newLayer);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 删除图层
  void deleteLayer(int index) {
    if (index < 0 || index >= _state.layers.length) return;
    
    LayerOperations.deleteLayer(_state.layers, index);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 删除所有图层
  void deleteAllLayers() {
    _state.layers.clear();
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 选择图层
  void selectLayer(int index) {
    LayerOperations.selectLayer(_state.layers, index);
    
    notifyListeners();
  }
  
  // 更改图层可见性
  void setLayerVisibility(int index, bool visible) {
    LayerOperations.setLayerVisibility(_state.layers, index, visible);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 更改图层锁定状态
  void setLayerLocked(int index, bool locked) {
    LayerOperations.setLayerLocked(_state.layers, index, locked);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 重命名图层
  void renameLayer(int index, String newName) {
    LayerOperations.renameLayer(_state.layers, index, newName);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    LayerOperations.reorderLayers(_state.layers, oldIndex, newIndex);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 显示所有图层
  void showAllLayers() {
    LayerOperations.showAllLayers(_state.layers);
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 添加页面
  void addPage() {
    PageOperations.addPage(_state.pages);
    
    // 切换到新页面
    _state.currentPageIndex = _state.pages.length - 1;
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 删除页面
  void deletePage() {
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }
    
    PageOperations.deletePage(_state.pages, _state.currentPageIndex);
    
    // 调整当前页索引
    if (_state.pages.isEmpty) {
      _state.currentPageIndex = 0;
    } else if (_state.currentPageIndex >= _state.pages.length) {
      _state.currentPageIndex = _state.pages.length - 1;
    }
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 选择页面
  void selectPage(int index) {
    if (index < 0 || index >= _state.pages.length) return;
    
    _state.currentPageIndex = index;
    
    // 清除选择
    _state.selectedElementIds.clear();
    _state.selectedElement = null;
    
    notifyListeners();
  }
  
  // 更新页面属性
  void updatePageProperties(PracticePage updatedPage) {
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }
    
    PageOperations.updatePageProperties(
      _state.pages, 
      _state.currentPageIndex, 
      updatedPage,
    );
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 选择元素
  void selectElement(String id, {bool isMultiSelect = false}) {
    if (!isMultiSelect) {
      // 单选模式，清除之前的选择
      _state.selectedElementIds.clear();
    }
    
    if (_state.selectedElementIds.contains(id)) {
      // 如果已经选中，则取消选中
      _state.selectedElementIds.remove(id);
    } else {
      // 否则选中这个元素
      _state.selectedElementIds.add(id);
    }
    
    // 更新属性面板的数据
    _updateSelectedElementProperties();
    
    notifyListeners();
  }
  
  // 更新元素属性
  void updateElementProperties(String id, Map<String, dynamic> properties) {
    if (_state.pages.isEmpty || _state.currentPageIndex >= _state.pages.length) {
      return;
    }
    
    final elements = _state.currentPageElements;
    
    // 找出要更新的元素
    final oldElement = ElementOperations.findElementById(elements, id);
    
    if (oldElement == null) return;
    
    // 添加撤销操作
    _undoRedoManager.addOperation(
      UndoRedoManager.createUpdateElementOperation(
        oldElement, 
        {...oldElement, ...properties},
      ),
    );
    
    // 更新元素属性
    ElementOperations.updateElementProperties(elements, id, properties);
    
    // 更新当前页面的元素
    _state.pages[_state.currentPageIndex]['elements'] = elements;
    
    // 更新选中元素
    if (_state.selectedElementIds.length == 1 && _state.selectedElementIds.first == id) {
      _state.selectedElement = ElementOperations.findElementById(elements, id);
    }
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 更新元素属性（从PracticeElement对象）
  void updateElementFromPracticeElement(PracticeElement updatedElement) {
    final elementId = updatedElement.id;
    final updatedMap = updatedElement.toMap();
    
    updateElementProperties(elementId, updatedMap);
  }
  
  // 切换网格显示
  void toggleGrid() {
    _state.gridVisible = !_state.gridVisible;
    
    notifyListeners();
  }
  
  // 切换页面缩略图可见性
  void togglePageThumbnails() {
    _state.isPageThumbnailsVisible = !_state.isPageThumbnailsVisible;
    
    notifyListeners();
  }
  
  // 切换吸附功能
  void toggleSnap(bool enabled) {
    _state.snapEnabled = enabled;
    
    notifyListeners();
  }
  
  // 撤销操作
  void undo() {
    if (!_undoRedoManager.canUndo) return;
    
    final operation = _undoRedoManager.undo();
    
    if (operation == null) return;
    
    // 根据操作类型执行撤销
    switch (operation.type) {
      case OperationType.addElement:
        // 撤销添加元素 -> 删除元素
        final element = operation.data['element'] as Map<String, dynamic>;
        final elements = _state.currentPageElements;
        ElementOperations.deleteElements(elements, [element['id'] as String]);
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.deleteElement:
        // 撤销删除元素 -> 添加元素
        final elements = _state.currentPageElements;
        final deletedElements = operation.previousData['elements'] as List<dynamic>;
        elements.addAll(deletedElements.map((e) => e as Map<String, dynamic>));
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.updateElement:
        // 撤销更新元素 -> 恢复旧属性
        final oldElement = operation.previousData['element'] as Map<String, dynamic>;
        final elements = _state.currentPageElements;
        ElementOperations.updateElementProperties(
          elements, 
          oldElement['id'] as String, 
          oldElement,
        );
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.group:
        // 撤销组合 -> 取消组合
        final group = operation.data['group'] as Map<String, dynamic>;
        final originalElements = operation.previousData['elements'] as List<dynamic>;
        final elements = _state.currentPageElements;
        ElementOperations.deleteElements(elements, [group['id'] as String]);
        elements.addAll(originalElements.map((e) => e as Map<String, dynamic>));
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.ungroup:
        // 撤销取消组合 -> 重新组合
        final group = operation.previousData['group'] as Map<String, dynamic>;
        final ungroupedElements = operation.data['elements'] as List<dynamic>;
        final elements = _state.currentPageElements;
        for (final element in ungroupedElements) {
          ElementOperations.deleteElements(
            elements, 
            [(element as Map<String, dynamic>)['id'] as String],
          );
        }
        elements.add(group);
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      default:
        // 其他操作类型暂不处理
        break;
    }
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 重做操作
  void redo() {
    if (!_undoRedoManager.canRedo) return;
    
    final operation = _undoRedoManager.redo();
    
    if (operation == null) return;
    
    // 根据操作类型执行重做
    switch (operation.type) {
      case OperationType.addElement:
        // 重做添加元素
        final element = operation.data['element'] as Map<String, dynamic>;
        final elements = _state.currentPageElements;
        elements.add(element);
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.deleteElement:
        // 重做删除元素
        final elementIds = operation.data['elementIds'] as List<dynamic>;
        final elements = _state.currentPageElements;
        ElementOperations.deleteElements(
          elements, 
          elementIds.map((e) => e as String).toList(),
        );
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.updateElement:
        // 重做更新元素
        final newElement = operation.data['element'] as Map<String, dynamic>;
        final elements = _state.currentPageElements;
        ElementOperations.updateElementProperties(
          elements, 
          newElement['id'] as String, 
          newElement,
        );
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.group:
        // 重做组合
        final group = operation.data['group'] as Map<String, dynamic>;
        final originalElements = operation.previousData['elements'] as List<dynamic>;
        final elements = _state.currentPageElements;
        for (final element in originalElements) {
          ElementOperations.deleteElements(
            elements, 
            [(element as Map<String, dynamic>)['id'] as String],
          );
        }
        elements.add(group);
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      case OperationType.ungroup:
        // 重做取消组合
        final group = operation.previousData['group'] as Map<String, dynamic>;
        final ungroupedElements = operation.data['elements'] as List<dynamic>;
        final elements = _state.currentPageElements;
        ElementOperations.deleteElements(elements, [group['id'] as String]);
        elements.addAll(ungroupedElements.map((e) => e as Map<String, dynamic>));
        _state.pages[_state.currentPageIndex]['elements'] = elements;
        break;
        
      default:
        // 其他操作类型暂不处理
        break;
    }
    
    _state.hasUnsavedChanges = true;
    
    notifyListeners();
  }
  
  // 更新选中元素的属性
  void _updateSelectedElementProperties() {
    if (_state.selectedElementIds.isEmpty) {
      _state.selectedElement = null;
      return;
    }
    
    if (_state.selectedElementIds.length == 1) {
      // 单选
      final id = _state.selectedElementIds.first;
      final elements = _state.currentPageElements;
      final element = ElementOperations.findElementById(elements, id);
      if (element != null) {
        _state.selectedElement = element;
      }
    } else {
      // 多选状态处理
      _state.selectedElement = null;
    }
  }
}
