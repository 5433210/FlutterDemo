/// Frame timing information
class FrameInfo {
  final Duration duration;
  final String operation;
  final int frameNumber;
  final DateTime timestamp;
  Duration? jitter;

  FrameInfo({
    required this.duration,
    required this.operation,
    required this.frameNumber,
    required this.timestamp,
  });

  bool hasHighJitter(PerformanceThresholds thresholds) =>
      jitter != null && jitter!.abs() > thresholds.maxJitterTime;

  bool isJanky(PerformanceThresholds thresholds) =>
      duration > thresholds.targetFrameTime;
}

/// Performance metrics collector
class PerformanceMetrics {
  static const _histogramBuckets = [8, 16, 32, 64, 128];
  final List<FrameInfo> frames = [];
  final List<Map<String, dynamic>> events = [];
  final PerformanceThresholds thresholds;
  final Map<String, double> _operationTrends = {};

  int _frameCount = 0;

  PerformanceMetrics({this.thresholds = const PerformanceThresholds()});

  Duration get averageFrameTime {
    if (frames.isEmpty) return Duration.zero;
    final total = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.duration.inMicroseconds,
    );
    return Duration(microseconds: total ~/ frames.length);
  }

  double get jankyFrameRatio => frames.isEmpty
      ? 0
      : frames.where((f) => f.isJanky(thresholds)).length / frames.length;

  void addFrame(Duration duration, String operation) {
    final frame = FrameInfo(
      duration: duration,
      operation: operation,
      frameNumber: ++_frameCount,
      timestamp: DateTime.now(),
    );

    if (frames.isNotEmpty) {
      final expectedDuration = thresholds.targetFrameTime;
      final actualDuration = frame.timestamp.difference(frames.last.timestamp);
      frame.jitter = actualDuration - expectedDuration;
    }

    frames.add(frame);
  }

  List<String> validatePerformance() {
    final issues = <String>[];

    if (jankyFrameRatio > thresholds.maxJankRate) {
      issues.add(
          'High jank rate: ${(jankyFrameRatio * 100).toStringAsFixed(1)}%');
    }

    if (averageFrameTime > thresholds.maxFrameTime) {
      issues
          .add('High average frame time: ${averageFrameTime.inMilliseconds}ms');
    }

    return issues;
  }
}

/// Performance thresholds configuration
class PerformanceThresholds {
  static const strict = PerformanceThresholds(
    targetFrameTime: Duration(milliseconds: 16),
    maxFrameTime: Duration(milliseconds: 20),
    maxJitterTime: Duration(milliseconds: 1),
    maxJankRate: 0.05,
    maxAverageFrameTime: 12.0,
    maxConsecutiveJanks: 2,
  );
  final Duration targetFrameTime;
  final Duration maxFrameTime;
  final Duration maxJitterTime;
  final double maxJankRate;
  final double maxAverageFrameTime;

  final int maxConsecutiveJanks;

  const PerformanceThresholds({
    this.targetFrameTime = const Duration(milliseconds: 16),
    this.maxFrameTime = const Duration(milliseconds: 32),
    this.maxJitterTime = const Duration(milliseconds: 2),
    this.maxJankRate = 0.1,
    this.maxAverageFrameTime = 16.0,
    this.maxConsecutiveJanks = 3,
  });
}
