import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  group('参考线对齐系统基础测试', () {
    test('基本平移对齐功能测试', () {
      final manager = GuidelineManager.instance;
      manager.enabled = true;
      manager.updatePageSize(Size(800, 600));

      // 设置两个元素
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
          'x': 103.0, // 距离element1左边界3像素（应该在吸附阈值内）
          'y': 200.0,
          'width': 60.0,
          'height': 40.0,
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      // 生成参考线
      manager.updateGuidelinesLive(
        elementId: 'element2',
        draftPosition: Offset(103.0, 200.0),
        elementSize: Size(60.0, 40.0),
      );

      // 执行对齐
      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(103.0, 200.0),
        elementSize: Size(60.0, 40.0),
        operationType: 'translate',
      );

      // 输出调试信息
      print('对齐结果: $result');

      if (result['hasAlignment'] == true) {
        print('对齐成功');
        print('对齐后位置: ${result['position']}');
        print('对齐后尺寸: ${result['size']}');
      } else {
        print('对齐失败');
        print('当前高亮参考线数量: ${manager.highlightedGuidelines.length}');
        print('当前静态参考线数量: ${manager.staticGuidelines.length}');
        print('当前动态参考线数量: ${manager.dynamicGuidelines.length}');
      }

      // 基本验证：至少应该有返回值
      expect(result, isNotNull);
      expect(result.containsKey('hasAlignment'), true);
      expect(result.containsKey('position'), true);
      expect(result.containsKey('size'), true);
    });

    test('Resize对齐功能基础测试', () {
      final manager = GuidelineManager.instance;
      manager.enabled = true;
      manager.updatePageSize(Size(800, 600));

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
          'x': 95.0, // 距离element1左边界5像素
          'y': 200.0,
          'width': 60.0,
          'height': 40.0,
          'rotation': 0.0,
        },
      ];

      manager.updateElements(elements);

      manager.updateGuidelinesLive(
        elementId: 'element2',
        draftPosition: Offset(95.0, 200.0),
        elementSize: Size(60.0, 40.0),
      );

      final result = manager.performAlignment(
        elementId: 'element2',
        currentPosition: Offset(95.0, 200.0),
        elementSize: Size(60.0, 40.0),
        operationType: 'resize',
        resizeDirection: 'left',
      );

      print('Resize对齐结果: $result');

      if (result['hasAlignment'] == true) {
        print('Resize对齐成功');
        print('对齐后位置: ${result['position']}');
        print('对齐后尺寸: ${result['size']}');
        print('对齐信息: ${result['alignmentInfo']}');
      } else {
        print('Resize对齐失败');
      }

      // 基本验证
      expect(result, isNotNull);
      expect(result.containsKey('hasAlignment'), true);
    });
  });
}
