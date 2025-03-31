import 'package:flutter/material.dart';

import '../../widgets/character_edit/layers/preview_layer.dart';
import 'erase_state.dart';

/// 擦除工具控制器，管理擦除状态和操作
class EraseController with ChangeNotifier {
  final EraseState _state = EraseState();
  PathInfo? _currentPath;
  List<PathInfo> _paths = [];
  List<PathInfo> _redoPaths = [];

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

  // 设置和获取描边模式
  bool get outlineMode => _state.outlineMode;

  set outlineMode(bool value) {
    _state.outlineMode = value;
    notifyListeners();
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
      // 检查路径是否有效
      Rect bounds = _currentPath!.path.getBounds();
      if (bounds.width > 0 || bounds.height > 0) {
        _paths.add(_currentPath!);
        _redoPaths.clear(); // 添加新路径时清空重做栈
        print('结束擦除 - 添加路径 - 路径数: ${_paths.length}');
        notifyListeners();
      }
      _currentPath = null;
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
      print('重做操作 - 路径数: ${_paths.length}, 重做栈: ${_redoPaths.length}');
      notifyListeners();
    }
  }

  // 开始擦除操作
  void startErase(Offset position) {
    if (_currentPath != null) {
      // 如果有未完成的路径，先完成它
      endErase();
    }

    final path = Path()..moveTo(position.dx, position.dy);
    _currentPath = PathInfo(
      path: path,
      brushSize: brushSize,
      brushColor: brushColor,
    );
    print('开始擦除 - 笔刷大小: $brushSize, 颜色: $brushColor');
    notifyListeners();
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
    if (_currentPath != null) {
      (_currentPath!.path).lineTo(position.dx, position.dy);
      notifyListeners();
    }
  }
}
