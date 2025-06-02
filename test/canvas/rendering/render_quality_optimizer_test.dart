import 'package:charasgem/canvas/rendering/render_quality_optimizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderQualityOptimizer 测试', () {
    late RenderQualityOptimizer optimizer;

    setUp(() {
      optimizer = RenderQualityOptimizer();
    });

    test('初始状态应该是默认质量设置', () {
      final settings = optimizer.currentSettings;
      expect(settings.qualityLevel, isA<RenderQualityLevel>());
    });

    test('应该能手动设置质量级别', () {
      // 设置为低质量
      optimizer.setQualityLevel(RenderQualityLevel.low);
      expect(optimizer.currentSettings.qualityLevel,
          equals(RenderQualityLevel.low));
      expect(optimizer.currentSettings.antiAlias, isFalse);
      expect(
          optimizer.currentSettings.filterQuality, equals(FilterQuality.low));

      // 设置为高质量
      optimizer.setQualityLevel(RenderQualityLevel.high);
      expect(optimizer.currentSettings.qualityLevel,
          equals(RenderQualityLevel.high));
      expect(optimizer.currentSettings.antiAlias, isTrue);
      expect(
          optimizer.currentSettings.filterQuality, equals(FilterQuality.high));
    });

    test('应该能根据性能自动调整质量', () {
      // 启用自动调整
      optimizer.autoAdjust = true;

      // 模拟低帧率
      optimizer.adjustForPerformance(25.0); // 25 FPS
      expect(optimizer.currentSettings.qualityLevel,
          equals(RenderQualityLevel.low));

      // 模拟高帧率
      optimizer.adjustForPerformance(60.0); // 60 FPS
      expect(optimizer.currentSettings.qualityLevel,
          equals(RenderQualityLevel.high));

      // 模拟中等帧率
      optimizer.adjustForPerformance(45.0); // 45 FPS
      expect(optimizer.currentSettings.qualityLevel,
          equals(RenderQualityLevel.medium));
    });

    test('应该能禁用自动调整', () {
      // 先设置为低质量
      optimizer.setQualityLevel(RenderQualityLevel.low);

      // 禁用自动调整
      optimizer.autoAdjust = false;

      // 即使性能良好，也不应该自动调整
      optimizer.adjustForPerformance(60.0);
      expect(optimizer.currentSettings.qualityLevel,
          equals(RenderQualityLevel.low));
    });

    test('应该能正确应用设置到画笔', () {
      // 设置为高质量
      optimizer.setQualityLevel(RenderQualityLevel.high);

      // 测试应用到画笔
      final paint = Paint();
      optimizer.applyToPaint(paint);

      expect(paint.isAntiAlias, isTrue);
      expect(paint.filterQuality, equals(FilterQuality.high));
    });

    test('RenderQualitySettings 应该支持复制并修改', () {
      final settings = RenderQualitySettings.defaultSettings();
      final modified = settings.copyWith(
        antiAlias: false,
        filterQuality: FilterQuality.low,
      );

      expect(modified.antiAlias, isFalse);
      expect(modified.filterQuality, equals(FilterQuality.low));
      expect(modified.curveSmoothing,
          equals(settings.curveSmoothing)); // 未修改的值应保持不变
    });
  });
}
