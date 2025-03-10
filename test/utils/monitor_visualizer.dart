import 'dart:math' as math;

/// 图表数据点
class DataPoint {
  final DateTime timestamp;
  final double value;
  final String? label;

  const DataPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });
}

/// 监控可视化器
class MonitorVisualizer {
  final VisualizerConfig config;
  final _dataPoints = <String, List<DataPoint>>{};
  String? _currentMetric;

  MonitorVisualizer({VisualizerConfig? config})
      : config = config ?? const VisualizerConfig();

  /// 添加数据点
  void addDataPoint(String metric, num value, [DateTime? timestamp]) {
    timestamp ??= DateTime.now();
    final points = _dataPoints.putIfAbsent(metric, () => []);
    points.add(DataPoint(
      timestamp: timestamp,
      value: value.toDouble(),
    ));
    _currentMetric = metric;
  }

  /// 清理数据
  void clear() {
    _dataPoints.clear();
    _currentMetric = null;
  }

  /// 生成SVG图表
  String generateChart([String? metric]) {
    metric ??= _currentMetric;
    if (metric == null || !_dataPoints.containsKey(metric)) return '';

    final data = _dataPoints[metric]!;
    if (data.isEmpty) return '';

    // 计算数据范围
    final minTime = data.first.timestamp;
    final maxTime = data.last.timestamp;
    final timeRange = maxTime.difference(minTime).inMilliseconds.toDouble();

    var minValue = data.first.value;
    var maxValue = data.first.value;
    for (final point in data) {
      minValue = math.min(minValue, point.value);
      maxValue = math.max(maxValue, point.value);
    }
    final valueRange = maxValue - minValue;

    // 图表尺寸
    final plotWidth = (config.width - 2 * config.padding).toDouble();
    final plotHeight = (config.height - 2 * config.padding).toDouble();

    // 生成路径
    final points = <String>[];
    for (final point in data) {
      final x = config.padding.toDouble() +
          ((point.timestamp.difference(minTime).inMilliseconds / timeRange) *
              plotWidth);
      final y = config.height.toDouble() -
          config.padding.toDouble() -
          (((point.value - minValue) / valueRange) * plotHeight);
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }

    // 生成SVG
    return '''
    <svg width="${config.width}" height="${config.height}" xmlns="http://www.w3.org/2000/svg">
      <title>$metric Monitor Chart</title>
      
      <!-- 背景网格 -->
      <g stroke="${config.gridColor}" stroke-width="1">
        ${_generateGrid(plotWidth, plotHeight)}
      </g>

      <!-- 数据曲线 -->
      <polyline
        points="${points.join(' ')}"
        fill="none"
        stroke="${config.lineColor}"
        stroke-width="2"
      />

      <!-- 坐标轴 -->
      ${_generateAxes(minValue, maxValue, minTime, maxTime)}
    </svg>
    ''';
  }

  /// 生成报告
  Map<String, dynamic> generateReport() {
    return {
      'metrics': _dataPoints.map((key, value) => MapEntry(key, {
            'count': value.length,
            'latest': value.isEmpty ? null : value.last.value,
            'min': value.isEmpty
                ? null
                : value.map((p) => p.value).reduce(math.min),
            'max': value.isEmpty
                ? null
                : value.map((p) => p.value).reduce(math.max),
            'avg': value.isEmpty
                ? null
                : value.map((p) => p.value).reduce((a, b) => a + b) /
                    value.length,
          })),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  /// 生成坐标轴标签
  String _generateAxes(
    double minValue,
    double maxValue,
    DateTime minTime,
    DateTime maxTime,
  ) {
    final labels = <String>[];
    const labelCount = 5;

    // Y轴标签
    for (var i = 0; i <= labelCount; i++) {
      final value = minValue + ((maxValue - minValue) * i / labelCount);
      final y = config.height.toDouble() -
          config.padding.toDouble() -
          ((value - minValue) / (maxValue - minValue)) *
              (config.height - 2 * config.padding);
      labels.add('''
        <text x="${config.padding - 5}" y="$y" 
              text-anchor="end" alignment-baseline="middle"
              fill="${config.textColor}" font-size="12">
          ${value.toStringAsFixed(1)}
        </text>
      ''');
    }

    // X轴标签
    for (var i = 0; i <= labelCount; i++) {
      final time = DateTime.fromMillisecondsSinceEpoch(
        minTime.millisecondsSinceEpoch +
            ((maxTime.millisecondsSinceEpoch - minTime.millisecondsSinceEpoch) *
                    i /
                    labelCount)
                .round(),
      );
      final x = config.padding.toDouble() +
          ((config.width - 2 * config.padding) * i / labelCount);
      labels.add('''
        <text x="$x" y="${config.height - config.padding + 20}"
              text-anchor="middle"
              fill="${config.textColor}" font-size="12">
          ${_formatTime(time)}
        </text>
      ''');
    }

    return labels.join('\n');
  }

  /// 生成网格线
  String _generateGrid(double width, double height) {
    final lines = <String>[];
    const gridCount = 10;

    // 横线
    for (var i = 0; i <= gridCount; i++) {
      final y = config.padding + (height * i / gridCount);
      lines.add('<line x1="${config.padding}" y1="$y" '
          'x2="${config.width - config.padding}" y2="$y" />');
    }

    // 竖线
    for (var i = 0; i <= gridCount; i++) {
      final x = config.padding + (width * i / gridCount);
      lines.add('<line x1="$x" y1="${config.padding}" '
          'x2="$x" y2="${config.height - config.padding}" />');
    }

    return lines.join('\n');
  }
}

/// 可视化配置
class VisualizerConfig {
  final int width;
  final int height;
  final int padding;
  final String gridColor;
  final String lineColor;
  final String textColor;
  final String outputPath;

  const VisualizerConfig({
    this.width = 800,
    this.height = 400,
    this.padding = 40,
    this.gridColor = '#eee',
    this.lineColor = '#2196F3',
    this.textColor = '#666',
    this.outputPath = 'monitor_report.svg',
  });
}
