import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_types.dart';

void main() {
  group('参考线对齐系统 - Resize功能测试', () {
    late GuidelineManager manager;    setUp(() {
      manager = GuidelineManager.instance;
      // 重置管理器状态
      manager.enabled = true;
      manager.updatePageSize(Size(800, 600));
    });

    test('应该支持左边界resize对齐', () {
      // 准备：添加两个元素，第二个元素的左边界将对齐到第一个元素的左边界
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 50.0,
          'rotation': 0.0,
        },
        {
          'id': 'element2', 
          'x': 95.0, // 距离element1左边界5像素（在吸附阈值内）
          'y': 200.0,
          'width': 60.0,
          'height': 40.0,
          'rotation': 0.0,
        },      ];

      manager.updateElements(elements);      // 生成参考线
      manager.updateGuidelinesLive(
        elementId: 'element2',
        draftPosition: Offset(95.0, 200.0),
        elementSize: Size(60.0, 40.0),
      );

      // 执行：模拟拖拽element2的左边界控制点
      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(95.0, 200.0),
        elementSize: Size(60.0, 40.0),
        operationType: 'resize',
        resizeDirection: 'left',
      );

      // 验证：应该发生对齐，左边界移动到100，宽度相应调整
      expect(result['hasAlignment'], true);
      expect(result['position'], Offset(100.0, 200.0)); // x位置对齐到100
      expect(result['size'].width, 55.0); // 宽度调整为原来的60-5=55
      expect(result['size'].height, 40.0); // 高度不变

      final alignmentInfo = result['alignmentInfo'];
      expect(alignmentInfo['operationType'], 'resize');
      expect(alignmentInfo['resizeDirection'], 'left');
    });

    test('应该支持右边界resize对齐', () {
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 50.0,
          'rotation': 0.0,
        },
        {
          'id': 'element2',
          'x': 200.0,
          'y': 200.0,
          'width': 45.0, // 右边界在245，距离element1右边界(150)较远
          'height': 40.0,
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      // 执行：模拟拖拽element2右边界到element1右边界附近
      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(200.0, 200.0),
        elementSize: Size(48.0, 40.0), // 假设右边界已经拖拽到152附近（在吸附阈值内）
        operationType: 'resize',
        resizeDirection: 'right',
      );

      // 验证：应该发生对齐，右边界对齐到150
      expect(result['hasAlignment'], true);
      expect(result['position'], Offset(200.0, 200.0)); // 位置不变
      expect(result['size'].width, closeTo(150.0 - 200.0, 0.1)); // 宽度调整，右边界对齐到150
      expect(result['size'].height, 40.0); // 高度不变
    });

    test('应该支持上边界resize对齐', () {
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 50.0,
          'rotation': 0.0,
        },
        {
          'id': 'element2',
          'x': 200.0,
          'y': 97.0, // 距离element1上边界3像素
          'width': 60.0,
          'height': 40.0,
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(200.0, 97.0),
        elementSize: Size(60.0, 40.0),
        operationType: 'resize',
        resizeDirection: 'top',
      );

      // 验证：上边界对齐，y位置移动到100，高度相应调整
      expect(result['hasAlignment'], true);
      expect(result['position'], Offset(200.0, 100.0)); // y位置对齐到100
      expect(result['size'].width, 60.0); // 宽度不变
      expect(result['size'].height, 37.0); // 高度调整为原来的40-3=37
    });

    test('应该支持下边界resize对齐', () {
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 50.0,
          'rotation': 0.0,
        },
        {
          'id': 'element2',
          'x': 200.0,
          'y': 200.0,
          'width': 60.0,
          'height': 45.0, // 下边界在245，距离element1下边界(150)较远
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      // 模拟下边界resize到element1下边界附近
      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(200.0, 200.0),
        elementSize: Size(60.0, 48.0), // 假设下边界已拖拽到248（在阈值内）
        operationType: 'resize',
        resizeDirection: 'bottom',
      );

      // 验证：下边界对齐到150
      expect(result['hasAlignment'], true);
      expect(result['position'], Offset(200.0, 200.0)); // 位置不变
      expect(result['size'].width, 60.0); // 宽度不变
      expect(result['size'].height, closeTo(150.0 - 200.0, 0.1)); // 高度调整，下边界对齐到150
    });

    test('平移操作应该保持元素尺寸不变', () {
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 50.0,
          'rotation': 0.0,
        },
        {
          'id': 'element2',
          'x': 103.0, // 距离element1左边界3像素
          'y': 200.0,
          'width': 60.0,
          'height': 40.0,
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(103.0, 200.0),
        elementSize: Size(60.0, 40.0),
        operationType: 'translate', // 平移操作
      );

      // 验证：位置对齐，但尺寸保持不变
      expect(result['hasAlignment'], true);
      expect(result['position'], Offset(100.0, 200.0)); // 位置对齐
      expect(result['size'], Size(60.0, 40.0)); // 尺寸不变
    });

    test('距离超过吸附阈值时不应该对齐', () {
      final elements = [
        {
          'id': 'element1',
          'x': 100.0,
          'y': 100.0,
          'width': 50.0,
          'height': 50.0,
          'rotation': 0.0,
        },
        {
          'id': 'element2',
          'x': 90.0, // 距离element1左边界10像素（超过吸附阈值8）
          'y': 200.0,
          'width': 60.0,
          'height': 40.0,
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(90.0, 200.0),
        elementSize: Size(60.0, 40.0),
        operationType: 'resize',
        resizeDirection: 'left',
      );

      // 验证：不应该发生对齐
      expect(result['hasAlignment'], false);
      expect(result['position'], Offset(90.0, 200.0)); // 位置不变
      expect(result['size'], Size(60.0, 40.0)); // 尺寸不变
    });
  });
}
