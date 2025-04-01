import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/debug/debug_flags.dart';
import '../../utils/path/path_smoothing.dart'; // 添加导入
import '../../widgets/character_edit/layers/preview_layer.dart';
import 'erase_state.dart';

/// 擦除工具控制器，管理擦除状态和操作
class EraseController with ChangeNotifier {
  static const int _bufferThreshold = 10; // 缓冲区阈值
  final EraseState _state = EraseState();
  PathInfo? _currentPath;
  List<PathInfo> _paths = [];

  List<PathInfo> _redoPaths = [];
  // 添加点缓冲区和阈值
  final List<Offset> _pointBuffer = [];

  // 记录最近的操作模式，便于出现问题时诊断
  bool _isInPanMode = false;
  DateTime _lastModeChangeTime = DateTime.now();

  // 获取画笔颜色 - 直接使用state中的实现
  Color get brushColor => _state.brushColor;

  // 设置和获取画笔大小
  double get brushSize => _state.brushSize;

  set brushSize(double value) {
    if (_state.brushSize != value) {
      _state.brushSize = value;
      notifyListeners();
    }
  }

  // 检查是否可以重做
  bool get canRedo => _redoPaths.isNotEmpty;

  // 检查是否可以撤销
  bool get canUndo => _paths.isNotEmpty;

  // 获取图像反转模式
  bool get imageInvertMode => _state.imageInvertMode;

  // 设置图像反转模式
  set imageInvertMode(bool value) {
    if (_state.imageInvertMode != value) {
      _state.imageInvertMode = value;
      notifyListeners();
    }
  }

  // 设置和获取笔刷反转模式
  bool get invertMode => _state.invertMode;

  set invertMode(bool value) {
    if (_state.invertMode != value) {
      _state.invertMode = value;
      notifyListeners();
    }
  }

  // 获取当前是否处于平移模式
  bool get isInPanMode => _isInPanMode;

  // 设置和获取描边模式
  bool get outlineMode => _state.outlineMode;

  set outlineMode(bool value) {
    _state.outlineMode = value;
    notifyListeners();
  }

  // 设置平移模式
  set panMode(bool value) {
    if (_isInPanMode != value) {
      _isInPanMode = value;
      _lastModeChangeTime = DateTime.now();

      // 只在调试模式下打印
      if (kDebugMode && DebugFlags.enableEraseDebug) {
        print('EraseController: 切换平移模式 -> $_isInPanMode');
      }

      // 如果从平移模式切回来，且有活动路径，结束它
      if (!_isInPanMode && _currentPath != null) {
        if (kDebugMode && DebugFlags.enableEraseDebug) {
          print('从平移模式返回时结束当前路径');
        }
        endErase();
      }

      notifyListeners();
    }
  }

  // 清除所有路径
  void clearPaths() {
    if (_paths.isNotEmpty || _currentPath != null) {
      _paths = [];
      _redoPaths = [];
      _currentPath = null;
      notifyListeners();
    }
  }

  // 结束擦除操作
  void endErase() {
    if (_currentPath != null) {
      // 应用所有缓冲的点
      if (_pointBuffer.isNotEmpty) {
        _applyBufferedPoints();
      }

      // 检查路径是否有效（存在点）
      try {
        final bounds = _currentPath!.path.getBounds();
        final hasPoints = !bounds.isEmpty;

        if (hasPoints) {
          _paths.add(_currentPath!);
          _redoPaths.clear(); // 添加新路径时清空重做栈
        }
      } catch (e) {
        print('结束擦除 - 错误: $e');
      }

      _currentPath = null;
      _pointBuffer.clear();
      notifyListeners();
    }
  }

  // 获取最终结果
  dynamic getFinalResult() {
    final pathsData = _paths
        .map((pathInfo) => {
              'path': pathInfo.path,
              'brushSize': pathInfo.brushSize,
              'brushColor': pathInfo.brushColor.value,
            })
        .toList();

    return {
      'paths': pathsData,
      'invertMode': invertMode,
      'imageInvertMode': imageInvertMode,
      'outlineMode': outlineMode,
    };
  }

  // 获取当前所有路径
  List<PathInfo> getPaths() {
    final result = List<PathInfo>.from(_paths);
    if (_currentPath != null) {
      result.add(_currentPath!);
    }
    return result;
  }

  // 重做操作
  void redo() {
    if (_redoPaths.isNotEmpty) {
      final path = _redoPaths.removeLast();
      _paths.add(path);
      notifyListeners();
    }
  }

  // 开始擦除操作
  void startErase(Offset position) {
    // 在平移模式下不启动擦除
    if (_isInPanMode) {
      if (kDebugMode && DebugFlags.enableEraseDebug) {
        print('EraseController: 忽略擦除请求，当前处于平移模式');
      }
      return;
    }

    // 只在调试模式下打印
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      print('EraseController: 开始擦除操作，位置 $position，笔刷大小 $brushSize');
    }

    // 如果有未完成的路径，先完成它
    if (_currentPath != null) {
      if (kDebugMode && DebugFlags.enableEraseDebug) {
        print('发现未完成的擦除路径，先完成它');
      }
      endErase();
    }

    try {
      final path = Path();
      path.moveTo(position.dx, position.dy);

      _currentPath = PathInfo(
        path: path,
        brushSize: brushSize,
        brushColor: brushColor,
      );

      // 只在调试模式下打印
      if (kDebugMode && DebugFlags.enableEraseDebug) {
        print('创建新擦除路径：${_currentPath.hashCode}');
      }
      notifyListeners();
    } catch (e) {
      print('创建路径时出错: $e');
    }
  }

  // 撤销操作
  void undo() {
    if (_paths.isNotEmpty) {
      final path = _paths.removeLast();
      _redoPaths.add(path);
      notifyListeners();
    }
  }

  // 更新擦除操作
  void updateErase(Offset position) {
    // 在平移模式下不更新擦除
    if (_isInPanMode) {
      return;
    }

    // 检查是否有活动的擦除路径
    if (_currentPath == null) {
      return;
    }

    try {
      // 添加点到当前路径 - 不使用lineTo，而是收集点
      // 然后在结束时应用平滑处理
      _pointBuffer.add(position);

      // 如果缓冲区足够大，应用部分平滑
      if (_pointBuffer.length > _bufferThreshold) {
        _applyBufferedPoints();
      }

      // 通知监听器更新UI
      notifyListeners();
    } catch (e) {
      print('更新擦除路径时出错: $e');
    }
  }

  // 应用缓冲区中的点到路径
  void _applyBufferedPoints() {
    if (_pointBuffer.isEmpty || _currentPath == null) return;

    // 只在调试模式且缓冲区足够大时打印
    if (kDebugMode && DebugFlags.enableEraseDebug && _pointBuffer.length > 20) {
      print('应用缓冲区 - 点数: ${_pointBuffer.length}');
    }

    // 平滑处理缓冲区中的点
    final smoothedPoints = PathSmoothing.interpolatePoints(
      _pointBuffer,
      maxDistance: 6.0,
    );

    // 创建平滑路径段
    final smoothPath = PathSmoothing.createSmoothPath(smoothedPoints);

    // 将平滑路径段添加到当前路径
    _currentPath!.path.addPath(smoothPath, Offset.zero);

    // 清空缓冲区，但保留最后一个点作为下一段的起点
    if (_pointBuffer.isNotEmpty) {
      final lastPoint = _pointBuffer.last;
      _pointBuffer.clear();
      _pointBuffer.add(lastPoint);
    }
  }
}
