import 'dart:ui';

import 'package:charasgem/canvas/core/interfaces/element_data.dart';
import 'package:charasgem/canvas/rendering/element_renderer.dart';
import 'package:charasgem/canvas/rendering/specialized_renderers/collection_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollectionElementRenderer 测试', () {
    late CollectionElementRenderer renderer;

    setUp(() {
      renderer = CollectionElementRenderer();
    });

    tearDown(() {
      renderer.dispose();
    });

    test('应该返回正确的元素类型', () {
      expect(renderer.elementType, equals('collection'));
      expect(renderer.supportsCaching, isTrue);
      expect(renderer.supportsGpuAcceleration, isTrue);
    });

    test('应该能够识别支持的元素类型', () {
      const collectionElement = ElementData(
        id: 'collection1',
        type: 'collection',
        layerId: 'layer1',
      );

      const otherElement = ElementData(
        id: 'shape1',
        type: 'shape',
        layerId: 'layer1',
      );

      expect(renderer.canRender(collectionElement), isTrue);
      expect(renderer.canRender(otherElement), isFalse);
    });

    test('应该能够初始化和清理资源', () async {
      expect(renderer.isInitialized, isFalse);

      await renderer.initialize();
      expect(renderer.isInitialized, isTrue);

      renderer.clearCache();
      expect(renderer.isInitialized, isTrue);

      renderer.dispose();
      expect(renderer.isInitialized, isFalse);
    });

    test('应该能够估算渲染时间', () {
      const simpleElement = ElementData(
        id: 'collection1',
        type: 'collection',
        layerId: 'layer1',
        properties: {
          'text': '简单文本',
          'hasTexture': false,
        },
      );

      const complexElement = ElementData(
        id: 'collection2',
        type: 'collection',
        layerId: 'layer1',
        properties: {
          'text': '这是一段比较长的文本，包含更多字符',
          'hasTexture': true,
        },
      );

      // 简单元素的估计时间应该小于复杂元素
      final simpleTime =
          renderer.estimateRenderTime(simpleElement, RenderQuality.normal);
      final complexTime =
          renderer.estimateRenderTime(complexElement, RenderQuality.normal);
      expect(simpleTime, lessThan(complexTime));

      // 高质量渲染的时间应该大于低质量
      final lowQualityTime =
          renderer.estimateRenderTime(complexElement, RenderQuality.low);
      final highQualityTime =
          renderer.estimateRenderTime(complexElement, RenderQuality.high);
      expect(lowQualityTime, lessThan(highQualityTime));
    });

    test('应该返回正确的边界和命中测试路径', () {
      const element = ElementData(
        id: 'collection1',
        type: 'collection',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(10, 20, 200, 100),
      );

      final bounds = renderer.getBounds(element);
      expect(bounds, equals(const Rect.fromLTWH(10, 20, 200, 100)));

      final hitPath = renderer.getHitTestPath(element);
      expect(hitPath, isNotNull);

      // 检查路径包含边界内的点
      expect(hitPath.contains(const Offset(15, 25)), isTrue);
      expect(hitPath.contains(const Offset(205, 25)), isTrue);
      expect(hitPath.contains(const Offset(15, 115)), isTrue);
      expect(hitPath.contains(const Offset(205, 115)), isTrue);

      // 检查路径不包含边界外的点
      expect(hitPath.contains(const Offset(5, 25)), isFalse);
      expect(hitPath.contains(const Offset(215, 25)), isFalse);
      expect(hitPath.contains(const Offset(15, 125)), isFalse);
    });

    test('应该能正确计算字符位置', () {
      // 通过反射调用私有方法进行测试
      final positions = renderer.getCharPositions(
        'test-id',
        '测试文本\n第二行',
        const Size(200, 100),
        20, // fontSize
        2, // letterSpacing
        5, // lineSpacing
        'horizontal-tb', // writingMode
        'left', // textAlign
        'top', // verticalAlign
        false, // enableSoftLineBreak
      );

      expect(positions, isNotEmpty);
      expect(positions.length, equals(8)); // 4个字符 + 3个字符 + 1个换行符

      // 验证第一行字符位置
      expect(positions[0].char, equals('测'));
      expect(positions[0].position.dy, equals(0)); // 第一行应该从顶部开始

      // 验证第二行字符位置
      final secondLineChar = positions.firstWhere((p) => p.isNewLine);
      expect(secondLineChar.position.dy, greaterThan(20)); // 第二行应该在第一行之下
    });

    test('应该支持不同的对齐方式', () {
      // 居中对齐
      final centerPositions = renderer.getCharPositions(
        'test-center',
        '居中对齐',
        const Size(200, 100),
        20,
        2,
        5,
        'horizontal-tb',
        'center', // 水平居中
        'middle', // 垂直居中
        false,
      );

      // 右对齐
      final rightPositions = renderer.getCharPositions(
        'test-right',
        '右对齐',
        const Size(200, 100),
        20,
        2,
        5,
        'horizontal-tb',
        'right', // 右对齐
        'top',
        false,
      );

      // 确认居中对齐的第一个字符在水平中间位置附近
      expect(centerPositions[0].position.dx,
          closeTo(200 / 2 - (4 * 20 + 3 * 2) / 2, 1));

      // 确认右对齐的第一个字符在右侧
      expect(rightPositions[0].position.dx, greaterThan(0));
      expect(rightPositions.last.position.dx + 20, closeTo(200, 1));
    });

    test('应该支持垂直布局', () {
      // 垂直布局测试
      final verticalPositions = renderer.getCharPositions(
        'test-vertical',
        '垂直布局',
        const Size(100, 200),
        20,
        2,
        5,
        'vertical-rl', // 垂直从右到左
        'center',
        'top',
        false,
      );

      // 确认垂直布局的字符是按列排列的
      for (int i = 0; i < verticalPositions.length - 1; i++) {
        if (verticalPositions[i].char != '\n' &&
            verticalPositions[i + 1].char != '\n') {
          // 同一列的字符应该有相同的X坐标
          expect(verticalPositions[i].position.dx,
              equals(verticalPositions[i + 1].position.dx));
          // Y坐标应该不同
          expect(verticalPositions[i].position.dy,
              lessThan(verticalPositions[i + 1].position.dy));
        }
      }
    });

    test('应该支持软换行', () {
      // 测试短文本（不需要换行）
      const shortText = '短文本';
      final shortPositions = renderer.getCharPositions(
        'test-short',
        shortText,
        const Size(200, 100),
        20,
        2,
        5,
        'horizontal-tb',
        'left',
        'top',
        true, // 启用软换行
      );

      // 测试长文本（需要换行）
      const longText = '这是一段需要软换行的较长文本内容，应该会自动换行';
      final longPositions = renderer.getCharPositions(
        'test-long',
        longText,
        const Size(200, 100),
        20,
        2,
        5,
        'horizontal-tb',
        'left',
        'top',
        true, // 启用软换行
      );

      // 短文本应该在一行内
      final shortYCoords = shortPositions.map((p) => p.position.dy).toSet();
      expect(shortYCoords.length, equals(1)); // 只有一个Y坐标值，表示只有一行

      // 长文本应该有多行
      final longYCoords = longPositions.map((p) => p.position.dy).toSet();
      expect(longYCoords.length, greaterThan(1)); // 有多个Y坐标值，表示有多行
    });

    test('应该能够渲染选择状态', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const element = ElementData(
        id: 'collection1',
        type: 'collection',
        layerId: 'layer1',
        bounds: Rect.fromLTWH(0, 0, 100, 50),
      );

      final context = RenderContext(
        canvas: canvas,
        size: const Size(100, 50),
        isSelected: true,
        timestamp: const Duration(seconds: 0),
      );

      expect(() {
        renderer.renderSelection(element, context);
      }, returnsNormally);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('应该正确解析颜色', () {
      // 测试透明色
      final transparent = renderer.parseColor('transparent');
      expect(transparent, equals(Colors.transparent));

      // 测试6位十六进制
      final red = renderer.parseColor('#FF0000');
      expect(red, equals(const Color(0xFFFF0000)));

      // 测试8位十六进制（带透明度）
      final semiTransparentBlue = renderer.parseColor('#800000FF');
      expect(semiTransparentBlue, equals(const Color(0x800000FF)));

      // 测试无效颜色（应返回黑色）
      final invalid = renderer.parseColor('invalid');
      expect(invalid, equals(Colors.black));
    });

    test('应该能够创建和更新缓存', () {
      const element = ElementData(
        id: 'collection1',
        type: 'collection',
        layerId: 'layer1',
        properties: {
          'text': '缓存测试',
        },
      );

      // 更新缓存
      renderer.updateCache(element);

      // 模拟渲染以填充缓存
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final context = RenderContext(
        canvas: canvas,
        size: const Size(100, 50),
        timestamp: const Duration(seconds: 0),
      );

      // 第一次渲染后应该有缓存
      renderer.render(element, context);

      // 清除特定元素的缓存
      renderer.clearCache(element.id);

      // 清除所有缓存
      renderer.clearCache();
    });
  });
}
