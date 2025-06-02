/// 性能统计数据
class PerformanceStats {
  final double frameRate;
  final double frameTime;
  final double elementsPerFrame;
  final double cacheHitRate;

  PerformanceStats({
    required this.frameRate,
    required this.frameTime,
    required this.elementsPerFrame,
    required this.cacheHitRate,
  });

  @override
  String toString() {
    return 'PerformanceStats(frameRate: ${frameRate.toStringAsFixed(1)} FPS, '
        'frameTime: ${frameTime.toStringAsFixed(1)} ms, '
        'elementsPerFrame: ${elementsPerFrame.toStringAsFixed(1)}, '
        'cacheHitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 单帧渲染数据
class RenderFrame {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int elementCount;
  final int cacheHits;
  final int cacheMisses;

  RenderFrame({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.elementCount,
    required this.cacheHits,
    required this.cacheMisses,
  });
}

/// 渲染性能监控器
///
/// 按照设计文档要求实现的性能监控组件
class RenderPerformanceMonitor {
  final List<RenderFrame> _frames = [];
  final int _maxFrames = 100; // 保留最近100帧的数据

  DateTime? _frameStartTime;
  int _elementCount = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// 检查是否有性能问题
  List<String> checkPerformanceIssues() {
    final issues = <String>[];
    final stats = getRecentStats();

    // 检查帧率
    if (stats.frameRate < 30) {
      issues.add('Low frame rate: ${stats.frameRate.toStringAsFixed(1)} FPS');
    }

    // 检查帧时间
    if (stats.frameTime > 33.3) {
      // 超过33.3ms意味着低于30FPS
      issues.add('High frame time: ${stats.frameTime.toStringAsFixed(1)} ms');
    }

    // 检查缓存命中率
    if (stats.cacheHitRate < 0.5) {
      issues.add(
          'Low cache hit rate: ${(stats.cacheHitRate * 100).toStringAsFixed(1)}%');
    }

    return issues;
  }

  /// 清除性能数据
  void clear() {
    _frames.clear();
  }

  /// 结束帧渲染计时
  void endFrame() {
    if (_frameStartTime == null) return;

    final endTime = DateTime.now();
    final frameDuration = endTime.difference(_frameStartTime!);

    final frame = RenderFrame(
      startTime: _frameStartTime!,
      endTime: endTime,
      duration: frameDuration,
      elementCount: _elementCount,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
    );

    _frames.add(frame);

    // 保持最大帧数限制
    while (_frames.length > _maxFrames) {
      _frames.removeAt(0);
    }

    _frameStartTime = null;
  }

  /// 获取平均每帧元素数
  double getAverageElementsPerFrame() {
    if (_frames.isEmpty) return 0.0;

    final totalElements =
        _frames.map((frame) => frame.elementCount).reduce((a, b) => a + b);

    return totalElements / _frames.length;
  }

  /// 获取平均帧率
  double getAverageFrameRate() {
    if (_frames.length < 2) return 0.0;

    final totalDuration =
        _frames.last.endTime.difference(_frames.first.startTime);
    final totalSeconds = totalDuration.inMicroseconds / 1000000.0;

    return _frames.length / totalSeconds;
  }

  /// 获取平均帧时间（毫秒）
  double getAverageFrameTime() {
    if (_frames.isEmpty) return 0.0;

    final totalMicroseconds = _frames
        .map((frame) => frame.duration.inMicroseconds)
        .reduce((a, b) => a + b);

    return totalMicroseconds / _frames.length / 1000.0;
  }

  /// 获取缓存命中率
  double getCacheHitRate() {
    if (_frames.isEmpty) return 0.0;

    final totalHits =
        _frames.map((frame) => frame.cacheHits).reduce((a, b) => a + b);

    final totalMisses =
        _frames.map((frame) => frame.cacheMisses).reduce((a, b) => a + b);

    final totalRequests = totalHits + totalMisses;
    return totalRequests > 0 ? totalHits / totalRequests : 0.0;
  }

  /// 获取最近N帧的平均性能
  PerformanceStats getRecentStats([int frameCount = 10]) {
    final recentFrames = _frames.length > frameCount
        ? _frames.sublist(_frames.length - frameCount)
        : _frames;

    if (recentFrames.isEmpty) {
      return PerformanceStats(
        frameRate: 0.0,
        frameTime: 0.0,
        elementsPerFrame: 0.0,
        cacheHitRate: 0.0,
      );
    }

    final avgFrameTime = recentFrames
            .map((frame) => frame.duration.inMicroseconds / 1000.0)
            .reduce((a, b) => a + b) /
        recentFrames.length;

    final avgElements = recentFrames
            .map((frame) => frame.elementCount)
            .reduce((a, b) => a + b) /
        recentFrames.length;

    final totalHits =
        recentFrames.map((frame) => frame.cacheHits).reduce((a, b) => a + b);

    final totalMisses =
        recentFrames.map((frame) => frame.cacheMisses).reduce((a, b) => a + b);

    final totalRequests = totalHits + totalMisses;
    final hitRate = totalRequests > 0 ? totalHits / totalRequests : 0.0;

    final frameRate = 1000.0 / avgFrameTime; // 从帧时间计算帧率

    return PerformanceStats(
      frameRate: frameRate,
      frameTime: avgFrameTime,
      elementsPerFrame: avgElements,
      cacheHitRate: hitRate,
    );
  }

  /// 记录缓存命中
  void recordCacheHit() {
    _cacheHits++;
  }

  /// 记录缓存未命中
  void recordCacheMiss() {
    _cacheMisses++;
  }

  /// 记录元素渲染
  void recordElementRender() {
    _elementCount++;
  }

  /// 开始帧渲染计时
  void startFrame() {
    _frameStartTime = DateTime.now();
    _elementCount = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}
