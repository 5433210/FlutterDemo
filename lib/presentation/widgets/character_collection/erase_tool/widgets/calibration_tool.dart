import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 校准工具 - 帮助开发者调整坐标精确度
class CalibrationTool extends StatefulWidget {
  /// 回调函数，当偏移量变化时调用
  final Function(Offset offset, double scale) onCalibrationChanged;

  /// 初始偏移量
  final Offset initialOffset;

  /// 初始缩放比例
  final double initialScale;

  const CalibrationTool({
    Key? key,
    required this.onCalibrationChanged,
    this.initialOffset = Offset.zero,
    this.initialScale = 1.0,
  }) : super(key: key);

  @override
  State<CalibrationTool> createState() => _CalibrationToolState();
}

class _CalibrationToolState extends State<CalibrationTool> {
  late double _offsetX;
  late double _offsetY;
  late double _scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '坐标校准工具',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('X偏移'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _offsetX,
                  min: -100,
                  max: 100,
                  divisions: 200,
                  onChanged: (value) {
                    setState(() {
                      _offsetX = value;
                      _notifyCalibrationChanged();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  _offsetX.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Text('Y偏移'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _offsetY,
                  min: -100,
                  max: 100,
                  divisions: 200,
                  onChanged: (value) {
                    setState(() {
                      _offsetY = value;
                      _notifyCalibrationChanged();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  _offsetY.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Text('比例校正'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _scale,
                  min: 0.5,
                  max: 2.0,
                  divisions: 30,
                  onChanged: (value) {
                    setState(() {
                      _scale = value;
                      _notifyCalibrationChanged();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  _scale.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _resetCalibration,
                child: const Text('重置'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyCalibration,
                child: const Text('应用'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _offsetX = widget.initialOffset.dx;
    _offsetY = widget.initialOffset.dy;
    _scale = widget.initialScale;
  }

  /// 应用校准设置
  void _applyCalibration() {
    _notifyCalibrationChanged();

    if (kDebugMode) {
      print(
          '应用校准设置: 偏移=(${_offsetX.toStringAsFixed(1)}, ${_offsetY.toStringAsFixed(1)}), 比例=${_scale.toStringAsFixed(2)}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('校准设置已应用'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 通知校准变化
  void _notifyCalibrationChanged() {
    widget.onCalibrationChanged(
      Offset(_offsetX, _offsetY),
      _scale,
    );
  }

  /// 重置校准设置
  void _resetCalibration() {
    setState(() {
      _offsetX = 0;
      _offsetY = 0;
      _scale = 1.0;
      _notifyCalibrationChanged();
    });
  }
}
