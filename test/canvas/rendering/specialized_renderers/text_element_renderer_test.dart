import 'dart:ui';

import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/rendering/specialized_renderers/text_element_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextElementRenderer 测试', () {
    late TextElementRenderer renderer;

    setUp(() {
      renderer = TextElementRenderer();
    });

    test('应该能正确渲染基本文本', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'text1',
        type: 'text',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 50),
        properties: {
          'text': 'Hello World',
          'fontSize': 16.0,
          'fontFamily': 'Arial',
          'color': '#000000',
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确处理文本样式', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'text2',
        type: 'text',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 200, 50),
        properties: {
          'text': 'Styled Text',
          'fontSize': 20.0,
          'fontFamily': 'Roboto',
          'color': '#FF0000',
          'fontWeight': 'bold',
          'fontStyle': 'italic',
          'letterSpacing': 1.5,
          'lineHeight': 1.2,
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确处理长文本和自动换行', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'text3',
        type: 'text',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 150, 100),
        properties: {
          'text':
              'This is a long text that should automatically wrap to the next line based on the element bounds width.',
          'fontSize': 14.0,
          'color': '#000000',
          'textAlign': 'left',
          'textWrap': true,
        },
      );

      // 执行渲染
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能正确应用文本对齐', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // 测试不同的文本对齐方式
      final alignments = ['left', 'center', 'right', 'justify'];

      for (final align in alignments) {
        final element = ElementData(
          id: 'text_align_$align',
          type: 'text',
          layerId: 'layer1',
          bounds: const Rect.fromLTWH(0, 0, 200, 50),
          properties: {
            'text': 'Aligned Text',
            'fontSize': 16.0,
            'color': '#000000',
            'textAlign': align,
          },
        );

        expect(() => renderer.render(canvas, element), returnsNormally);
      }

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能处理空文本', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'empty_text',
        type: 'text',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {
          'text': '',
          'fontSize': 16.0,
          'color': '#000000',
        },
      );

      // 执行渲染 - 不应崩溃
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该能处理缺失的文本属性', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'missing_text_props',
        type: 'text',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
        properties: {
          // 没有提供任何文本相关属性
        },
      );

      // 执行渲染 - 应该使用默认值
      expect(() => renderer.render(canvas, element), returnsNormally);

      // 完成绘制
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
