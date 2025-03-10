import 'dart:async';
import 'dart:math';

import '../seasonal_analyzer.dart';

Future<void> main() async {
  print('启动季节性分析示例...\n');

  final analyzer = SeasonalAnalyzer(
    config: const SeasonalConfig(
      minAnalysisPeriod: Duration(days: 7),
      maxAnalysisPeriod: Duration(days: 90),
      autoDetect: true,
      significanceThreshold: 0.1,
      factors: [
        SeasonalFactor(
          pattern: SeasonalPattern.daily,
          period: Duration(days: 1),
          factors: {},
          timeSlots: {
            TimeCharacteristic.peak: [
              TimeOfDay(hour: 9, minute: 0),
              TimeOfDay(hour: 14, minute: 0),
            ],
            TimeCharacteristic.normal: [
              TimeOfDay(hour: 10, minute: 0),
              TimeOfDay(hour: 15, minute: 0),
            ],
          },
        ),
      ],
    ),
  );

  // 1. 模拟API请求延迟数据
  print('1. 模拟一周的API请求延迟数据:');
  final now = DateTime.now();
  final random = Random(42); // 固定种子以获得可重复的结果

  // 生成一周的数据，每小时一个数据点
  for (var i = 0; i < 24 * 7; i++) {
    final time = now.subtract(Duration(hours: 24 * 7 - i));
    final hour = time.hour;
    final weekday = time.weekday;

    // 基础延迟
    var latency = 100.0;

    // 添加每日模式
    if (hour >= 9 && hour <= 18) {
      // 工作时间
      latency += 50.0; // 更高的延迟
      if (hour >= 13 && hour <= 15) {
        // 午后高峰
        latency += 30.0;
      }
    }

    // 添加工作日/周末模式
    if (weekday <= 5) {
      // 工作日
      latency += 40.0;
    }

    // 添加随机波动
    latency += random.nextDouble() * 20.0;

    analyzer.recordDataPoint(time, latency);
  }

  // 2. 分析季节性模式
  print('\n2. 分析季节性模式:');
  final analysis = await analyzer.analyze();

  print('''
检测到的模式:
${analysis.detectedPatterns.map((p) => '- $p').join('\n')}

模式显著性:
${analysis.significance.entries.map((e) => '- ${e.key}: ${(e.value * 100).toStringAsFixed(1)}%').join('\n')}

时间特征:
${analysis.timeRanges.entries.map((e) => '''
${e.key}:
  开始: ${e.value.start.hour}:${e.value.start.minute.toString().padLeft(2, '0')}
  结束: ${e.value.end.hour}:${e.value.end.minute.toString().padLeft(2, '0')}''').join('\n')}
''');

  // 3. 模拟不同时段的数据
  print('\n3. 模拟不同时段的请求延迟:');
  final testTimes = [
    DateTime(2025, 3, 10, 10, 0), // 工作日上午
    DateTime(2025, 3, 10, 14, 0), // 工作日午后高峰
    DateTime(2025, 3, 10, 22, 0), // 工作日夜间
    DateTime(2025, 3, 15, 14, 0), // 周末下午
  ];

  for (final time in testTimes) {
    const rawLatency = 150.0; // 原始延迟
    final adjustedLatency = analyzer.adjustValue(
      rawLatency,
      time,
      analysis,
    );

    print('''
时间: ${time.toString()}
- 原始延迟: ${rawLatency.toStringAsFixed(1)}ms
- 调整后: ${adjustedLatency.toStringAsFixed(1)}ms
- 特征: ${analysis.timeRanges.entries.where((e) => e.value.start.hour <= time.hour && e.value.end.hour > time.hour).map((e) => e.key).join(', ')}
''');
  }

  // 4. 模拟实时监控
  print('\n4. 模拟实时监控(5分钟):');
  var count = 0;
  final stopwatch = Stopwatch()..start();

  while (count < 30) {
    // 5分钟后停止
    if (stopwatch.elapsedMilliseconds >= count * 1000) {
      // 每秒更新一次
      final time = DateTime.now().add(Duration(minutes: count * 10));
      final hour = time.hour;

      // 生成延迟数据
      var latency = 100.0;
      if (hour >= 9 && hour <= 18) {
        latency += 50.0 + random.nextDouble() * 30.0;
      } else {
        latency += random.nextDouble() * 20.0;
      }

      analyzer.recordDataPoint(time, latency);
      count++;

      if (count % 6 == 0) {
        // 每分钟分析一次
        print('\n时间: $time');
        final result = await analyzer.analyze();
        final characteristic = result.timeRanges.entries.firstWhere(
          (e) => e.value.start.hour <= hour && e.value.end.hour > hour,
          orElse: () => MapEntry(
            TimeCharacteristic.normal,
            TimeRange(
              start: TimeOfDay(hour: hour, minute: 0),
              end: TimeOfDay(hour: hour + 1, minute: 0),
            ),
          ),
        );

        print('''
当前特征: ${characteristic.key}
活跃模式: ${result.detectedPatterns.length}
最显著模式: ${result.significance.entries.reduce((a, b) => a.value > b.value ? a : b).key}
''');
      }
    }

    await Future.delayed(const Duration(milliseconds: 100)); // 降低CPU使用
  }

  // 5. 分析最终结果
  print('\n5. 最终分析:');
  final finalAnalysis = await analyzer.analyze(
    start: now.subtract(const Duration(days: 7)),
    end: now,
  );

  print('''
检测到的季节性模式:
${finalAnalysis.detectedPatterns.map((p) => '''
- $p (显著性: ${(finalAnalysis.significance[p] ?? 0 * 100).toStringAsFixed(1)}%)''').join('\n')}

时间特征分布:
${finalAnalysis.timeRanges.entries.map((e) => '''
${e.key}:
  时段: ${e.value.start.hour}:${e.value.start.minute.toString().padLeft(2, '0')} - ${e.value.end.hour}:${e.value.end.minute.toString().padLeft(2, '0')}''').join('\n')}

分析总结:
- 检测模式数: ${finalAnalysis.detectedPatterns.length}
- 显著模式数: ${finalAnalysis.significance.entries.where((e) => e.value >= 0.1).length}
- 时间特征数: ${finalAnalysis.timeRanges.length}
''');

  analyzer.dispose();
  print('\n示例完成!\n');
}
