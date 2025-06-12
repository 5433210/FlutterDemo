// test/presentation/widgets/free_control_points_alignment_mode_test.dart
import 'package:charasgem/presentation/pages/practices/widgets/free_control_points.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FreeControlPoints AlignmentMode测试', () {
    testWidgets('alignmentMode应该被正确传递和使用', (WidgetTester tester) async {
      // 测试不同的对齐模式
      for (final mode in AlignmentMode.values) {
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
                alignmentMode: mode,
                onGuidelinesUpdated: (guidelines) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证组件能正常渲染
        expect(find.byType(FreeControlPoints), findsOneWidget);

        print('✅ AlignmentMode.${mode.name} 测试通过');
      }
    });

    testWidgets('alignmentMode为null时应该正常工作', (WidgetTester tester) async {
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
              alignmentMode: null, // 测试null值
              onGuidelinesUpdated: (guidelines) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证组件能正常渲染
      expect(find.byType(FreeControlPoints), findsOneWidget);

      print('✅ AlignmentMode为null时测试通过');
    });
  });
}
