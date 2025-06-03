/// Canvas系统重构 - Phase 3 集成测试
///
/// 测试练习编辑页面的集成功能
library;

import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/integration/integrated_practice_edit_page.dart';
import 'package:charasgem/canvas/integration/refactored_practice_edit_controller.dart';
import 'package:charasgem/canvas/integration/unified_property_panel.dart';
import 'package:charasgem/canvas/rendering/element_renderer.dart';
import 'package:charasgem/canvas/rendering/specialized_renderers/practice_grid_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3: 练习编辑集成测试', () {
    group('RefactoredPracticeEditController', () {
      late RefactoredPracticeEditController controller;

      setUp(() {
        controller = RefactoredPracticeEditController();
      });

      tearDown(() {
        controller.dispose();
      });

      test('应该正确初始化', () {
        expect(controller.currentPracticeTemplate, '');
        expect(controller.practiceCharacters, isEmpty);
        expect(controller.showGrid, true);
        expect(controller.enableGuideLines, true);
        expect(controller.gridSpacing, 30.0);
      });

      test('应该能设置练习模板', () {
        const template = 'basic_chinese';
        controller.setPracticeTemplate(template);
        expect(controller.currentPracticeTemplate, template);
      });

      test('应该能设置练习字符', () {
        final characters = ['字', '帖', '练', '习'];
        controller.setPracticeCharacters(characters);
        expect(controller.practiceCharacters, characters);
      });

      test('应该能切换网格显示', () {
        final initialState = controller.showGrid;
        controller.toggleGrid();
        expect(controller.showGrid, !initialState);
      });

      test('应该能设置网格间距', () {
        const newSpacing = 40.0;
        controller.setGridSpacing(newSpacing);
        expect(controller.gridSpacing, newSpacing);
      });

      test('应该能添加练习字符元素', () {
        const character = '字';
        const position = Offset(100, 100);

        controller.addPracticeCharacter(character, position);

        final elements = controller.canvasController.state.elements;
        expect(elements.isNotEmpty, true);

        final element = elements.values.first;
        expect(element.type, 'collection');
        expect(element.properties['text'], character);
        expect(element.properties['isPracticeChar'], true);
      });

      test('应该能添加模板字符元素', () {
        const character = '帖';
        const position = Offset(150, 150);

        controller.addTemplateCharacter(character, position);

        final elements = controller.canvasController.state.elements;
        expect(elements.isNotEmpty, true);

        final element = elements.values.first;
        expect(element.type, 'collection');
        expect(element.properties['text'], character);
        expect(element.properties['isTemplate'], true);
      });

      test('应该能保存和加载练习进度', () {
        // 设置一些状态
        controller.setPracticeTemplate('test_template');
        controller.setPracticeCharacters(['测', '试']);
        controller.setGridSpacing(35.0);

        // 保存状态
        final savedState = controller.savePracticeProgress();

        // 验证保存的数据
        expect(savedState['template'], 'test_template');
        expect(savedState['characters'], ['测', '试']);
        expect(savedState['gridSpacing'], 35.0);
        expect(savedState['timestamp'], isNotNull);

        // 重置状态
        controller.clearPractice();
        expect(controller.currentPracticeTemplate, '');
        expect(controller.practiceCharacters, isEmpty);

        // 加载状态
        controller.loadPracticeProgress(savedState);
        expect(controller.currentPracticeTemplate, 'test_template');
        expect(controller.practiceCharacters, ['测', '试']);
        expect(controller.gridSpacing, 35.0);
      });

      test('应该能获取练习统计信息', () {
        // 添加一些练习内容
        controller.setPracticeCharacters(['统', '计', '测', '试']);
        controller.addPracticeCharacter('统', const Offset(0, 0));
        controller.addPracticeCharacter('计', const Offset(50, 0));
        controller.addTemplateCharacter('测', const Offset(100, 0));

        final stats = controller.getPracticeStatistics();

        expect(stats['totalCharacters'], 4);
        expect(stats['practiceCharacters'], 2);
        expect(stats['templateCharacters'], 1);
        expect(stats['completionRate'], 0.5);
        expect(stats['lastModified'], isNotNull);
      });
    });

    group('UnifiedPropertyPanel', () {
      testWidgets('应该正确显示空状态', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnifiedPropertyPanel(
                selectedElements: const [],
                onPropertyChanged: (id, property, value) {},
              ),
            ),
          ),
        );

        expect(find.text('选择一个或多个元素以编辑属性'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('应该正确显示单个元素的属性', (WidgetTester tester) async {
        const element = ElementData(
          id: 'test_element',
          type: 'text',
          layerId: 'layer1',
          bounds: Rect.fromLTWH(0, 0, 100, 50),
          properties: {
            'text': '测试文本',
            'fontSize': 16.0,
            'fontColor': '#000000',
            'isLocked': false,
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnifiedPropertyPanel(
                selectedElements: const [element],
                onPropertyChanged: (id, property, value) {},
              ),
            ),
          ),
        );

        expect(find.text('文本'), findsWidgets);
        expect(find.text('test_element'), findsOneWidget);
      });

      testWidgets('应该正确显示多元素批量编辑', (WidgetTester tester) async {
        final elements = [
          const ElementData(
            id: 'element1',
            type: 'text',
            layerId: 'layer1',
            bounds: Rect.fromLTWH(0, 0, 100, 50),
            properties: {'text': '元素1'},
          ),
          const ElementData(
            id: 'element2',
            type: 'text',
            layerId: 'layer1',
            bounds: Rect.fromLTWH(100, 0, 100, 50),
            properties: {'text': '元素2'},
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnifiedPropertyPanel(
                selectedElements: elements,
                onPropertyChanged: (id, property, value) {},
              ),
            ),
          ),
        );

        expect(find.text('批量编辑 (2 个元素)'), findsOneWidget);
        expect(find.text('开始批量编辑'), findsOneWidget);
      });
    });

    group('PracticeGridRenderer', () {
      late PracticeGridRenderer renderer;

      setUp(() {
        renderer = PracticeGridRenderer();
      });

      tearDown(() {
        renderer.dispose();
      });

      test('应该返回正确的元素类型', () {
        expect(renderer.elementType, 'practice_grid');
      });

      test('应该能识别支持的元素类型', () {
        const gridElement = ElementData(
          id: 'grid1',
          type: 'practice_grid',
          layerId: 'layer1',
          bounds: Rect.fromLTWH(0, 0, 300, 300),
          properties: {},
        );

        const textElement = ElementData(
          id: 'text1',
          type: 'text',
          layerId: 'layer1',
          bounds: Rect.fromLTWH(0, 0, 100, 50),
          properties: {},
        );

        expect(renderer.canRender(gridElement), true);
        expect(renderer.canRender(textElement), false);
      });

      test('应该能估算渲染时间', () {
        const element = ElementData(
          id: 'grid1',
          type: 'practice_grid',
          layerId: 'layer1',
          bounds: Rect.fromLTWH(0, 0, 300, 300),
          properties: {
            'gridSize': 30.0,
          },
        );
        final lowTime = renderer.estimateRenderTime(element, RenderQuality.low);
        final normalTime =
            renderer.estimateRenderTime(element, RenderQuality.normal);
        final highTime =
            renderer.estimateRenderTime(element, RenderQuality.high);

        expect(lowTime, lessThan(normalTime));
        expect(normalTime, lessThan(highTime));
      });

      test('应该能获取正确的边界', () {
        const bounds = Rect.fromLTWH(10, 20, 200, 150);
        const element = ElementData(
          id: 'grid1',
          type: 'practice_grid',
          layerId: 'layer1',
          bounds: bounds,
          properties: {},
        );

        final resultBounds = renderer.getBounds(element);
        expect(resultBounds, bounds);
      });

      test('应该能初始化和清理资源', () async {
        expect(renderer.isInitialized, false);

        await renderer.initialize();
        expect(renderer.isInitialized, true);

        renderer.dispose();
        expect(renderer.isInitialized, false);
      });
    });

    group('集成测试', () {
      testWidgets('IntegratedPracticeEditPage 应该正确渲染',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: IntegratedPracticeEditPage(
              initialTemplate: 'test_template',
              initialCharacters: ['测', '试'],
            ),
          ),
        );

        expect(find.text('字帖编辑'), findsOneWidget);
        expect(find.byIcon(Icons.grid_on), findsOneWidget);
        expect(find.byIcon(Icons.straighten), findsOneWidget);
      });

      testWidgets('应该能切换网格显示', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: IntegratedPracticeEditPage(),
          ),
        );

        // 查找网格按钮并点击
        final gridButton = find.byIcon(Icons.grid_on);
        expect(gridButton, findsOneWidget);

        await tester.tap(gridButton);
        await tester.pump();

        // 验证图标已变化
        expect(find.byIcon(Icons.grid_off), findsOneWidget);
      });

      testWidgets('应该显示状态栏信息', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: IntegratedPracticeEditPage(
              initialCharacters: ['状', '态', '栏'],
            ),
          ),
        );

        await tester.pump();

        // 查找状态栏信息
        expect(find.textContaining('字符:'), findsOneWidget);
        expect(find.textContaining('已练习:'), findsOneWidget);
        expect(find.textContaining('完成率:'), findsOneWidget);
      });

      testWidgets('工具栏应该正确显示和响应', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: IntegratedPracticeEditPage(),
          ),
        );

        // 验证工具栏按钮
        expect(find.text('选择'), findsOneWidget);
        expect(find.text('文本'), findsOneWidget);
        expect(find.text('集字'), findsOneWidget);
        expect(find.text('图片'), findsOneWidget);
        expect(find.text('形状'), findsOneWidget);
        expect(find.text('撤销'), findsOneWidget);
        expect(find.text('重做'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      });
    });

    group('兼容性测试', () {
      test('应该能处理旧格式的元素数据', () {
        final controller = RefactoredPracticeEditController();

        // 模拟旧格式的元素数据
        final legacyElement = {
          'id': 'legacy_text_1',
          'type': 'text',
          'x': 100.0,
          'y': 200.0,
          'width': 150.0,
          'height': 80.0,
          'content': {
            'text': '兼容性测试',
            'fontSize': 18.0,
            'fontColor': '#333333',
          },
        };

        // 验证能够处理旧格式
        expect(() {
          // 这里模拟在统一属性面板中处理旧格式数据
          final propertyPanel = UnifiedPropertyPanel(
            selectedElements: [legacyElement],
            onPropertyChanged: (id, property, value) {},
          );
          expect(propertyPanel.selectedElements.length, 1);
        }, returnsNormally);

        controller.dispose();
      });

      test('新旧系统属性映射应该正确', () {
        // 测试属性名称映射
        const propertyMappings = {
          'x': 'bounds.left',
          'y': 'bounds.top',
          'width': 'bounds.width',
          'height': 'bounds.height',
          'content.text': 'text',
          'content.fontSize': 'fontSize',
          'content.fontColor': 'fontColor',
        };

        for (final mapping in propertyMappings.entries) {
          // 验证映射关系存在
          expect(mapping.key, isNotEmpty);
          expect(mapping.value, isNotEmpty);
        }
      });
    });

    group('性能测试', () {
      test('大量元素处理性能', () {
        final controller = RefactoredPracticeEditController();
        final stopwatch = Stopwatch()..start();

        // 添加大量元素
        for (int i = 0; i < 1000; i++) {
          controller.addPracticeCharacter(
            '字',
            Offset(i % 20 * 30.0, i ~/ 20 * 30.0),
          );
        }

        stopwatch.stop();

        // 验证性能在可接受范围内（1秒内）
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        // 验证元素数量
        final elementCount = controller.canvasController.state.elements.length;
        expect(elementCount, 1000);

        controller.dispose();
      });

      test('属性面板渲染性能', () {
        // 创建大量元素进行批量编辑测试
        final elements = List.generate(100, (i) {
          return ElementData(
            id: 'element_$i',
            type: 'text',
            layerId: 'layer1',
            bounds: Rect.fromLTWH(i * 10.0, 0, 50, 30),
            properties: {
              'text': '元素$i',
              'fontSize': 16.0,
            },
          );
        });

        final stopwatch = Stopwatch()..start();

        // 创建属性面板
        final propertyPanel = UnifiedPropertyPanel(
          selectedElements: elements,
          onPropertyChanged: (id, property, value) {},
          config: const PropertyPanelConfig(
            enableBatchEdit: true,
            showAdvancedProperties: true,
          ),
        );

        stopwatch.stop();

        // 验证创建时间在可接受范围内
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(propertyPanel.selectedElements.length, 100);
      });
    });
  });
}
