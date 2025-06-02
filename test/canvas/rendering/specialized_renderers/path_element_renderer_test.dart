import 'dart:ui';

import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/rendering/specialized_renderers/path_element_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PathElementRenderer 测试', () {
    late PathElementRenderer renderer;

    setUp(() {
      renderer = PathElementRenderer();
    });

    test('应该能正确渲染SVG路径数据', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'path1',
        type: 'path',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'pathData':
              'M 10,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 90,30 Q 90,60 50,90 Q 10,60 10,30 z',
          'fillColor': '#FF0000',
          'strokeColor': '#000000',
          'strokeWidth': 2.0,
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确渲染直线路径', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'line_path',
        type: 'path',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'pathData': 'M 10,10 L 90,90 M 90,10 L 10,90',
          'fillColor': 'transparent',
          'strokeColor': '#0000FF',
          'strokeWidth': 3.0,
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确渲染贝塞尔曲线', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'bezier_path',
        type: 'path',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 200),
        properties: {
          'pathData': 'M 10,50 C 20,0 80,0 90,50 S 160,100 180,50',
          'fillColor': 'transparent',
          'strokeColor': '#00FF00',
          'strokeWidth': 2.0,
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能处理无效路径数据', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'invalid_path',
        type: 'path',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'pathData': 'Invalid SVG path data XYZ',
          'fillColor': '#FF00FF',
          'strokeColor': '#000000',
          'strokeWidth': 1.0,
        },
      );

      // 执行渲染 - 应该优雅处理错误
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能处理缺失的路径数据', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'missing_path_data',
        type: 'path',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          // 缺失pathData
          'fillColor': '#FF00FF',
          'strokeColor': '#000000',
          'strokeWidth': 1.0,
        },
      );

      // 执行渲染 - 应该优雅处理错误
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确应用路径样式', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'styled_path',
        type: 'path',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'pathData': 'M 10,10 h 80 v 80 h -80 Z',
          'fillColor': '#80FF8080', // 半透明填充
          'strokeColor': '#000000',
          'strokeWidth': 2.0,
          'strokeCap': 'round',
          'strokeJoin': 'round',
          'strokeStyle': 'dashed',
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
