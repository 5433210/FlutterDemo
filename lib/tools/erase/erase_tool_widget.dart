import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/performance/frame_logger.dart';
import '../../utils/performance/memory_tracker.dart';
import '../../widgets/character_edit/character_edit_panel.dart';

/// 擦除工具组件
/// 提供字符擦除功能的入口点
class EraseToolWidget extends StatefulWidget {
  final ui.Image image;
  final String workId;
  final Function(Map<String, dynamic>)? onComplete;

  const EraseToolWidget({
    Key? key,
    required this.image,
    required this.workId,
    this.onComplete,
  }) : super(key: key);

  @override
  State<EraseToolWidget> createState() => _EraseToolWidgetState();
}

class _EraseToolWidgetState extends State<EraseToolWidget> {
  bool _performanceMonitoringEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字符擦除'),
        actions: [
          // 性能监控开关
          IconButton(
            icon: Icon(
              _performanceMonitoringEnabled
                  ? Icons.speed
                  : Icons.speed_outlined,
            ),
            onPressed: _togglePerformanceMonitoring,
            tooltip: '性能监控',
          ),
        ],
      ),
      body: CharacterEditPanel(
        image: widget.image,
        workId: widget.workId,
        onEditComplete: _handleEditComplete,
      ),
    );
  }

  @override
  void dispose() {
    // 确保停止性能监控
    _stopPerformanceMonitoring();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 延迟启动性能监控，避免启动时的抖动影响测量
    Future.delayed(const Duration(seconds: 1), () {
      if (_performanceMonitoringEnabled) {
        _startPerformanceMonitoring();
      }
    });
  }

  // 处理编辑完成
  void _handleEditComplete(Map<String, dynamic> result) {
    widget.onComplete?.call(result);
  }

  // 启动性能监控
  void _startPerformanceMonitoring() {
    FrameLogger.start();
    MemoryTracker.start();
  }

  // 停止性能监控
  void _stopPerformanceMonitoring() {
    FrameLogger.stop();
    MemoryTracker.stop();
  }

  // 切换性能监控
  void _togglePerformanceMonitoring() {
    setState(() {
      _performanceMonitoringEnabled = !_performanceMonitoringEnabled;

      if (_performanceMonitoringEnabled) {
        _startPerformanceMonitoring();
      } else {
        _stopPerformanceMonitoring();
      }
    });
  }
}
