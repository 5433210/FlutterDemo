import 'package:charasgem/canvas/compatibility/canvas_controller_adapter.dart';
import 'package:charasgem/canvas/compatibility/canvas_state_adapter.dart';
import 'package:charasgem/canvas/core/canvas_state_manager.dart';
import 'package:charasgem/canvas/core/interfaces/layer_data.dart';
import 'package:charasgem/canvas/ui/toolbar/tool_state_manager.dart';
import 'package:charasgem/canvas/ui/toolbar/toolbar_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canvas兼容层测试
///
/// 测试Phase 2.3的核心兼容层功能：
/// 1. CanvasStateManagerAdapter的基本功能
/// 2. CanvasControllerAdapter的兼容API
/// 3. ToolbarAdapter的集成
void main() {
  group('Canvas Compatibility Layer Tests', () {
    late CanvasStateManager coreStateManager;
    late CanvasStateManagerAdapter stateAdapter;
    late CanvasControllerAdapter controllerAdapter;
    late ToolStateManager toolStateManager;
    late ToolbarAdapter toolbarAdapter;
    setUp(() {
      // 创建核心状态管理器
      coreStateManager = CanvasStateManager();

      // 创建兼容适配器
      stateAdapter = CanvasStateManagerAdapter(coreStateManager);

      // 创建默认图层
      const defaultLayer = LayerData(
        id: 'default',
        name: 'Default Layer',
        visible: true,
        locked: false,
        opacity: 1.0,
        blendMode: 'normal',
      );
      coreStateManager.createLayer(defaultLayer);
      coreStateManager.selectLayer('default');

      // 创建控制器适配器
      controllerAdapter = CanvasControllerAdapter();
      controllerAdapter.attach(stateAdapter);

      // 创建工具栏相关组件
      toolStateManager = ToolStateManager();
      toolbarAdapter = ToolbarAdapter(
        stateManager: stateAdapter,
        toolStateManager: toolStateManager,
        controllerAdapter: controllerAdapter,
      );
    });

    tearDown(() {
      controllerAdapter.detach();
    });

    test('CanvasStateManagerAdapter - Basic functionality', () {
      // 测试基本属性访问
      expect(stateAdapter.canUndo, false);
      expect(stateAdapter.canRedo, false);
      expect(stateAdapter.selectedElements, isEmpty);
      expect(stateAdapter.selectableElements, isEmpty);
    });

    test('CanvasControllerAdapter - Add element functionality', () {
      // 测试添加元素
      expect(controllerAdapter.elements, isEmpty);

      // 添加文本元素
      controllerAdapter.addTextElement();

      // 验证元素已添加
      expect(controllerAdapter.elements, hasLength(1));
      expect(controllerAdapter.elements.first['type'], 'text');
    });

    test('CanvasControllerAdapter - Add image element functionality', () {
      // 测试添加图片元素
      controllerAdapter.addEmptyImageElementAt(100.0, 200.0);

      // 验证元素已添加且位置正确
      expect(controllerAdapter.elements, hasLength(1));
      final element = controllerAdapter.elements.first;
      expect(element['type'], 'image');
      expect(element['x'], 100.0);
      expect(element['y'], 200.0);
    });

    test('CanvasControllerAdapter - Add collection element functionality', () {
      // 测试添加集字元素
      controllerAdapter.addEmptyCollectionElementAt(50.0, 75.0);

      // 验证元素已添加且位置正确
      expect(controllerAdapter.elements, hasLength(1));
      final element = controllerAdapter.elements.first;
      expect(element['type'], 'collection');
      expect(element['x'], 50.0);
      expect(element['y'], 75.0);
    });

    test('CanvasControllerAdapter - Selection functionality', () {
      // 添加一个元素进行选择测试
      controllerAdapter.addTextElement();
      expect(controllerAdapter.elements, hasLength(1));

      final elementId = controllerAdapter.elements.first['id'] as String;

      // 测试选择元素
      controllerAdapter.selectElement(elementId);
      expect(controllerAdapter.selectedElementIds, contains(elementId));

      // 测试清除选择
      controllerAdapter.clearSelection();
      expect(controllerAdapter.selectedElementIds, isEmpty);

      // 测试退出选择模式
      controllerAdapter.exitSelectMode();
      expect(controllerAdapter.selectedElementIds, isEmpty);
    });

    test('CanvasControllerAdapter - Undo/Redo functionality', () {
      // 初始状态
      expect(controllerAdapter.canUndo, false);
      expect(controllerAdapter.canRedo, false);

      // 添加元素
      controllerAdapter.addTextElement();
      expect(controllerAdapter.canUndo, true);
      expect(controllerAdapter.canRedo, false);

      // 撤销
      final undoResult = controllerAdapter.undo();
      expect(undoResult, true);
      expect(controllerAdapter.elements, isEmpty);
      expect(controllerAdapter.canUndo, false);
      expect(controllerAdapter.canRedo, true);

      // 重做
      final redoResult = controllerAdapter.redo();
      expect(redoResult, true);
      expect(controllerAdapter.elements, hasLength(1));
      expect(controllerAdapter.canUndo, true);
      expect(controllerAdapter.canRedo, false);
    });

    test('CanvasControllerAdapter - Delete functionality', () {
      // 添加并选择元素
      controllerAdapter.addTextElement();
      final elementId = controllerAdapter.elements.first['id'] as String;
      controllerAdapter.selectElement(elementId);

      // 删除选中的元素
      controllerAdapter.deleteSelectedElements();
      expect(controllerAdapter.elements, isEmpty);
      expect(controllerAdapter.selectedElementIds, isEmpty);
    });

    test('ToolbarAdapter - Basic integration', () {
      // 测试工具栏适配器基本功能
      expect(toolbarAdapter.currentTool, isNotNull);

      // 测试工具变更
      final initialTool = toolbarAdapter.currentTool;

      // 这里我们只测试适配器是否正确初始化
      // 更复杂的工具切换测试需要完整的UI测试环境
      expect(toolbarAdapter, isNotNull);
      expect(toolbarAdapter.currentTool, equals(initialTool));
    });

    test('CanvasControllerAdapter - State property access', () {
      // 测试state属性（为toolbar_adapter提供）
      expect(controllerAdapter.state, isNotNull);
      expect(controllerAdapter.state, equals(stateAdapter));
      expect(controllerAdapter.stateManager, equals(stateAdapter));
    });

    test('Integration - Full workflow', () {
      // 模拟完整的工作流程

      // 1. 添加多个元素
      controllerAdapter.addTextElement();
      controllerAdapter.addEmptyImageElementAt(150.0, 150.0);
      controllerAdapter.addEmptyCollectionElementAt(200.0, 200.0);

      expect(controllerAdapter.elements, hasLength(3));

      // 2. 选择一个元素
      final firstElementId = controllerAdapter.elements.first['id'] as String;
      controllerAdapter.selectElement(firstElementId);
      expect(controllerAdapter.selectedElementIds, contains(firstElementId));

      // 3. 删除选中的元素
      controllerAdapter.deleteSelectedElements();
      expect(controllerAdapter.elements, hasLength(2));
      expect(controllerAdapter.selectedElementIds, isEmpty);

      // 4. 撤销删除
      controllerAdapter.undo();
      expect(controllerAdapter.elements, hasLength(3));

      // 5. 清除所有选择
      controllerAdapter.clearSelection();
      expect(controllerAdapter.selectedElementIds, isEmpty);

      // 6. 退出选择模式
      controllerAdapter.exitSelectMode();
      expect(controllerAdapter.selectedElementIds, isEmpty);
    });
  });
}
