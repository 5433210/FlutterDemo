import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring utility for M3Canvas optimization tracking
class PerformanceMonitor extends ChangeNotifier {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  // Frame rate tracking
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();

  double _currentFPS = 0.0;
  final List<double> _fpsHistory = [];
  final int _maxHistoryLength = 60; // Keep 60 seconds of history
  // Performance metrics
  final List<Duration> _frameTimeHistory = [];
  Duration _averageFrameTime = Duration.zero;

  Duration _maxFrameTime = Duration.zero;
  int _slowFrameCount = 0;
  // Memory tracking
  final List<int> _memoryHistory = [];
  // Widget rebuild tracking
  final Map<String, int> _widgetRebuildCounts = {};
  int _totalRebuilds = 0;

  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  Duration get averageFrameTime => _averageFrameTime;
  // Getters for current metrics
  double get currentFPS => _currentFPS;
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);
  Duration get maxFrameTime => _maxFrameTime;
  int get slowFrameCount => _slowFrameCount;
  int get totalRebuilds => _totalRebuilds;

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'currentFPS': _currentFPS,
      'averageFrameTime': '${_averageFrameTime.inMilliseconds}ms',
      'maxFrameTime': '${_maxFrameTime.inMilliseconds}ms',
      'slowFrameCount': _slowFrameCount,
      'totalRebuilds': _totalRebuilds,
      'topRebuildWidgets': _getTopRebuildWidgets(),
    };
  }

  /// Print detailed performance report
  void printPerformanceReport() {
    debugPrint('\n📊 ====== Performance Report ======');
    debugPrint('📈 Current FPS: ${_currentFPS.toStringAsFixed(1)}');
    debugPrint('⏱️ Average Frame Time: ${_averageFrameTime.inMilliseconds}ms');
    debugPrint('🐌 Max Frame Time: ${_maxFrameTime.inMilliseconds}ms');
    debugPrint('❌ Slow Frames: $_slowFrameCount');
    debugPrint('🔄 Total Rebuilds: $_totalRebuilds');

    if (_widgetRebuildCounts.isNotEmpty) {
      debugPrint('🏆 Top Rebuild Widgets:');
      final top = _getTopRebuildWidgets();
      for (final widget in top) {
        debugPrint('   ${widget['widget']}: ${widget['rebuilds']} rebuilds');
      }
    }

    if (_fpsHistory.isNotEmpty) {
      final avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      debugPrint(
          '📊 Average FPS (last ${_fpsHistory.length}s): ${avgFPS.toStringAsFixed(1)}');
    }

    debugPrint('================================\n');
  }

  /// Reset all metrics
  void reset() {
    _frameCount = 0;
    _lastFrameTime = DateTime.now();
    _currentFPS = 0.0;
    _fpsHistory.clear();
    _frameTimeHistory.clear();
    _averageFrameTime = Duration.zero;
    _maxFrameTime = Duration.zero;
    _slowFrameCount = 0;
    _widgetRebuildCounts.clear();
    _totalRebuilds = 0;
    _memoryHistory.clear();
    notifyListeners();
  }

  /// Start monitoring mode with frame callbacks
  void startMonitoring() {
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);
  }

  /// Stop monitoring
  void stopMonitoring() {
    // Note: SchedulerBinding doesn't provide a direct way to remove callbacks
    // The callback will naturally stop when not rescheduled
  }

  /// Track frame rendering
  void trackFrame() {
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameTime);

    if (elapsed.inSeconds >= 1) {
      _currentFPS = _frameCount / elapsed.inSeconds;

      // Add to history
      _fpsHistory.add(_currentFPS);
      if (_fpsHistory.length > _maxHistoryLength) {
        _fpsHistory.removeAt(0);
      }

      // Log performance issues
      if (_currentFPS < 30) {
        debugPrint(
            '⚠️ Low FPS detected: ${_currentFPS.toStringAsFixed(1)} FPS');
      }

      debugPrint('📊 Canvas FPS: ${_currentFPS.toStringAsFixed(1)}');

      _frameCount = 0;
      _lastFrameTime = now;
      notifyListeners();
    }
  }

  /// Track frame time for individual frames
  void trackFrameTime(Duration frameTime) {
    _frameTimeHistory.add(frameTime);
    if (_frameTimeHistory.length > 100) {
      _frameTimeHistory.removeAt(0);
    }

    // Calculate average
    if (_frameTimeHistory.isNotEmpty) {
      final total = _frameTimeHistory.fold<Duration>(
        Duration.zero,
        (prev, element) => prev + element,
      );
      _averageFrameTime = Duration(
        microseconds: total.inMicroseconds ~/ _frameTimeHistory.length,
      );
    }

    // Track max frame time
    if (frameTime > _maxFrameTime) {
      _maxFrameTime = frameTime;
    }

    // Count slow frames (> 16.67ms for 60FPS)
    if (frameTime.inMicroseconds > 16670) {
      _slowFrameCount++;
      debugPrint('🐌 Slow frame detected: ${frameTime.inMilliseconds}ms');
    }
  }

  /// Track widget rebuilds
  void trackWidgetRebuild(String widgetName) {
    _widgetRebuildCounts[widgetName] =
        (_widgetRebuildCounts[widgetName] ?? 0) + 1;
    _totalRebuilds++;

    // Log excessive rebuilds
    final count = _widgetRebuildCounts[widgetName]!;
    if (count % 10 == 0) {
      debugPrint('🔄 Widget $widgetName rebuilt $count times');
    }
  }

  List<Map<String, dynamic>> _getTopRebuildWidgets() {
    final entries = _widgetRebuildCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => {
              'widget': e.key,
              'rebuilds': e.value,
            })
        .toList();
  }

  void _onFrameEnd(Duration timeStamp) {
    trackFrame();
    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);
  }
}

/// Performance overlay widget for development
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

/// Widget wrapper that tracks rebuilds
class PerformanceTrackedWidget extends StatelessWidget {
  final Widget child;
  final String widgetName;
  final PerformanceMonitor? monitor;

  const PerformanceTrackedWidget({
    super.key,
    required this.child,
    required this.widgetName,
    this.monitor,
  });

  @override
  Widget build(BuildContext context) {
    // Track this rebuild
    (monitor ?? PerformanceMonitor()).trackWidgetRebuild(widgetName);
    return child;
  }
}

/// Mixin for tracking widget performance
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  PerformanceMonitor get performanceMonitor => PerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    // Track frame rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performanceMonitor.trackFrame();
    });

    // Track widget rebuild
    performanceMonitor.trackWidgetRebuild(widget.runtimeType.toString());

    return buildTracked(context);
  }

  /// Override this instead of build()
  Widget buildTracked(BuildContext context);
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && kDebugMode)
          Positioned(
            top: 50,
            right: 16,
            child: _buildPerformanceDisplay(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _monitor.removeListener(_onPerformanceUpdate);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _monitor.addListener(_onPerformanceUpdate);
  }

  Widget _buildFPSIndicator() {
    final fps = _monitor.currentFPS;
    Color color;
    if (fps >= 55) {
      color = Colors.green;
    } else if (fps >= 30) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'FPS: ${fps.toStringAsFixed(1)}',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildPerformanceDisplay() {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Performance Monitor',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            _buildFPSIndicator(),
            const SizedBox(height: 2),
            Text(
              'Rebuilds: ${_monitor.totalRebuilds}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Avg Frame: ${_monitor.averageFrameTime.inMilliseconds}ms',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _onPerformanceUpdate() {
    if (mounted) setState(() {});
  }
}
