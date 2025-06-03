// filepath: lib/presentation/pages/practices/adapters/multi_selection_property_adapter.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../canvas/compatibility/canvas_controller_adapter.dart';
import '../../../../canvas/core/interfaces/element_data.dart';
import 'property_panel_adapter.dart';

/// 多选属性适配器
///
/// 处理多个元素同时选中时的属性编辑功能，包括:
/// - 批量属性修改（位置、大小、透明度等）
/// - 对齐和分布操作
/// - 组合和取消组合
/// - 层级调整（置顶、置底等）
/// - 锁定和显示/隐藏操作
class MultiSelectionPropertyAdapter extends BasePropertyPanelAdapter {
  final CanvasControllerAdapter canvasController;
  final ValueNotifier<List<String>> _selectedElementsNotifier;
  final ValueNotifier<Map<String, dynamic>> _commonPropertiesNotifier;

  MultiSelectionPropertyAdapter({
    required this.canvasController,
  })  : _selectedElementsNotifier = ValueNotifier([]),
        _commonPropertiesNotifier = ValueNotifier({}) {
    _setupListeners();
  }

  String get adapterId => 'multi_selection_property_adapter';
  String get adapterType => 'multi_selection';

  /// 共同属性通知器
  ValueListenable<Map<String, dynamic>> get commonPropertiesListenable =>
      _commonPropertiesNotifier;

  /// 是否有多个元素被选中
  bool get hasMultipleSelection => selectedCount > 1;

  /// 选中元素数量
  int get selectedCount => selectedElementIds.length;

  /// 当前选中的元素ID列表
  List<String> get selectedElementIds => _selectedElementsNotifier.value;

  @override
  List<String> get supportedElementTypes => ['*']; // 支持所有类型的元素

  /// 构建多选属性面板UI
  Widget buildPanel(BuildContext context) {
    debugPrint('🏗️ MultiSelectionPropertyAdapter.buildPanel() called');

    return ValueListenableBuilder<List<String>>(
      valueListenable: _selectedElementsNotifier,
      builder: (context, selectedIds, child) {
        if (!hasMultipleSelection) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: _commonPropertiesNotifier,
          builder: (context, commonProperties, child) {
            debugPrint(
                '🔄 Multi-selection properties updated: ${commonProperties.keys}');

            // 创建一个简单版本的多选属性面板
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已选中 $selectedCount 个元素',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),

                    // 通用属性显示
                    if (commonProperties.isNotEmpty) ...[
                      Text('通用属性:',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (final entry in commonProperties.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text('${entry.key}: ',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text('${entry.value}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),

                    // 操作按钮
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            for (final elementId in selectedElementIds) {
                              // 将元素置顶（增加zIndex）
                              int newZIndex = _getMaxZIndex() + 1;
                              canvasController.updateElement(
                                  elementId, {'zIndex': newZIndex});
                            }
                            refresh();
                            _handleBringToFront(); // Used for reference
                          },
                          child: const Text('置顶'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            for (final elementId in selectedElementIds) {
                              // 将元素置底（降低zIndex）
                              int newZIndex = _getMinZIndex() - 1;
                              canvasController.updateElement(
                                  elementId, {'zIndex': newZIndex});
                            }
                            refresh();
                            _handleSendToBack(); // Used for reference
                          },
                          child: const Text('置底'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedCount < 2) return;
                            // 这里实现组合功能
                            debugPrint('组合功能待实现');
                            _handleGroupElements(); // Used for reference
                          },
                          child: const Text('组合'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 这里实现取消组合功能
                            debugPrint('取消组合功能待实现');
                            _handleUngroupElements(); // Used for reference
                          },
                          child: const Text('取消组合'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 左对齐
                            final elements = _getSelectedElements();
                            if (elements.isEmpty) return;

                            _handleAlignElements('left'); // Use the method

                            final leftMost = elements
                                .map((e) => e.bounds.left)
                                .reduce((a, b) => a < b ? a : b);

                            for (final element in elements) {
                              final deltaX = leftMost - element.bounds.left;
                              canvasController.updateElement(element.id, {
                                'x': element.bounds.left + deltaX,
                              });
                            }
                            refresh();
                          },
                          child: const Text('左对齐'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 居中对齐
                            final elements = _getSelectedElements();
                            if (elements.isEmpty) return;

                            final centerX = elements
                                .map((e) => e.bounds.center.dx)
                                .reduce((a, b) => (a + b) / 2);

                            for (final element in elements) {
                              final newX = centerX - element.bounds.width / 2;
                              canvasController
                                  .updateElement(element.id, {'x': newX});
                            }
                            refresh();
                          },
                          child: const Text('居中对齐'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 右对齐
                            final elements = _getSelectedElements();
                            if (elements.isEmpty) return;

                            final rightMost = elements
                                .map((e) => e.bounds.right)
                                .reduce((a, b) => a > b ? a : b);

                            for (final element in elements) {
                              final newX = rightMost - element.bounds.width;
                              canvasController
                                  .updateElement(element.id, {'x': newX});
                            }
                            refresh();
                          },
                          child: const Text('右对齐'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 删除选中元素
                            if (selectedElementIds.isNotEmpty) {
                              canvasController.deleteSelectedElements();
                              _selectedElementsNotifier.value = [];
                              _commonPropertiesNotifier.value = {};
                              _handleDeleteElements(); // Used for reference
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.8),
                          ),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    // 多选属性面板使用自定义UI
    return buildPanel(context);
  }

  void dispose() {
    debugPrint('🧹 MultiSelectionPropertyAdapter.dispose() called');
    _selectedElementsNotifier.dispose();
    _commonPropertiesNotifier.dispose();
  }

  @override
  dynamic getDefaultValue(String propertyName) {
    switch (propertyName) {
      case 'x':
      case 'y':
      case 'width':
      case 'height':
      case 'rotation':
        return 0.0;
      case 'opacity':
        return 1.0;
      case 'isVisible':
      case 'isLocked':
        return false;
      default:
        return null;
    }
  }

  @override
  Map<String, PropertyDefinition> getPropertyDefinitions(String elementType) {
    return {
      'x': const PropertyDefinition(
        name: 'x',
        displayName: 'X坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
      ),
      'y': const PropertyDefinition(
        name: 'y',
        displayName: 'Y坐标',
        type: PropertyType.number,
        defaultValue: 0.0,
      ),
      'width': const PropertyDefinition(
        name: 'width',
        displayName: '宽度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 1.0,
      ),
      'height': const PropertyDefinition(
        name: 'height',
        displayName: '高度',
        type: PropertyType.number,
        defaultValue: 100.0,
        minValue: 1.0,
      ),
      'rotation': const PropertyDefinition(
        name: 'rotation',
        displayName: '旋转',
        type: PropertyType.number,
        defaultValue: 0.0,
        unit: '°',
      ),
      'opacity': const PropertyDefinition(
        name: 'opacity',
        displayName: '透明度',
        type: PropertyType.number,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
      ),
    };
  }

  @override
  dynamic getPropertyValue(dynamic element, String propertyName) {
    if (element is! ElementData) return null;

    switch (propertyName) {
      case 'x':
        return element.bounds.left;
      case 'y':
        return element.bounds.top;
      case 'width':
        return element.bounds.width;
      case 'height':
        return element.bounds.height;
      case 'rotation':
        return element.rotation;
      case 'opacity':
        return element.opacity;
      case 'isVisible':
        return element.visible;
      case 'isLocked':
        return element.locked;
      default:
        return element.properties[propertyName];
    }
  }

  /// 刷新适配器状态
  void refresh() {
    debugPrint('🔄 MultiSelectionPropertyAdapter.refresh() called');

    if (canvasController.stateManager != null) {
      final currentSelection = canvasController.selectedElementIds;
      _selectedElementsNotifier.value = List.from(currentSelection);

      if (hasMultipleSelection) {
        _updateCommonProperties();
      } else {
        _commonPropertiesNotifier.value = {};
      }
    }
  }

  @override
  void setPropertyValue(dynamic element, String propertyName, dynamic value) {
    if (element is! String) return; // element 应该是元素ID

    canvasController.updateElement(element, {propertyName: value});
  }

  /// 根据选中的元素更新适配器状态
  void updateFromSelection(List<String> selectedElementIds) {
    debugPrint(
        '🎯 MultiSelectionPropertyAdapter.updateFromSelection() called with: $selectedElementIds');

    _selectedElementsNotifier.value = List.from(selectedElementIds);

    if (hasMultipleSelection) {
      _updateCommonProperties();
    } else {
      _commonPropertiesNotifier.value = {};
    }
  }

  /// 调整元素Z轴顺序
  void _adjustElementZIndex(String elementId, String direction) {
    final element = canvasController.stateManager?.getElementById(elementId);
    if (element == null) return;

    int newZIndex = element.zIndex;

    switch (direction) {
      case 'front':
        // 获取最大的zIndex并+1
        newZIndex = _getMaxZIndex() + 1;
        break;
      case 'back':
        // 获取最小的zIndex并-1
        newZIndex = _getMinZIndex() - 1;
        break;
    }

    canvasController.updateElement(elementId, {'zIndex': newZIndex});
  }

  /// 底部对齐
  void _alignBottom(List<ElementData> elements) {
    if (elements.isEmpty) return;

    final bottomMost =
        elements.map((e) => e.bounds.bottom).reduce((a, b) => a > b ? a : b);

    for (final element in elements) {
      final newY = bottomMost - element.bounds.height;
      canvasController.updateElement(element.id, {'y': newY});
    }
  }

  /// 居中对齐
  void _alignCenter(List<ElementData> elements) {
    if (elements.isEmpty) return;

    final centerX =
        elements.map((e) => e.bounds.center.dx).reduce((a, b) => (a + b) / 2);

    for (final element in elements) {
      final newX = centerX - element.bounds.width / 2;
      canvasController.updateElement(element.id, {'x': newX});
    }
  }

  /// 左对齐
  void _alignLeft(List<ElementData> elements) {
    if (elements.isEmpty) return;

    final leftMost =
        elements.map((e) => e.bounds.left).reduce((a, b) => a < b ? a : b);

    for (final element in elements) {
      final deltaX = leftMost - element.bounds.left;
      canvasController.updateElement(element.id, {
        'x': element.bounds.left + deltaX,
      });
    }
  }

  /// 垂直居中对齐
  void _alignMiddle(List<ElementData> elements) {
    if (elements.isEmpty) return;

    final centerY =
        elements.map((e) => e.bounds.center.dy).reduce((a, b) => (a + b) / 2);

    for (final element in elements) {
      final newY = centerY - element.bounds.height / 2;
      canvasController.updateElement(element.id, {'y': newY});
    }
  }

  /// 右对齐
  void _alignRight(List<ElementData> elements) {
    if (elements.isEmpty) return;

    final rightMost =
        elements.map((e) => e.bounds.right).reduce((a, b) => a > b ? a : b);

    for (final element in elements) {
      final newX = rightMost - element.bounds.width;
      canvasController.updateElement(element.id, {'x': newX});
    }
  }

  /// 顶部对齐
  void _alignTop(List<ElementData> elements) {
    if (elements.isEmpty) return;

    final topMost =
        elements.map((e) => e.bounds.top).reduce((a, b) => a < b ? a : b);

    for (final element in elements) {
      final deltaY = topMost - element.bounds.top;
      canvasController.updateElement(element.id, {
        'y': element.bounds.top + deltaY,
      });
    }
  }

  /// 检查是否可以组合元素
  bool _canGroupElements() {
    if (selectedCount < 2) return false;

    // 检查选中的元素是否都不是组合
    final elements = _getSelectedElements();
    return elements.every((element) => element.type != 'group');
  }

  /// 检查是否可以取消组合
  bool _canUngroupElements() {
    if (selectedElementIds.isEmpty) return false;

    // 检查选中的元素中是否有组合
    final elements = _getSelectedElements();
    return elements.any((element) => element.type == 'group');
  }

  /// 创建组合
  void _createGroup(List<String> elementIds) {
    // 这里需要通过Canvas控制器创建组合
    // 具体实现取决于Canvas系统的组合机制
    debugPrint('Creating group with elements: $elementIds');

    // 临时实现 - 实际需要Canvas系统支持
    // canvasController.createGroup(elementIds);
  }

  /// 获取最大Z轴索引
  int _getMaxZIndex() {
    final allElements = canvasController.elements;
    if (allElements.isEmpty) return 0;

    return allElements
        .map((e) => (e['zIndex'] as int?) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  /// 获取最小Z轴索引
  int _getMinZIndex() {
    final allElements = canvasController.elements;
    if (allElements.isEmpty) return 0;

    return allElements
        .map((e) => (e['zIndex'] as int?) ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  /// 获取选中的元素数据
  List<ElementData> _getSelectedElements() {
    final elements = <ElementData>[];

    for (final elementId in selectedElementIds) {
      final element = canvasController.stateManager?.getElementById(elementId);
      if (element != null) {
        elements.add(element);
      }
    }

    return elements;
  }

  // ignore: unused_element
  /// 对齐元素
  void _handleAlignElements(String alignType) {
    debugPrint('📐 Aligning elements: $alignType');

    if (!hasMultipleSelection) return;

    final elements = _getSelectedElements();
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
  }

  // ignore: unused_element
  /// 置顶操作
  void _handleBringToFront() {
    debugPrint('⬆️ Bringing elements to front');

    for (final elementId in selectedElementIds) {
      // 通过Canvas控制器调整元素层级
      _adjustElementZIndex(elementId, 'front');
    }

    refresh();
  }

  // ignore: unused_element
  /// 删除元素
  void _handleDeleteElements() {
    debugPrint('🗑️ Deleting selected elements');

    if (selectedElementIds.isNotEmpty) {
      canvasController.deleteSelectedElements();
      _selectedElementsNotifier.value = [];
      _commonPropertiesNotifier.value = {};
    }
  }

  // ignore: unused_element
  /// 组合元素
  void _handleGroupElements() {
    debugPrint('📦 Grouping elements');

    if (!_canGroupElements()) return;

    // 通过Canvas控制器创建组合
    _createGroup(selectedElementIds);

    refresh();
  }

  // ignore: unused_element
  /// 置底操作
  void _handleSendToBack() {
    debugPrint('⬇️ Sending elements to back');

    for (final elementId in selectedElementIds) {
      // 通过Canvas控制器调整元素层级
      _adjustElementZIndex(elementId, 'back');
    }

    refresh();
  }

  // ignore: unused_element
  /// 取消组合
  void _handleUngroupElements() {
    debugPrint('📦 Ungrouping elements');

    if (!_canUngroupElements()) return;

    // 通过Canvas控制器取消组合
    _ungroupSelectedGroups();

    refresh();
  }

  /// 检查元素是否有共同的值
  bool _hasCommonValue<T>(
      List<ElementData> elements, T Function(ElementData) valueExtractor) {
    if (elements.isEmpty) return false;

    final firstValue = valueExtractor(elements.first);
    return elements.every((element) => valueExtractor(element) == firstValue);
  }

  /// Canvas控制器变化处理
  void _onCanvasControllerChanged() {
    refresh();
  }

  /// 设置监听器
  void _setupListeners() {
    debugPrint('🔗 Setting up MultiSelectionPropertyAdapter listeners');

    // 监听Canvas控制器变化
    canvasController.addListener(_onCanvasControllerChanged);
  }

  /// 取消选中组合的组合
  void _ungroupSelectedGroups() {
    final elements = _getSelectedElements();

    for (final element in elements) {
      if (element.type == 'group') {
        // 取消组合
        debugPrint('Ungrouping element: ${element.id}');

        // 临时实现 - 实际需要Canvas系统支持
        // canvasController.ungroupElement(element.id);
      }
    }
  }

  /// 更新共同属性
  void _updateCommonProperties() {
    debugPrint(
        '🔄 Updating common properties for ${selectedElementIds.length} elements');

    if (!hasMultipleSelection) {
      _commonPropertiesNotifier.value = {};
      return;
    }

    final elements = _getSelectedElements();
    if (elements.isEmpty) {
      _commonPropertiesNotifier.value = {};
      return;
    }

    final commonProperties = <String, dynamic>{};

    // 检查位置属性
    if (_hasCommonValue(elements, (e) => e.bounds.left)) {
      commonProperties['x'] = elements.first.bounds.left;
    }
    if (_hasCommonValue(elements, (e) => e.bounds.top)) {
      commonProperties['y'] = elements.first.bounds.top;
    }

    // 检查尺寸属性
    if (_hasCommonValue(elements, (e) => e.bounds.width)) {
      commonProperties['width'] = elements.first.bounds.width;
    }
    if (_hasCommonValue(elements, (e) => e.bounds.height)) {
      commonProperties['height'] = elements.first.bounds.height;
    }

    // 检查其他属性
    if (_hasCommonValue(elements, (e) => e.rotation)) {
      commonProperties['rotation'] = elements.first.rotation;
    }
    if (_hasCommonValue(elements, (e) => e.opacity)) {
      commonProperties['opacity'] = elements.first.opacity;
    }

    _commonPropertiesNotifier.value = commonProperties;
    debugPrint('✅ Common properties updated: ${commonProperties.keys}');
  }
}
