import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Utility class to track memory usage during tests
class MemoryTracker {
  final List<int> _snapshots = [];
  final WidgetTester tester;

  MemoryTracker(this.tester);

  void dispose() {
    _snapshots.clear();
  }

  bool hasMemoryLeak() {
    if (_snapshots.length < 2) return false;

    // Check if memory usage is trending upward
    final firstHalf = _snapshots.sublist(0, _snapshots.length ~/ 2);
    final secondHalf = _snapshots.sublist(_snapshots.length ~/ 2);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    // Consider it a leak if memory increased by more than 20%
    return secondAvg > firstAvg * 1.2;
  }

  Future<void> initialize() async {
    await tester.pump();
    _snapshots.clear();
  }

  Future<void> takeSnapshot() async {
    await tester.pump();
    final memory = await _getCurrentMemory();
    _snapshots.add(memory);
  }

  Future<int> _getCurrentMemory() async {
    return Future.value(0); // Placeholder for actual memory tracking
  }
}

/// Utility class to track performance metrics during tests
class PerformanceProfiler {
  final _metrics = <String, double>{};
  final _frameTimestamps = <int>[];
  bool _isActive = false;
  late final Timer _profileTimer;

  Map<String, double> getMetrics() => Map.unmodifiable(_metrics);

  void startProfiling() {
    _isActive = true;
    _frameTimestamps.clear();
    _metrics.clear();

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    _profileTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _calculateMetrics(),
    );
  }

  void stopProfiling() {
    _isActive = false;
    _profileTimer.cancel();
    _calculateMetrics();
  }

  void _calculateMetrics() {
    if (_frameTimestamps.length < 2) return;

    final frameTimes = <int>[];
    for (var i = 1; i < _frameTimestamps.length; i++) {
      frameTimes.add(_frameTimestamps[i] - _frameTimestamps[i - 1]);
    }

    // Calculate average frame time
    final avgFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
    _metrics['avg_frame_time_ms'] = avgFrameTime / 1000;

    // Calculate jank percentage (frames over 16ms)
    final jankFrames = frameTimes.where((time) => time > 16000).length;
    _metrics['jank_percentage'] = (jankFrames / frameTimes.length) * 100;

    // Calculate max frame time
    final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
    _metrics['max_frame_time_ms'] = maxFrameTime / 1000;
  }

  void _onFrame(Duration timestamp) {
    if (_isActive) {
      _frameTimestamps.add(timestamp.inMicroseconds);
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    }
  }
}
