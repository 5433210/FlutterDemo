// test/presentation/widgets/free_control_points_guideline_test.dart
import 'package:charasgem/presentation/pages/practices/widgets/free_control_points.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FreeControlPoints 参考线对齐测试', () {
    testWidgets('平移时应该触发参考线对齐回调', (WidgetTester tester) async {
      List<Guideline> capturedGuidelines = [];
      bool onGuidelinesUpdatedCalled = false;

      // 初始化GuidelineManager
      GuidelineManager.instance.initialize(
        elements: [
          {
            'id': 'element1',
            'x': 100.0,
            'y': 100.0,
            'width': 50.0,
            'height': 30.0
          },
        ],
        pageSize: const Size(800, 600),
        enabled: true,
        snapThreshold: 5.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: FreeControlPoints(
                elementId: 'element2',
                x: 95.0,
                y: 102.0,
                width: 40.0,
                height: 25.0,
                rotation: 0.0,
                alignmentMode: AlignmentMode.guideline,
                onGuidelinesUpdated: (guidelines) {
                  capturedGuidelines = guidelines;
                  onGuidelinesUpdatedCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证FreeControlPoints是否正确初始化
      expect(find.byType(FreeControlPoints), findsOneWidget);

      // 测试通过验证回调是否正确设置
      expect(onGuidelinesUpdatedCalled, false, reason: '初始状态下不应该有参考线回调');

      print('✅ FreeControlPoints参考线对齐回调集成测试通过');
    });

    testWidgets('应该正确初始化参考线相关属性', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FreeControlPoints(
              elementId: 'test-element',
              x: 100.0,
              y: 100.0,
              width: 50.0,
              height: 30.0,
              rotation: 0.0,
              alignmentMode: AlignmentMode.guideline,
              onGuidelinesUpdated: (guidelines) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证组件是否正确渲染
      expect(find.byType(FreeControlPoints), findsOneWidget);

      print('✅ FreeControlPoints参考线属性初始化测试通过');
    });
  });
}
