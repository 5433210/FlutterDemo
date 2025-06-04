import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'enhanced_performance_tracker.dart';

/// Custom painter for frame time chart
class FrameTimeChartPainter extends CustomPainter {
  final List<double> data;
  final double targetFrameTime;
  final double warningFrameTime;
  
  FrameTimeChartPainter({
    required this.data,
    required this.targetFrameTime,
    required this.warningFrameTime,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final maxFrameTime = math.max(35.0, data.reduce(math.max));
    
    // Draw target line
    final targetPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final targetY = size.height * (1 - targetFrameTime / maxFrameTime);
    canvas.drawLine(Offset(0, targetY), Offset(size.width, targetY), targetPaint);
    
    // Draw warning line
    final warningPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final warningY = size.height * (1 - warningFrameTime / maxFrameTime);
    canvas.drawLine(Offset(0, warningY), Offset(size.width, warningY), warningPaint);
    
    // Draw data
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / math.max(data.length - 1, 1)) * size.width;
      final y = size.height * (1 - data[i] / maxFrameTime);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for mini chart
class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double targetValue;
  
  MiniChartPainter({
    required this.data,
    required this.color,
    required this.targetValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final targetPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw target line
    final targetY = size.height * (1 - (targetValue / 100));
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      targetPaint,
    );
    
    // Draw data line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height * (1 - (data[i] / 100));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for performance chart
class PerformanceChartPainter extends CustomPainter {
  final List<double> data;
  final double animationValue;
  final double targetFPS;
  final double warningFPS;
  final double criticalFPS;
  
  PerformanceChartPainter({
    required this.data,
    required this.animationValue,
    required this.targetFPS,
    required this.warningFPS,
    required this.criticalFPS,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    // Background zones
    _drawPerformanceZones(canvas, size);
    
    // Data line
    _drawDataLine(canvas, size);
    
    // Grid lines
    _drawGridLines(canvas, size);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
  
  void _drawDataLine(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final visibleDataCount = (data.length * animationValue).round();
    
    for (int i = 0; i < visibleDataCount; i++) {
      final x = (i / math.max(data.length - 1, 1)) * size.width;
      final y = size.height * (1 - data[i] / 70); // Max scale to 70 FPS
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    // Horizontal grid lines
    for (double fps = 0; fps <= 70; fps += 10) {
      final y = size.height * (1 - fps / 70);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Vertical grid lines
    for (int i = 0; i <= 10; i++) {
      final x = (i / 10) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }
  
  void _drawPerformanceZones(Canvas canvas, Size size) {
    final excellentPaint = Paint()..color = Colors.green.withValues(alpha: 0.1);
    final goodPaint = Paint()..color = Colors.orange.withValues(alpha: 0.1);
    final poorPaint = Paint()..color = Colors.red.withValues(alpha: 0.1);
    
    // Excellent zone (target to max)
    final excellentRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height * (1 - targetFPS / 70),
    );
    canvas.drawRect(excellentRect, excellentPaint);
    
    // Good zone (warning to target)
    final goodRect = Rect.fromLTWH(
      0,
      size.height * (1 - targetFPS / 70),
      size.width,
      size.height * ((targetFPS - warningFPS) / 70),
    );
    canvas.drawRect(goodRect, goodPaint);
    
    // Poor zone (critical to warning)
    final poorRect = Rect.fromLTWH(
      0,
      size.height * (1 - warningFPS / 70),
      size.width,
      size.height * ((warningFPS - criticalFPS) / 70),
    );
    canvas.drawRect(poorRect, poorPaint);
  }
}

/// Performance Dashboard Widget - Implements Task 5.2: Visualization
/// Provides real-time performance monitoring UI with visual indicators
class PerformanceDashboard extends StatefulWidget {
  final bool expanded;
  final double width;
  final double height;
  
  const PerformanceDashboard({
    super.key,
    this.expanded = false,
    this.width = 400,
    this.height = 600,
  });

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard>
    with TickerProviderStateMixin {
  final EnhancedPerformanceTracker _tracker = EnhancedPerformanceTracker();
  Timer? _updateTimer;
  PerformanceReport? _currentReport;
  
  // Animation controllers for visual effects
  late AnimationController _pulseController;
  late AnimationController _chartController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chartAnimation;
  
  // Chart data
  final List<double> _fpsChartData = [];
  final List<double> _frameTimeChartData = [];
  final int _maxChartPoints = 60; // 1 minute of data points
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.expanded
          ? _buildExpandedDashboard()
          : _buildCompactDashboard(),
    );
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    _chartController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPerformanceTracking();
  }
  
  Widget _buildCompactDashboard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 8),
          _buildFPSIndicator(),
          const SizedBox(height: 8),
          _buildPerformanceGradeIndicator(),
          const SizedBox(height: 8),
          _buildMiniChart(),
        ],
      ),
    );
  }
  
  Widget _buildControlButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildControlButton(
                'Create Baseline',
                Icons.bookmark_add,
                () => _createBaseline(),
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                'Reset Data',
                Icons.refresh,
                () => _resetData(),
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                'Export',
                Icons.download,
                () => _exportData(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardHeader() {
    return Row(
      children: [
        const Icon(
          Icons.speed,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Performance Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildEventRow(PerformanceEvent event) {
    final severityInfo = _getSeverityInfo(event.severity);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            severityInfo.icon,
            color: severityInfo.color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatEventDescription(event),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            _formatEventTime(event.timestamp),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandedDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMetricsGrid(),
                  const SizedBox(height: 16),
                  _buildPerformanceChart(),
                  const SizedBox(height: 16),
                  _buildFrameTimeChart(),
                  const SizedBox(height: 16),
                  _buildPerformanceEvents(),
                  const SizedBox(height: 16),
                  _buildControlPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFPSIndicator() {
    final fps = _currentReport?.averageFps ?? 0.0;
    final color = _getFPSColor(fps);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speed,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${fps.toStringAsFixed(1)} FPS',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildTrendIndicator(fps),
        ],
      ),
    );
  }
  
  Widget _buildFrameTimeChart() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frame Time (ms)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: FrameTimeChartPainter(
                data: _frameTimeChartData,
                targetFrameTime: 16.67, // 60 FPS target
                warningFrameTime: 22.0,  // 45 FPS
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingWidget() {
    return const SizedBox(
      height: 100,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
        ),
      ),
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsGrid() {
    if (_currentReport == null) {
      return _buildLoadingWidget();
    }
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricCard(
          'Average FPS',
          _currentReport!.averageFps.toStringAsFixed(1),
          Icons.speed,
          _getFPSColor(_currentReport!.averageFps),
        ),
        _buildMetricCard(
          'Frame Time',
          '${_currentReport!.averageFrameTime.inMilliseconds}ms',
          Icons.timer,
          _getFrameTimeColor(_currentReport!.averageFrameTime.inMilliseconds),
        ),
        _buildMetricCard(
          'Jank %',
          '${_currentReport!.jankPercentage.toStringAsFixed(1)}%',
          Icons.warning,
          _getJankColor(_currentReport!.jankPercentage),
        ),
        _buildMetricCard(
          'Critical Events',
          '${_currentReport!.criticalEvents}',
          Icons.error,
          _currentReport!.criticalEvents > 0 ? Colors.red : Colors.green,
        ),
      ],
    );
  }
  
  Widget _buildMiniChart() {
    if (_fpsChartData.isEmpty) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'Collecting data...',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: MiniChartPainter(
          data: _fpsChartData,
          color: Colors.cyan,
          targetValue: 60.0,
        ),
        size: Size.infinite,
      ),
    );
  }
  
  Widget _buildPerformanceChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FPS Over Time',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: PerformanceChartPainter(
                    data: _fpsChartData,
                    animationValue: _chartAnimation.value,
                    targetFPS: 60.0,
                    warningFPS: 45.0,
                    criticalFPS: 30.0,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceEvents() {
    final events = _tracker.performanceEvents.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Performance Events',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Text(
              'No recent events',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...events.map((event) => _buildEventRow(event)),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceGradeIndicator() {
    final grade = _currentReport?.performanceGrade ?? PerformanceGrade.unknown;
    final gradeInfo = _getGradeInfo(grade);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gradeInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gradeInfo.color, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            gradeInfo.icon,
            color: gradeInfo.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            gradeInfo.label,
            style: TextStyle(
              color: gradeInfo.color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendIndicator(double fps) {
    // Simple trend calculation based on recent data
    if (_fpsChartData.length < 2) {
      return const SizedBox.shrink();
    }
    
    // Get the last 5 items (or all if less than 5)
    final recent = _fpsChartData.length <= 5 
        ? _fpsChartData 
        : _fpsChartData.sublist(_fpsChartData.length - 5);
    final isIncreasing = recent.last > recent.first;
    
    return Icon(
      isIncreasing ? Icons.trending_up : Icons.trending_down,
      color: isIncreasing ? Colors.green : Colors.red,
      size: 16,
    );
  }
  
  // Control methods
  void _createBaseline() {
    _tracker.createPerformanceBaseline(
      'Manual Baseline ${DateTime.now().toIso8601String().substring(11, 19)}',
      description: 'User-created baseline from dashboard',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance baseline created'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
    void _exportData() async {
    try {
      final data = await _tracker.exportPerformanceData();
      // In a real app, you would save this to a file or share it
      debugPrint('Performance data exported: ${data.length} characters');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Performance data exported to console'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Event formatting
  String _formatEventDescription(PerformanceEvent event) {
    switch (event.type) {
      case PerformanceEventType.frameJank:
        return 'Frame jank detected (${event.data['frameTime']}ms)';
      case PerformanceEventType.operationStart:
        return 'Started ${event.data['operation']}';
      case PerformanceEventType.operationEnd:
        return 'Completed ${event.data['operation']} (${event.data['averageFps']?.toStringAsFixed(1)} FPS)';
      case PerformanceEventType.baselineCreated:
        return 'Baseline "${event.data['baselineName']}" created';
      case PerformanceEventType.performanceRegression:
        return 'Performance regression: ${event.data['regressionPercentage']?.toStringAsFixed(1)}% drop';
      case PerformanceEventType.memoryWarning:
        return 'Memory warning';
      case PerformanceEventType.cpuSpike:
        return 'CPU spike detected';
    }
  }
  
  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
  
  // Color helper methods
  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.orange;
    if (fps >= 30) return Colors.red;
    return Colors.red.shade900;
  }
  
  Color _getFrameTimeColor(int frameTimeMs) {
    if (frameTimeMs <= 17) return Colors.green;
    if (frameTimeMs <= 22) return Colors.orange;
    return Colors.red;
  }
  
  // Grade information
  ({String label, Color color, IconData icon}) _getGradeInfo(PerformanceGrade grade) {
    switch (grade) {
      case PerformanceGrade.excellent:
        return (label: 'Excellent', color: Colors.green, icon: Icons.star);
      case PerformanceGrade.good:
        return (label: 'Good', color: Colors.lightGreen, icon: Icons.thumb_up);
      case PerformanceGrade.acceptable:
        return (label: 'Acceptable', color: Colors.orange, icon: Icons.check);
      case PerformanceGrade.poor:
        return (label: 'Poor', color: Colors.red, icon: Icons.warning);
      case PerformanceGrade.critical:
        return (label: 'Critical', color: Colors.red.shade900, icon: Icons.error);
      case PerformanceGrade.unknown:
        return (label: 'Unknown', color: Colors.grey, icon: Icons.help);
    }
  }
  
  Color _getJankColor(double jankPercentage) {
    if (jankPercentage <= 2) return Colors.green;
    if (jankPercentage <= 5) return Colors.orange;
    return Colors.red;
  }
  
  // Severity information
  ({Color color, IconData icon}) _getSeverityInfo(PerformanceSeverity severity) {
    switch (severity) {
      case PerformanceSeverity.info:
        return (color: Colors.blue, icon: Icons.info);
      case PerformanceSeverity.warning:
        return (color: Colors.orange, icon: Icons.warning);
      case PerformanceSeverity.critical:
        return (color: Colors.red, icon: Icons.error);
    }
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    ));
    
    _chartController.forward();
  }
  
  void _resetData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Performance Data'),
        content: const Text('Are you sure you want to reset all performance tracking data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _tracker.reset();
              setState(() {
                _fpsChartData.clear();
                _frameTimeChartData.clear();
                _currentReport = null;
              });
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Performance data reset'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _startPerformanceTracking() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePerformanceData();
    });
  }
  
  void _updatePerformanceData() {
    if (!mounted) return;
    
    setState(() {
      _currentReport = _tracker.generatePerformanceReport();
      
      // Update chart data
      if (_currentReport != null) {
        _fpsChartData.add(_currentReport!.averageFps);
        _frameTimeChartData.add(_currentReport!.averageFrameTime.inMilliseconds.toDouble());
        
        // Maintain chart data size
        if (_fpsChartData.length > _maxChartPoints) {
          _fpsChartData.removeAt(0);
          _frameTimeChartData.removeAt(0);
        }
      }
    });
  }
}
