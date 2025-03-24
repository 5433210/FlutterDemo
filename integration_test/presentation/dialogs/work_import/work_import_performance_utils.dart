import 'dart:math' as math;

/// Frame pattern analysis
class FramePattern {
  final List<bool> pattern;
  final int count;
  final double percentage;

  FramePattern({
    required this.pattern,
    required this.count,
    required this.percentage,
  });

  String get patternString => pattern.map((j) => j ? 'J' : 'N').join();
}

/// Performance visualization helper
class PerformanceVisualizer {
  static const _barChar = '█';
  static const _defaultBarWidth = 50;

  /// Analyzes frame patterns
  static List<FramePattern> analyzePatterns(
    List<bool> frames, {
    int patternLength = 3,
  }) {
    if (frames.length < patternLength) return [];

    final patterns = <String, int>{};
    for (var i = 0; i <= frames.length - patternLength; i++) {
      final pattern = frames.sublist(i, i + patternLength);
      final key = pattern.map((j) => j ? 'J' : 'N').join();
      patterns[key] = (patterns[key] ?? 0) + 1;
    }

    final totalPatterns = patterns.values.reduce((a, b) => a + b);
    return patterns.entries
        .map((e) => FramePattern(
              pattern: e.key.split('').map((c) => c == 'J').toList(),
              count: e.value,
              percentage: e.value * 100 / totalPatterns,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Creates a horizontal bar chart
  static String createBarChart({
    required Map<String, double> data,
    int width = _defaultBarWidth,
    bool showPercentages = true,
    String? title,
  }) {
    if (data.isEmpty) return '';

    final buffer = StringBuffer();
    if (title != null) {
      buffer.writeln(title);
      buffer.writeln('=' * title.length);
    }

    final maxValue = data.values.reduce(math.max);
    final maxLabelLength = data.keys.map((k) => k.length).reduce(math.max);

    for (final entry in data.entries) {
      final label = entry.key.padRight(maxLabelLength);
      final value = entry.value;
      final barLength = (value * width / maxValue).round();
      final bar = _barChar * barLength;

      if (showPercentages) {
        final percentage = (value * 100 / maxValue).toStringAsFixed(1);
        buffer.writeln('$label $bar ($percentage%)');
      } else {
        buffer.writeln('$label $bar');
      }
    }

    return buffer.toString();
  }

  /// Creates a heat map visualization
  static String createHeatMap({
    required List<double> values,
    int width = 10,
    List<String> intensityChars = const ['░', '▒', '▓', '█'],
  }) {
    if (values.isEmpty) return '';

    final buffer = StringBuffer();
    final normalizedValues = _normalizeValues(values);
    final height = (values.length / width).ceil();

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        if (index >= values.length) break;

        final intensity = normalizedValues[index];
        final charIndex = (intensity * (intensityChars.length - 1)).round();
        buffer.write(intensityChars[charIndex]);
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Creates a time series visualization
  static String createTimeline({
    required List<bool> events,
    String normalChar = '·',
    String anomalyChar = '!',
    int width = 80,
  }) {
    if (events.isEmpty) return '';

    final buffer = StringBuffer();
    final step = math.max(1, events.length ~/ width);

    for (var i = 0; i < events.length; i += step) {
      final slice = events.skip(i).take(step);
      final hasAnomaly = slice.any((e) => e);
      buffer.write(hasAnomaly ? anomalyChar : normalChar);
    }

    buffer.writeln('\nLegend: $normalChar Normal  $anomalyChar Anomaly');
    return buffer.toString();
  }

  /// Detect performance outliers using IQR method
  static List<int> detectOutliers(List<num> values) {
    if (values.length < 4) return [];

    final sorted = List<num>.from(values)..sort();
    final q1 = _quartile(sorted, 0.25);
    final q3 = _quartile(sorted, 0.75);
    final iqr = q3 - q1;
    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;

    return List.generate(values.length, (i) => i)
        .where((i) => values[i] < lowerBound || values[i] > upperBound)
        .toList();
  }

  static List<double> _normalizeValues(List<double> values) {
    if (values.isEmpty) return [];
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = max - min;
    return range > 0
        ? values.map((v) => (v - min) / range).toList()
        : List.filled(values.length, 0.5);
  }

  static double _quartile(List<num> values, double percentile) {
    final index = (values.length * percentile).round();
    return values[index].toDouble();
  }
}
