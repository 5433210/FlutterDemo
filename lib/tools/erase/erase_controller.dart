import 'package:flutter/material.dart';

import '../../widgets/character_edit/layers/preview_layer.dart';
import 'erase_state.dart';

/// 擦除工具控制器，管理擦除状态和操作
class EraseController with ChangeNotifier {
  final EraseState _state = EraseState();
  PathInfo? _currentPath;
  List<PathInfo> _paths = [];
  List<PathInfo> _redoPaths = [];

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
      print('切换图像反转 - imageInvertMode: ${_state.imageInvertMode}');
      notifyListeners();
    }
  }

  // 设置和获取笔刷反转模式
  bool get invertMode => _state.invertMode;

  set invertMode(bool value) {
    if (_state.invertMode != value) {
      _state.invertMode = value;
      print(
          '切换笔刷反转 - invertMode: ${_state.invertMode}, brushColor: ${_state.brushColor}');
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
      print('EraseController: 切换平移模式 -> $_isInPanMode');

      // 如果从平移模式切回来，且有活动路径，结束它
      if (!_isInPanMode && _currentPath != null) {
        print('从平移模式返回时结束当前路径');
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
      print('清除所有路径');
      notifyListeners();
    }
  }

  // 结束擦除操作
  void endErase() {
    if (_currentPath != null) {
      // 检查路径是否有效（存在点）
      try {
        final bounds = _currentPath!.path.getBounds();
        final hasPoints = !bounds.isEmpty;

        if (hasPoints) {
          _paths.add(_currentPath!);
          _redoPaths.clear(); // 添加新路径时清空重做栈
          print('结束擦除 - 添加有效路径 - 总数: ${_paths.length}');
        } else {
          print('结束擦除 - 跳过空路径');
        }
      } catch (e) {
        print('结束擦除 - 错误: $e');
      }

      _currentPath = null;
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
      print('获取路径 - 包含当前活动路径，总数: ${result.length}');
    } else {
      print('获取路径 - 无活动路径，总数: ${result.length}');
    }
    return result;
  }

  // 重做操作
  void redo() {
    if (_redoPaths.isNotEmpty) {
      final path = _redoPaths.removeLast();
      _paths.add(path);
      print('重做操作 - 路径数: ${_paths.length}, 重做栈: ${_redoPaths.length}');
      notifyListeners();
    }
  }

  // 开始擦除操作
  void startErase(Offset position) {
    // 在平移模式下不启动擦除
    if (_isInPanMode) {
      print('EraseController: 忽略擦除请求，当前处于平移模式');
      return;
    }

    print('EraseController: 开始擦除操作，位置 $position，笔刷大小 $brushSize');

    // 如果有未完成的路径，先完成它
    if (_currentPath != null) {
      print('发现未完成的擦除路径，先完成它');
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
      print('创建新擦除路径：${_currentPath.hashCode}');
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
      print('撤销操作 - 路径数: ${_paths.length}, 重做栈: ${_redoPaths.length}');
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
      // 这种情况不应该发生，因为我们现在只在拖拽时执行擦除
      print('警告: 尝试更新不存在的擦除路径');
      return;
    }

    try {
      // 添加点到当前路径
      _currentPath!.path.lineTo(position.dx, position.dy);
      print('擦除路径更新: 添加点 $position');

      // 通知监听器更新UI
      notifyListeners();
    } catch (e) {
      print('更新擦除路径时出错: $e');
    }
  }
}
