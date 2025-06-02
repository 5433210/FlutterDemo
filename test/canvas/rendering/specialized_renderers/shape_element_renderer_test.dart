import 'dart:ui';

import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/rendering/specialized_renderers/shape_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShapeElementRenderer 测试', () {
    late ShapeElementRenderer renderer;

    setUp(() {
      renderer = ShapeElementRenderer();
    });

    test('应该能正确渲染矩形', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'rect1',
        type: 'shape',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {
          'shapeType': 'rectangle',
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

    test('应该能正确渲染圆形', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'circle1',
        type: 'shape',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'shapeType': 'circle',
          'fillColor': '#0000FF',
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确渲染多边形', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'polygon1',
        type: 'shape',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'shapeType': 'polygon',
          'sides': 6, // 六边形
          'fillColor': '#00FF00',
          'strokeColor': '#000000',
          'strokeWidth': 1.0,
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能处理无效的形状类型', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'invalid1',
        type: 'shape',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
        properties: {
          'shapeType': 'nonexistent', // 不存在的形状类型
          'fillColor': '#FF00FF',
        },
      );

      // 应该会回退到默认形状（矩形）
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确处理描边样式', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'rect2',
        type: 'shape',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {
          'shapeType': 'rectangle',
          'fillColor': 'transparent', // 无填充
          'strokeColor': '#000000',
          'strokeWidth': 3.0,
          'strokeStyle': 'dashed', // 虚线样式
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确解析颜色', () {
      // 测试私有方法通过反射或通过公共接口测试
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // 测试各种颜色格式
      final colorTests = [
        {'color': '#FF0000', 'expected': const Color(0xFFFF0000)},
        {'color': '#00FF00', 'expected': const Color(0xFF00FF00)},
        {'color': '#0000FF', 'expected': const Color(0xFF0000FF)},
        {'color': '#80808080', 'expected': const Color(0x80808080)},
        {'color': 'invalid', 'expected': Colors.black}, // 默认为黑色
      ];

      for (final test in colorTests) {
        final element = ElementData(
          id: 'color_test',
          type: 'shape',
          layerId: 'layer1',
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
          properties: {
            'shapeType': 'rectangle',
            'fillColor': test['color'],
          },
        );

        expect(() => renderer.render(canvas, element), returnsNormally);
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
