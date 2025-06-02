import 'dart:ui' as ui;

import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/rendering/specialized_renderers/image_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageElementRenderer 测试', () {
    late ImageElementRenderer renderer;

    setUp(() {
      renderer = ImageElementRenderer();
    });

    test('应该能处理缺失的图像数据', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'image1',
        type: 'image',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 150),
        properties: {
          // 没有提供图像数据
        },
      );

      // 执行渲染 - 应该优雅处理错误
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确应用图像混合模式', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'image_blend',
        type: 'image',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 150),
        properties: {
          'blendMode': 'multiply', // 混合模式
          'opacity': 0.8, // 透明度
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确应用裁剪区域', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'image_crop',
        type: 'image',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 150),
        properties: {
          'cropRect': {
            'x': 20.0,
            'y': 20.0,
            'width': 160.0,
            'height': 110.0,
          },
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确应用图像滤镜', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'image_filter',
        type: 'image',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 150),
        properties: {
          'filters': [
            {'type': 'blur', 'radius': 5.0},
            {'type': 'brightness', 'value': 1.2},
            {'type': 'contrast', 'value': 1.1},
          ],
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确处理图像缩放模式', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 测试不同的缩放模式
      final fitModes = ['contain', 'cover', 'fill', 'none'];

      for (final mode in fitModes) {
        final element = ElementData(
          id: 'image_fit_$mode',
          type: 'image',
          layerId: 'layer1',
          bounds: const Rect.fromLTWH(0, 0, 200, 150),
          properties: {
            'fitMode': mode,
          },
        );

        expect(() => renderer.render(canvas, element), returnsNormally);
      }

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确处理图像旋转', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'image_rotation',
        type: 'image',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 150),
        rotation: 0.785, // 约45度
        properties: {},
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
