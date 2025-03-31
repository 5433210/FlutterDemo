import 'package:flutter/material.dart';

import 'erase_state.dart';

/// 擦除工具控制器，管理擦除状态和操作
class EraseController with ChangeNotifier {
  final EraseState _state = EraseState();
  Path? _currentPath;
  List<Path> _paths = [];
  List<Path> _redoPaths = [];

  // 设置和获取画笔大小
  double get brushSize => _state.brushSize;
  set brushSize(double value) {
    _state.brushSize = value;
    notifyListeners();
  }

  // 检查是否可以重做
  bool get canRedo => _redoPaths.isNotEmpty;
  // 检查是否可以撤销
  bool get canUndo => _paths.isNotEmpty;

  // 设置和获取反转模式
  bool get invertMode => _state.invertMode;
  set invertMode(bool value) {
    _state.invertMode = value;
    notifyListeners();
  }

  // 设置和获取描边模式
  bool get outlineMode => _state.outlineMode;

  set outlineMode(bool value) {
    _state.outlineMode = value;
    notifyListeners();
  }

  // 清除所有路径
  void clearPaths() {
    _paths = [];
    _redoPaths = [];
    _currentPath = null;
    notifyListeners();
  }

  // 结束擦除操作
  void endErase() {
    if (_currentPath != null) {
      _paths.add(_currentPath!);
      _currentPath = null;
      notifyListeners();
    }
  }

  // 获取最终结果
  dynamic getFinalResult() {
    // 这里通常会进行图像处理，将擦除应用到原始图像
    // 简化版本，返回路径列表
    return {
      'paths': _paths,
      'brushSize': brushSize,
      'invertMode': invertMode,
      'outlineMode': outlineMode,
    };
  }

  // 获取当前所有路径
  List<Path> getPaths() {
    final result = List<Path>.from(_paths);
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
    _currentPath = Path()..moveTo(position.dx, position.dy);
    _redoPaths = []; // 清空重做栈
    notifyListeners();
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
    if (_currentPath != null) {
      _currentPath!.lineTo(position.dx, position.dy);
      notifyListeners();
    }
  }
}
