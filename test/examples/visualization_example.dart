import 'dart:async';
import 'dart:math';

import '../utils/monitor_visualizer.dart';

Future<void> main() async {
  final visualizer = MonitorVisualizer();
  final rnd = Random();

  print('开始收集测试数据...');

  // 模拟收集一天的测试数据
  final now = DateTime.now();
  for (var i = 0; i < 24; i++) {
    final timestamp = now.subtract(Duration(hours: 23 - i));

    // CPU使用率
    visualizer.addDataPoint(
      'CPU Usage (%)',
      50.0 + rnd.nextDouble() * 30.0,
      timestamp,
    );

    // 内存使用
    visualizer.addDataPoint(
      'Memory Usage (MB)',
      500.0 + rnd.nextDouble() * 200.0,
      timestamp,
    );

    // 测试执行时间
    visualizer.addDataPoint(
      'Test Execution Time (s)',
      120.0 + rnd.nextDouble() * 60.0,
      timestamp,
    );

    // 测试覆盖率
    visualizer.addDataPoint(
      'Test Coverage (%)',
      75.0 + rnd.nextDouble() * 15.0,
      timestamp,
    );

    // 失败测试数量
    visualizer.addDataPoint(
      'Failed Tests',
      rnd.nextDouble() * 5.0,
      timestamp,
    );
  }

  print('生成可视化报告...');

  // 生成报告
  await visualizer.generateReport();

  print('\n报告生成完成！可以在以下位置查看：');
  print('- HTML报告：test/reports/visualization/report.html');
  print('- JSON数据：test/reports/visualization/data.json');
  print('- ASCII图表：test/reports/visualization/ascii_charts.txt');

  // 展示一些示例统计数据
  print('\n简单统计示例：');
  print('----------------------------------------');

  // 模拟实时数据收集
  print('\n开始模拟实时数据收集 (10秒)...');
  var count = 0;
  final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    count++;

    // 添加实时CPU数据
    visualizer.addDataPoint(
      'Real-time CPU (%)',
      40.0 + rnd.nextDouble() * 40.0,
    );

    // 添加实时内存数据
    visualizer.addDataPoint(
      'Real-time Memory (MB)',
      450.0 + rnd.nextDouble() * 250.0,
    );

    print('已收集 $count 秒的数据...');
  });

  // 10秒后停止收集
  await Future.delayed(const Duration(seconds: 10));
  timer.cancel();

  // 生成最终报告
  print('\n生成最终报告...');
  await visualizer.generateReport();
  print('完成！');

  // 使用示例
  print('\n使用示例:');
  print('''
1. 查看HTML报告：
   open test/reports/visualization/report.html

2. 分析JSON数据：
   cat test/reports/visualization/data.json | jq .

3. 查看ASCII图表：
   cat test/reports/visualization/ascii_charts.txt

4. 监控指标：
   - CPU使用率
   - 内存使用
   - 测试执行时间
   - 测试覆盖率
   - 失败测试数量
   - 实时性能数据
''');
}

/*
要运行此示例：

1. 确保依赖已安装：
   dart pub get

2. 运行示例：
   dart run test/examples/visualization_example.dart

3. 查看生成的报告：
   - 打开 test/reports/visualization/report.html
   - 检查 test/reports/visualization/data.json
   - 查看 test/reports/visualization/ascii_charts.txt
*/
