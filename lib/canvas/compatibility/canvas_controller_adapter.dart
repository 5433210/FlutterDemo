// filepath: lib/canvas/compatibility/canvas_controller_adapter.dart

import 'dart:math' as math;
import 'dart:ui' show Rect, Size, Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;

import '../core/commands/command_manager.dart';
import '../core/commands/element_commands.dart';
import '../core/interfaces/element_data.dart';
import 'canvas_state_adapter.dart';

/// 兼容层适配器 - 将旧的API适配到新的架构
class CanvasControllerAdapter extends ChangeNotifier {
  dynamic _stateManager;

  /// Page management functionality for Practice Edit integration

  /// Current page properties
  Map<String, dynamic>? _currentPageProperties;

  /// Canvas configuration
  Map<String, dynamic>? _canvasConfiguration;

  /// Page properties change callback
  VoidCallback? _onPagePropertiesChanged;

  /// Canvas configuration change callback
  VoidCallback? _onCanvasConfigurationChanged;

  CanvasControllerAdapter() {
    // 初始化时不创建状态管理器，等待attach方法被调用
  }

  /// 兼容旧API：是否可以重做
  bool get canRedo => _stateManager?.canRedo ?? false;

  /// 兼容旧API：是否可以撤销
  bool get canUndo => _stateManager?.canUndo ?? false;

  /// 获取Canvas配置
  Map<String, dynamic> get canvasConfiguration {
    return _canvasConfiguration ?? _getDefaultCanvasConfiguration();
  }

  /// 暴露命令管理器给新组件使用
  CommandManager get commandManager =>
      _stateManager?.commandManager ?? CommandManager();

  /// 兼容旧API：获取所有元素
  List<Map<String, dynamic>> get elements {
    debugPrint('🔍 elements getter called');
    if (_stateManager == null) {
      debugPrint('⚠️ 警告: _stateManager为null，返回空列表');
      return [];
    }

    try {
      final sortedElements = _stateManager.elementState.sortedElements;
      debugPrint('📊 Found ${sortedElements.length} elements in state');

      final result = sortedElements
          .map((element) => _elementToLegacyMap(element))
          .cast<Map<String, dynamic>>()
          .toList();

      debugPrint('📋 Returning ${result.length} elements');
      if (result.isNotEmpty) {
        debugPrint(
            '📋 Elements: ${result.map((e) => '${e['id']}(${e['type']})').join(', ')}');
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in elements getter: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// 获取当前页面属性
  Map<String, dynamic> get pageProperties {
    return _currentPageProperties ?? _getDefaultPageProperties();
  }

  /// 兼容旧API：获取选中的元素ID列表
  List<String> get selectedElementIds {
    if (_stateManager == null) {
      debugPrint('警告: _stateManager为null，返回空列表');
      return [];
    }
    return _stateManager.selectionState.selectedIds.toList();
  }

  /// 兼容旧API：获取状态管理器（为toolbar_adapter提供）
  dynamic get state => _stateManager;

  /// 暴露状态管理器给新组件使用
  dynamic get stateManager => _stateManager;

  void addElement(Map<String, dynamic> elementData) {
    debugPrint('🔧 addElement called with data: $elementData');
    // 确保_stateManager已初始化
    if (_stateManager == null) {
      debugPrint('❌ 错误: 添加元素前_stateManager未初始化');
      return;
    }

    try {
      debugPrint('🔄 Converting legacy map to element...');
      final element = _legacyMapToElement(elementData);
      debugPrint('✅ Element converted: ${element.id}, type: ${element.type}');

      // 对于文本元素，检查并记录重要属性
      if (element.type == 'text') {
        final hasText = element.properties.containsKey('text');
        final textValue = element.properties['text'] as String? ?? '未找到文本';
        debugPrint('📝 转换后的文本元素属性检查:');
        debugPrint('   - 直接text属性: ${hasText ? '存在' : '不存在'}');
        debugPrint('   - 文本内容: "$textValue"');
        debugPrint('   - 所有属性: ${element.properties.keys.join(', ')}');
      }

      // 检查_stateManager是否正确初始化并且可以访问underlying属性
      if (_stateManager is CanvasStateManagerAdapter) {
        debugPrint('🎯 Creating AddElementCommand...');
        final command = AddElementCommand(
          stateManager: _stateManager.underlying,
          element: element,
        );
        debugPrint('⚡ Executing command...');
        _stateManager.underlying.commandManager.execute(command);
        debugPrint('✅ Command executed successfully');

        // 验证元素是否真的被添加了
        final currentElements = _stateManager.elementState.sortedElements;
        debugPrint(
            '📊 Current elements count after add: ${currentElements.length}');
        if (currentElements.isNotEmpty) {
          debugPrint(
              '📋 Elements in state: ${currentElements.map((e) => '${e.id}(${e.type})').join(', ')}');
        }
      } else {
        debugPrint('❌ 错误: _stateManager类型不正确: ${_stateManager.runtimeType}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 添加元素时出错: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 兼容旧API：添加空集字元素在指定位置
  void addEmptyCollectionElementAt(double x, double y) {
    final element = {
      'id': 'collection_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'collection',
      'x': x,
      'y': y,
      'width': 400.0,
      'height': 200.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
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

    addElement(element);
  }

  /// 兼容旧API：添加空图片元素在指定位置
  void addEmptyImageElementAt(double x, double y) {
    final element = {
      'id': 'image_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'image',
      'x': x,
      'y': y,
      'width': 200.0,
      'height': 200.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'imageUrl': '',
        'fit': 'contain',
        'aspectRatio': 1.0,
      },
    };

    addElement(element);
  }

  /// 添加形状元素
  void addShapeElement(String shapeType, {double? x, double? y}) {
    final element = {
      'id': 'shape_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'shape',
      'x': x ?? 100.0,
      'y': y ?? 100.0,
      'width': 100.0,
      'height': 100.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'shapeType': shapeType, // rectangle, circle, triangle, etc.
        'fillColor': '#0066CC',
        'strokeColor': '#003366',
        'strokeWidth': 2.0,
        'cornerRadius': shapeType == 'rectangle' ? 8.0 : 0.0,
      },
    };

    addElement(element);
  }

  /// 兼容旧API：添加文本元素
  void addTextElement() {
    final element = {
      'id': 'text_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'text',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'isLocked': false,
      'isHidden': false,
      'content': {
        'text': '属性页\n输入文本',
        'fontFamily': 'sans-serif',
        'fontSize': 24.0,
        'fontColor': '#000000',
        'backgroundColor': '#FFFFFF',
        'textAlign': 'left',
        'verticalAlign': 'top',
        'writingMode': 'horizontal-l',
        'lineHeight': 1.2,
        'letterSpacing': 0.0,
        'padding': 8.0,
        'fontWeight': 'normal',
        'fontStyle': 'normal',
      },
    };

    addElement(element);
  }

  /// 对齐操作
  void alignElements(List<String> elementIds, String alignType) {
    debugPrint('📐 Aligning elements: $elementIds, type: $alignType');

    if (elementIds.length < 2) {
      debugPrint('⚠️ Need at least 2 elements to align');
      return;
    }

    if (_stateManager == null) return;

    try {
      final elements = elementIds
          .map((id) => _stateManager.elementState.getElementById(id))
          .where((element) => element != null)
          .cast<ElementData>()
          .toList();

      if (elements.isEmpty) return;

      switch (alignType) {
        case 'left':
          _alignLeft(elements);
          break;
        case 'center':
          _alignCenter(elements);
          break;
        case 'right':
          _alignRight(elements);
          break;
        case 'top':
          _alignTop(elements);
          break;
        case 'middle':
          _alignMiddle(elements);
          break;
        case 'bottom':
          _alignBottom(elements);
          break;
      }

      debugPrint('✅ Elements aligned successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error aligning elements: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 附加到画布
  void attach(dynamic stateManager) {
    assert(stateManager is CanvasStateManagerAdapter,
        'CanvasControllerAdapter requires a CanvasStateManagerAdapter');
    _stateManager = stateManager;
    _stateManager.addListener(() => notifyListeners());
  }

  /// 兼容旧API：清除选择
  void clearSelection() {
    debugPrint('🧹 clearSelection called');
    if (_stateManager == null) {
      debugPrint('⚠️ 警告: _stateManager为null，无法清除选择');
      return;
    }

    try {
      final newSelectionState = _stateManager.selectionState.clearSelection();
      _stateManager.updateSelectionState(newSelectionState);
      debugPrint('✅ Selection cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in clearSelection: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 兼容旧API：删除选中的元素
  void deleteSelectedElements() {
    if (_stateManager == null) {
      debugPrint('警告: _stateManager为null，无法删除元素');
      return;
    }
    if (_stateManager.selectionState.selectedIds.isEmpty) return;

    final command = DeleteElementsCommand(
      stateManager: _stateManager.underlying,
      elementIds: _stateManager.selectionState.selectedIds.toList(),
    );
    _stateManager.underlying.commandManager.execute(command);
  }

  /// 从画布分离
  void detach() {
    if (_stateManager != null) {
      _stateManager.removeListener(() => notifyListeners());
      _stateManager = null;
    }
  }

  /// 兼容旧API：退出选择模式
  void exitSelectMode() {
    // 清除选择
    clearSelection();
  }

  /// 批量操作：组合元素
  void groupElements(List<String> elementIds) {
    debugPrint('📦 Grouping elements: $elementIds');

    if (elementIds.length < 2) {
      debugPrint('⚠️ Need at least 2 elements to group');
      return;
    }

    if (_stateManager == null) {
      debugPrint('❌ StateManager not available for grouping');
      return;
    }

    try {
      // 获取所有要组合的元素
      final elements = elementIds
          .map((id) => _stateManager.elementState.getElementById(id))
          .where((element) => element != null)
          .cast<ElementData>()
          .toList();

      if (elements.length != elementIds.length) {
        debugPrint('⚠️ Some elements not found for grouping');
        return;
      }

      // 计算组合边界
      final bounds = _calculateGroupBounds(elements);

      // 创建组合元素
      final groupElement = {
        'id': 'group_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'group',
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
        'rotation': 0.0,
        'opacity': 1.0,
        'isLocked': false,
        'isHidden': false,
        'content': {
          'children': elementIds,
          'groupType': 'manual',
        },
      };

      // 添加组合元素
      addElement(groupElement);

      // 删除原始元素（它们现在是组合的一部分）
      for (final elementId in elementIds) {
        _deleteElementDirect(elementId);
      }

      debugPrint('✅ Elements grouped successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error grouping elements: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 兼容旧API：重做
  bool redo() => _stateManager?.redo() ?? false;

  /// 兼容旧API：选择元素
  void selectElement(String id, {bool addToSelection = false}) {
    debugPrint(
        '🎯 selectElement called with id: $id, addToSelection: $addToSelection');
    if (_stateManager == null) {
      debugPrint('⚠️ 警告: _stateManager为null，无法选择元素');
      return;
    }

    try {
      if (addToSelection) {
        // 添加到现有选择
        final currentSelection = _stateManager.selectionState.selectedIds;
        final newSelection = Set<String>.from(currentSelection)..add(id);
        final newState =
            _stateManager.selectionState.replaceSelection(newSelection.first);
        for (final elementId in newSelection.skip(1)) {
          newState.addToSelection(elementId);
        }
        _stateManager.updateSelectionState(newState);
      } else {
        // 替换选择（清除当前选择并选择新元素）
        _stateManager.selectElement(id);
      }

      // 验证选择结果
      final selectedIds = _stateManager.selectionState.selectedIds;
      debugPrint(
          '✅ Selection completed. Selected IDs: ${selectedIds.toList()}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in selectElement: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 设置Canvas配置变化回调
  void setCanvasConfigurationChangeCallback(VoidCallback? callback) {
    _onCanvasConfigurationChanged = callback;
  }

  /// 设置页面属性变化回调
  void setPagePropertiesChangeCallback(VoidCallback? callback) {
    _onPagePropertiesChanged = callback;
  }

  /// 兼容旧API：撤销
  bool undo() => _stateManager?.undo() ?? false;

  /// 批量操作：取消组合
  void ungroupElements(List<String> groupIds) {
    debugPrint('📦 Ungrouping elements: $groupIds');

    if (_stateManager == null) {
      debugPrint('❌ StateManager not available for ungrouping');
      return;
    }

    try {
      for (final groupId in groupIds) {
        final groupElement = _stateManager.elementState.getElementById(groupId);
        if (groupElement == null || groupElement.type != 'group') {
          debugPrint('⚠️ Element $groupId is not a group');
          continue;
        }

        // 获取组合中的子元素ID
        final childrenIds =
            groupElement.properties['content']?['children'] as List<String>?;
        if (childrenIds == null || childrenIds.isEmpty) {
          debugPrint('⚠️ Group $groupId has no children');
          continue;
        }

        // 恢复子元素（这里需要从某个地方恢复子元素的完整数据）
        // 实际实现中需要保存完整的子元素数据

        // 删除组合元素
        _deleteElementDirect(groupId);
      }

      debugPrint('✅ Elements ungrouped successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error ungrouping elements: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 更新Canvas配置
  void updateCanvasConfiguration(Map<String, dynamic> configuration) {
    debugPrint('🎨 Updating canvas configuration: ${configuration.keys}');

    _canvasConfiguration = Map.from(_canvasConfiguration ?? {})
      ..addAll(configuration);

    // 通知Canvas系统配置变化
    _notifyCanvasConfigurationChanged();

    _onCanvasConfigurationChanged?.call();
    notifyListeners();
  }

  /// 兼容旧API：更新元素
  void updateElement(String id, Map<String, dynamic> updates) {
    if (_stateManager == null) {
      debugPrint('警告: _stateManager为null，无法更新元素');
      return;
    }

    final currentElement = _stateManager.elementState.getElementById(id);
    if (currentElement == null) return;

    final elementMap = _elementToLegacyMap(currentElement);
    elementMap.addAll(updates);
    final updatedElement = _legacyMapToElement(elementMap);

    final command = UpdateElementCommand(
      stateManager: _stateManager.underlying,
      elementId: id,
      newElementData: updatedElement,
    );
    _stateManager.underlying.commandManager.execute(command);
  }

  /// 批量更新元素属性
  void updateMultipleElements(
      List<String> elementIds, Map<String, dynamic> updates) {
    debugPrint('🔧 Updating multiple elements: $elementIds with $updates');

    for (final elementId in elementIds) {
      updateElement(elementId, updates);
    }
  }

  /// 更新页面属性
  void updatePageProperties(Map<String, dynamic> properties) {
    debugPrint('📄 Updating page properties: ${properties.keys}');

    _currentPageProperties = Map.from(_currentPageProperties ?? {})
      ..addAll(properties);

    // 通知Canvas系统页面属性变化
    _notifyPagePropertiesChanged();

    _onPagePropertiesChanged?.call();
    notifyListeners();
  }

  void _alignBottom(List<ElementData> elements) {
    final bottomMost =
        elements.map((e) => e.bounds.bottom).reduce((a, b) => a > b ? a : b);
    for (final element in elements) {
      updateElement(element.id, {'y': bottomMost - element.bounds.height});
    }
  }

  void _alignCenter(List<ElementData> elements) {
    final centerX =
        elements.map((e) => e.bounds.center.dx).reduce((a, b) => (a + b) / 2);
    for (final element in elements) {
      updateElement(element.id, {'x': centerX - element.bounds.width / 2});
    }
  }

  /// 对齐方法实现
  void _alignLeft(List<ElementData> elements) {
    final leftMost =
        elements.map((e) => e.bounds.left).reduce((a, b) => a < b ? a : b);
    for (final element in elements) {
      updateElement(element.id, {'x': leftMost});
    }
  }

  void _alignMiddle(List<ElementData> elements) {
    final centerY =
        elements.map((e) => e.bounds.center.dy).reduce((a, b) => (a + b) / 2);
    for (final element in elements) {
      updateElement(element.id, {'y': centerY - element.bounds.height / 2});
    }
  }

  void _alignRight(List<ElementData> elements) {
    final rightMost =
        elements.map((e) => e.bounds.right).reduce((a, b) => a > b ? a : b);
    for (final element in elements) {
      updateElement(element.id, {'x': rightMost - element.bounds.width});
    }
  }

  void _alignTop(List<ElementData> elements) {
    final topMost =
        elements.map((e) => e.bounds.top).reduce((a, b) => a < b ? a : b);
    for (final element in elements) {
      updateElement(element.id, {'y': topMost});
    }
  }

  /// 计算组合边界
  Rect _calculateGroupBounds(List<ElementData> elements) {
    if (elements.isEmpty) return Rect.zero;

    double left = elements.first.bounds.left;
    double top = elements.first.bounds.top;
    double right = elements.first.bounds.right;
    double bottom = elements.first.bounds.bottom;

    for (final element in elements.skip(1)) {
      left = math.min(left, element.bounds.left);
      top = math.min(top, element.bounds.top);
      right = math.max(right, element.bounds.right);
      bottom = math.max(bottom, element.bounds.bottom);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 直接删除元素（内部使用）
  void _deleteElementDirect(String elementId) {
    if (_stateManager is CanvasStateManagerAdapter) {
      final command = DeleteElementsCommand(
        stateManager: _stateManager.underlying,
        elementIds: [elementId],
      );
      _stateManager.underlying.commandManager.execute(command);
    }
  }

  /// 将ElementData转换为legacy格式的Map
  Map<String, dynamic> _elementToLegacyMap(ElementData element) {
    return {
      'id': element.id,
      'type': element.type,
      'x': element.bounds.left,
      'y': element.bounds.top,
      'width': element.bounds.width,
      'height': element.bounds.height,
      'rotation': element.rotation,
      'opacity': element.opacity,
      'layerId': element.layerId,
      'isLocked': element.isLocked,
      'isVisible': element.visible,
      // Add other properties as needed based on element type
      ...element.properties,
    };
  }

  /// 获取默认Canvas配置
  Map<String, dynamic> _getDefaultCanvasConfiguration() {
    return {
      'size': const Size(800, 600),
      'backgroundColor': Colors.white,
      'showGrid': false,
      'gridSize': 20.0,
      'gridColor': const Color(0xFFE0E0E0),
      'enableGestures': true,
      'enablePerformanceMonitoring': true,
    };
  }

  /// 获取默认页面属性
  Map<String, dynamic> _getDefaultPageProperties() {
    return {
      'pageWidth': 800.0,
      'pageHeight': 600.0,
      'orientation': 'portrait',
      'dpi': 150.0,
      'backgroundColor': '#FFFFFF',
      'backgroundImageUrl': null,
      'gridVisible': false,
      'gridSize': 20.0,
      'gridColor': '#E0E0E0',
      'snapToGrid': false,
      'pageMargin': 20.0,
    };
  }

  /// 将legacy格式的Map转换为ElementData
  ElementData _legacyMapToElement(Map<String, dynamic> elementMap) {
    // 创建一个包含所有非标准属性的properties map
    final properties = Map<String, dynamic>.from(elementMap)
      ..removeWhere((key, value) => [
            'id',
            'type',
            'x',
            'y',
            'width',
            'height',
            'rotation',
            'opacity',
            'layerId',
            'isLocked',
            'isVisible',
            'isHidden',
            'content'  // Remove content but handle it separately
          ].contains(key));

    // 如果存在content对象，将其属性扁平化到根级别
    if (elementMap.containsKey('content') &&
        elementMap['content'] is Map<String, dynamic>) {
      final content = elementMap['content'] as Map<String, dynamic>;
      
      // 特别记录文本元素的内容
      if (elementMap['type'] == 'text' && content.containsKey('text')) {
        debugPrint('📝 Text element content found: "${content['text']}"');
        
        // 确保文本内容被正确地复制到properties中
        properties['text'] = content['text'];
        debugPrint('📝 Copied text content to properties: "${properties['text']}"');
      }

      // 处理特殊属性的映射，确保渲染器可以找到正确的属性
      if (content.containsKey('fontColor')) {
        properties['color'] = content['fontColor'];
        properties['fontColor'] = content['fontColor']; // 保留原属性以备兼容
        debugPrint('🎨 Mapping fontColor to color: ${content['fontColor']}');
      }

      // 将content中的所有属性添加到properties的根级别
      properties.addAll(content);

      // 记录日志以便调试
      debugPrint('🔄 扁平化元素content属性: ${content.keys.join(', ')}');
    }

    // 解析isHidden，确保visible设置正确
    final isHidden = elementMap['isHidden'] as bool? ?? false;
    final visible = !isHidden;
    debugPrint(
        '👁️ 元素可见性: ${elementMap['id']} - visible=$visible (isHidden=$isHidden)');

    // 确保文本元素的text属性存在于properties中
    if (elementMap['type'] == 'text') {
      if (!properties.containsKey('text') && properties.containsKey('content')) {
        // 这种情况不应该发生，因为我们已经扁平化了content
        // 但作为防御性编程，保留这个检查
        debugPrint('⚠️ 警告: 文本元素缺少text属性，尝试从content中提取');
      }
      
      // 最终检查和日志
      debugPrint('📝 最终文本元素属性:');
      debugPrint('   - text: ${properties['text']}');
      debugPrint('   - color/fontColor: ${properties['color'] ?? properties['fontColor']}');
      debugPrint('   - fontSize: ${properties['fontSize']}');
      debugPrint('   - 可见性: $visible');
    }

    return ElementData(
      id: elementMap['id'] as String,
      type: elementMap['type'] as String,
      bounds: Rect.fromLTWH(
        (elementMap['x'] as num?)?.toDouble() ?? 0.0,
        (elementMap['y'] as num?)?.toDouble() ?? 0.0,
        (elementMap['width'] as num?)?.toDouble() ?? 100.0,
        (elementMap['height'] as num?)?.toDouble() ?? 100.0,
      ),
      rotation: (elementMap['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (elementMap['opacity'] as num?)?.toDouble() ?? 1.0,
      layerId: elementMap['layerId'] as String? ?? '',
      locked: elementMap['isLocked'] as bool? ?? false,
      visible: visible,
      properties: properties,
    };
  }

  /// 通知Canvas配置变化
  void _notifyCanvasConfigurationChanged() {
    debugPrint('📢 Notifying canvas configuration changed');
    // 这里可以直接更新Canvas组件的配置
  }

  /// 通知页面属性变化
  void _notifyPagePropertiesChanged() {
    debugPrint('📢 Notifying page properties changed');
    // 这里可以更新Canvas的相关配置

    if (_currentPageProperties != null) {
      // 更新Canvas配置以反映页面属性变化
      final canvasConfig = Map<String, dynamic>.from(canvasConfiguration);

      // 更新画布尺寸
      if (_currentPageProperties!.containsKey('pageWidth') &&
          _currentPageProperties!.containsKey('pageHeight')) {
        canvasConfig['size'] = Size(
          (_currentPageProperties!['pageWidth'] as num).toDouble(),
          (_currentPageProperties!['pageHeight'] as num).toDouble(),
        );
      }

      // 更新背景色
      if (_currentPageProperties!.containsKey('backgroundColor')) {
        final colorString =
            _currentPageProperties!['backgroundColor'] as String;
        canvasConfig['backgroundColor'] = _parseColorFromString(colorString);
      }

      // 更新网格设置
      if (_currentPageProperties!.containsKey('gridVisible')) {
        canvasConfig['showGrid'] =
            _currentPageProperties!['gridVisible'] as bool;
      }
      if (_currentPageProperties!.containsKey('gridSize')) {
        canvasConfig['gridSize'] =
            (_currentPageProperties!['gridSize'] as num).toDouble();
      }
      if (_currentPageProperties!.containsKey('gridColor')) {
        final colorString = _currentPageProperties!['gridColor'] as String;
        canvasConfig['gridColor'] = _parseColorFromString(colorString);
      }

      _canvasConfiguration = canvasConfig;
    }
  }

  /// 解析颜色字符串
  Color _parseColorFromString(String colorString) {
    try {
      String color = colorString;
      if (color.startsWith('#')) {
        color = color.substring(1);
      }

      if (color.length == 6) {
        return Color(int.parse('FF$color', radix: 16));
      } else if (color.length == 8) {
        return Color(int.parse(color, radix: 16));
      }
    } catch (e) {
      debugPrint('⚠️ Failed to parse color: $colorString');
    }

    return Colors.white;
  }

  // ...existing code...
}
