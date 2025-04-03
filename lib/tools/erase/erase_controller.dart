import 'package:flutter/material.dart';

import '../../domain/models/character/path_info.dart';
import '../../utils/path/path_utils.dart';
import 'erase_state.dart';

/// 擦除工具控制器，管理擦除状态和操作
class EraseController with ChangeNotifier {
  static const _notifyThreshold = 5;
  static const _maxNotifyInterval = Duration(milliseconds: 33);

  final EraseState _state = EraseState();
  PathInfo? _currentPath;
  List<PathInfo> _paths = [];
  List<PathInfo> _redoPaths = [];

  Offset? _lastPoint;
  bool _isInPanMode = false;
  DateTime _lastModeChangeTime = DateTime.now();
  int _pendingPointCount = 0;
  DateTime _lastNotifyTime = DateTime.now();

  // Get the brush color - based on invert and image invert modes
  Color get brushColor {
    final baseColor = _state.invertMode ? Colors.black : Colors.white;

    // If image is inverted, we need to invert the brush color too
    // to maintain the correct erasing behavior
    if (_state.imageInvertMode) {
      return baseColor == Colors.white ? Colors.black : Colors.white;
    }

    return baseColor;
  }

  double get brushSize => _state.brushSize;
  set brushSize(double value) {
    if (_state.brushSize != value) {
      _state.brushSize = value;
      notifyListeners();
    }
  }

  bool get canRedo => _redoPaths.isNotEmpty;
  bool get canUndo => _paths.isNotEmpty;
  bool get imageInvertMode => _state.imageInvertMode;

  // Override the existing imageInvertMode setter
  set imageInvertMode(bool value) {
    if (_state.imageInvertMode != value) {
      _state.imageInvertMode = value;
      // Only update the current path if it exists, don't refresh previous paths
      _updateCurrentPathColor();
      notifyListeners();
    }
  }

  bool get invertMode => _state.invertMode;

  // Override the existing invertMode setter
  set invertMode(bool value) {
    if (_state.invertMode != value) {
      _state.invertMode = value;
      // Only update the current path if it exists, don't refresh previous paths
      _updateCurrentPathColor();
      notifyListeners();
    }
  }

  bool get isInPanMode => _isInPanMode;

  bool get outlineMode => _state.outlineMode;

  set outlineMode(bool value) {
    _state.outlineMode = value;
    notifyListeners();
  }

  set panMode(bool value) {
    if (_isInPanMode != value) {
      _isInPanMode = value;
      _lastModeChangeTime = DateTime.now();
      if (!_isInPanMode && _currentPath != null) {
        endErase();
      }
      notifyListeners();
    }
  }

  void clearPaths() {
    if (_paths.isNotEmpty || _currentPath != null) {
      _paths = [];
      _redoPaths = [];
      _currentPath = null;
      notifyListeners();
    }
  }

  void endErase() {
    if (_currentPath != null) {
      print('结束当前擦除路径');
      try {
        final bounds = _currentPath!.path.getBounds();
        if (!bounds.isEmpty) {
          _paths.add(_currentPath!);
          _redoPaths.clear();
          print('添加擦除路径 - bounds: $bounds');
        }
      } catch (e) {
        print('结束擦除路径出错: $e');
      }
      _currentPath = null;
      notifyListeners();
    }
  }

  dynamic getFinalResult() {
    final pathsData = _paths
        .map((pathInfo) => {
              'path': pathInfo.path,
              'brushSize': pathInfo.brushSize,
              'brushColor': pathInfo.brushColor.value, // 确保颜色值正确保存
            })
        .toList();

    return {
      'paths': pathsData,
      'invertMode': invertMode,
      'imageInvertMode': imageInvertMode,
      'outlineMode': outlineMode,
    };
  }

  List<PathInfo> getPaths() {
    final result = List<PathInfo>.from(_paths);
    if (_currentPath != null) {
      result.add(_currentPath!);
    }
    return result;
  }

  void handleClickErase(Offset position) {
    if (_isInPanMode) return;

    try {
      final path = PathUtils.createSolidCircle(
        position,
        brushSize / 2,
      );

      _currentPath = PathInfo(
        path: path,
        brushSize: brushSize,
        brushColor: brushColor,
      );

      _paths.add(_currentPath!);
      _redoPaths.clear();
      _currentPath = null;

      notifyListeners();
    } catch (e) {
      print('单击擦除出错: $e');
    }
  }

  void redo() {
    if (_redoPaths.isNotEmpty) {
      final path = _redoPaths.removeLast();
      _paths.add(path);
      notifyListeners();
    }
  }

  // Replace the existing refreshPathColors method with a simpler version
  // that only logs the change but doesn't modify existing paths
  void refreshPathColors() {
    print('Brush color changed to: $brushColor');
    // No longer modifying existing paths
  }

  void startErase(Offset position) {
    if (_isInPanMode) return;

    if (_currentPath != null) {
      endErase();
    }

    try {
      final path = PathUtils.createSolidCircle(
        position,
        brushSize / 2,
      );

      _currentPath = PathInfo(
        path: path,
        brushSize: brushSize,
        brushColor: brushColor,
      );

      _lastPoint = position;
      notifyListeners();
    } catch (e) {
      print('开始擦除出错: $e');
    }
  }

  void undo() {
    if (_paths.isNotEmpty) {
      final path = _paths.removeLast();
      _redoPaths.add(path);
      notifyListeners();
    }
  }

  void updateErase(Offset position) {
    if (_isInPanMode || _currentPath == null || _lastPoint == null) return;

    try {
      // 连接上一个点和当前点位置，生成实心路径
      final gapPath = PathUtils.createSolidGap(
        _lastPoint!,
        position,
        brushSize,
      );

      // 合并到当前路径
      _currentPath!.path.addPath(gapPath, Offset.zero);
      _lastPoint = position;

      _pendingPointCount++;

      final now = DateTime.now();
      if (_pendingPointCount >= _notifyThreshold ||
          now.difference(_lastNotifyTime) >= _maxNotifyInterval) {
        _lastNotifyTime = now;
        _pendingPointCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('更新擦除路径时出错: $e');
    }
  }

  // New method to update only the current path color if needed
  void _updateCurrentPathColor() {
    // Only update current path if it exists
    if (_currentPath != null) {
      final currentColor = brushColor;

      if (_currentPath!.brushColor != currentColor) {
        _currentPath = PathInfo(
          path: _currentPath!.path,
          brushSize: _currentPath!.brushSize,
          brushColor: currentColor,
        );
      }
    }
  }
}
