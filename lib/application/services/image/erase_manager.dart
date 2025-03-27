import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/undo_action.dart';

final eraseManagerProvider = Provider<EraseManager>((ref) {
  return EraseManager();
});

class EraseManager {
  // 存储所有擦除路径
  final List<List<Offset>> _erasePaths = [];

  // 当前正在绘制的路径
  List<Offset>? _currentPath;

  // 撤销栈
  final List<UndoAction> _undoStack = [];

  // 重做栈
  final List<UndoAction> _redoStack = [];

  // 笔刷大小（直径）
  double _brushSize = 10.0;

  // 获取笔刷大小
  double get brushSize => _brushSize;

  // 是否有可重做的操作
  bool get canRedo => _redoStack.isNotEmpty;

  // 是否有可撤销的操作
  bool get canUndo => _undoStack.isNotEmpty;

  // 获取所有擦除路径
  List<List<Offset>> get erasePaths => List.unmodifiable(_erasePaths);

  // 清除所有擦除
  void clearErase() {
    if (_erasePaths.isNotEmpty) {
      // 保存当前状态用于撤销
      _undoStack.add(UndoAction(
        type: UndoActionType.batch,
        data: List.from(_erasePaths),
      ));

      // 清空路径
      _erasePaths.clear();

      // 清空重做栈
      _redoStack.clear();
    }
  }

  // 继续擦除操作
  void continueErase(Offset position) {
    if (_currentPath != null) {
      _currentPath!.add(position);
    }
  }

  // 结束擦除操作
  void endErase() {
    if (_currentPath != null && _currentPath!.isNotEmpty) {
      // 保存当前路径
      _erasePaths.add(List.from(_currentPath!));

      // 创建撤销操作
      _undoStack.add(UndoAction(
        type: UndoActionType.erase,
        data: {
          'pathIndex': _erasePaths.length - 1,
          'path': List.from(_currentPath!),
        },
      ));

      // 清空重做栈
      _redoStack.clear();

      // 重置当前路径
      _currentPath = null;
    }
  }

  // 生成擦除遮罩图像
  Uint8List? generateEraseMask(Size imageSize) {
    if (_erasePaths.isEmpty) return null;

    // 这里需要集成图像处理库来生成实际的擦除遮罩
    // 例如使用Flutter的Canvas绘制到一个自定义的图像上

    // 此处为示例，实际实现需要与图像处理逻辑集成
    return Uint8List(0);
  }

  // 判断点是否在擦除区域内
  bool isPointErased(Offset point) {
    for (final path in _erasePaths) {
      for (final erasePoint in path) {
        final distance = (point - erasePoint).distance;
        if (distance <= _brushSize / 2) {
          return true;
        }
      }
    }
    return false;
  }

  // 从已有路径加载
  void loadFromPaths(List<List<Offset>> paths) {
    // 清空当前状态
    _erasePaths.clear();
    _undoStack.clear();
    _redoStack.clear();

    // 添加所有路径
    if (paths.isNotEmpty) {
      _erasePaths.addAll(paths.map((path) => List<Offset>.from(path)));
    }
  }

  // 重做操作
  bool redo() {
    if (!canRedo) return false;

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    if (action.type == UndoActionType.erase) {
      final path = action.data['path'] as List<Offset>;
      _erasePaths.add(path);
    }

    return true;
  }

  // 重置所有状态
  void reset() {
    _erasePaths.clear();
    _currentPath = null;
    _undoStack.clear();
    _redoStack.clear();
  }

  // 设置笔刷大小
  void setBrushSize(double size) {
    // 限制笔刷大小范围
    _brushSize = size.clamp(1.0, 50.0);
  }

  // 开始擦除操作
  void startErase(Offset position) {
    _currentPath = [position];
  }

  // 撤销操作
  bool undo() {
    if (!canUndo) return false;

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    if (action.type == UndoActionType.erase) {
      final pathIndex = action.data['pathIndex'] as int;
      if (pathIndex >= 0 && pathIndex < _erasePaths.length) {
        _erasePaths.removeAt(pathIndex);
      }
    }

    return true;
  }
}
