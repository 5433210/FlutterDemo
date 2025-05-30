import 'package:flutter/material.dart';

import '../../../domain/models/character/path_info.dart';
import '../../../utils/path/path_utils.dart';

/// 路径管理器，负责管理绘制路径的状态
class PathManager {
  // 完成的路径列表 - 修改为存储PathInfo而不仅仅是Path
  final List<PathInfo> _completedPaths = [];

  // 当前正在绘制的路径
  Path? _currentPath;

  // 当前路径的颜色和大小
  Color? _currentColor;
  double _currentBrushSize = 10.0;

  // 重做路径列表
  final List<PathInfo> _redoPaths = [];

  // 撤销历史堆栈 - 添加缺失的字段
  final List<List<PathInfo>> _undoStack = [];

  // 脏区域（需要重绘的区域）
  Rect? _dirtyBounds;

  // 当前点列表（用于构建当前路径）
  final List<Offset> _currentPoints = [];

  // 是否可以重做
  bool get canRedo => _redoPaths.isNotEmpty;

  // 已完成的路径的只读访问
  List<PathInfo> get completedPaths => List.unmodifiable(_completedPaths);

  // 当前路径的颜色
  Color? get currentColor => _currentColor;

  // 当前路径的只读访问
  Path? get currentPath => _currentPath;

  // 脏区域的只读访问
  Rect? get dirtyBounds => _dirtyBounds;

  /// Checks if redo is available
  bool get isRedoAvailable => _redoPaths.isNotEmpty;

  /// Checks if undo is available
  bool get isUndoAvailable => _undoStack.isNotEmpty;

  // 重做路径列表的只读访问
  List<PathInfo> get redoPaths => List.unmodifiable(_redoPaths);

  /// Add a completed path without starting/completing sequence
  void addCompletedPath(PathInfo path) {
    _completedPaths.add(PathInfo(
      path: path.path,
      brushSize: path.brushSize,
      brushColor: path.brushColor,
    ));
    _updateDirtyBounds();
  }

  /// 清除所有路径
  void clear() {
    _completedPaths.clear();
    _currentPath = null;
    _currentColor = null;
    _currentPoints.clear();
    _dirtyBounds = null;
    _redoPaths.clear();
  }

  /// Clears only the undo and redo stacks, while preserving completed paths
  void clearUndoRedo() {
    _undoStack.clear();
    _redoPaths.clear();
  }

  /// 完成当前路径
  void completePath() {
    if (_currentPath != null) {
      // 确保即使 _currentColor 为 null 也能使用默认的颜色
      final color = _currentColor ?? Colors.white;

      _completedPaths.add(PathInfo(
        path: _currentPath!,
        brushSize: _currentBrushSize,
        brushColor: color,
      ));

      _currentPath = null;
      _currentColor = null;
      _currentPoints.clear();
      _redoPaths.clear(); // 完成新路径时清除重做列表
    }
  }

  /// Returns the list of completed paths
  List<PathInfo> getCompletedPaths() {
    return _completedPaths;
  }

  /// Returns the current path being drawn
  Path? getCurrentPath() {
    return _currentPath;
  }

  /// Returns the dirty rectangle that needs to be repainted
  Rect? getDirtyRect() {
    return _dirtyBounds;
  }

  // 获取指定路径的颜色信息，用于调试和轮廓检测
  Map<String, dynamic> getPathColorInfo() {
    int blackPaths = 0;
    int whitePaths = 0;

    for (final path in _completedPaths) {
      if (path.brushColor == Colors.black) {
        blackPaths++;
      } else if (path.brushColor == Colors.white) {
        whitePaths++;
      }
    }

    return {
      'blackPaths': blackPaths,
      'whitePaths': whitePaths,
      'hasMixedColors': blackPaths > 0 && whitePaths > 0,
      'currentColor': _currentColor?.toString(),
    };
  }

  /// 使用现有路径初始化 - 修改接收类型为PathInfo以匹配EraseStateNotifier的调用
  void initializeWithPaths(List<PathInfo> paths) {
    _completedPaths.clear();
    // 将PathInfo转换为PathInfo
    _completedPaths.addAll(paths
        .map((p) => PathInfo(
              path: p.path,
              brushSize: p.brushSize,
              brushColor: p.brushColor,
            ))
        .toList());

    // 更新脏区域
    _updateDirtyBounds();
  }

  /// Initialize with saved paths
  void initializeWithSavedPaths(List<PathInfo> paths) {
    _completedPaths.clear();
    // 将PathInfo转换为PathInfo
    _completedPaths.addAll(paths
        .map((p) => PathInfo(
              path: p.path,
              brushSize: p.brushSize,
              brushColor: p.brushColor,
            ))
        .toList());

    // Update history - 修复_redoStack为_redoPaths
    _undoStack.clear();
    _undoStack.add(_completedPaths.toList());
    _redoPaths.clear();

    // Recalculate dirty bounds
    _updateDirtyBounds();
  }

  /// Performs a redo operation
  bool redo() {
    if (_redoPaths.isEmpty) return false;

    final path = _redoPaths.removeLast();
    _completedPaths.add(path);
    _undoStack.add(_completedPaths.toList());
    return true;
  }

  /// 重做上一个撤销的路径
  void redoPath() {
    if (_redoPaths.isNotEmpty) {
      final pathInfo = _redoPaths.removeLast();
      _completedPaths.add(pathInfo);
    }
  }

  /// Sets the completed paths list to a new list
  void setCompletedPaths(List<PathInfo> paths) {
    _completedPaths.clear();
    _completedPaths.addAll(paths);
  }

  /// Sets the current path
  void setCurrentPath(Path path) {
    _currentPath = path;
  }

  /// Sets the dirty rectangle for repainting
  void setDirtyRect(Rect rect) {
    _dirtyBounds = rect;
  }

  /// Starts a new path at the given position
  Path startNewPath(Offset position, double brushSize, Color brushColor) {
    _currentPath = Path()..moveTo(position.dx, position.dy);
    _currentBrushSize = brushSize;
    _currentColor = brushColor;

    // Initialize dirty rect to the position with brush size as dimensions
    final halfBrushSize = brushSize / 2;
    _dirtyBounds = Rect.fromLTWH(
      position.dx - halfBrushSize,
      position.dy - halfBrushSize,
      brushSize,
      brushSize,
    );

    return _currentPath!;
  }

  /// 开始新的路径
  void startPath(Offset position, {double? brushSize, Color? brushColor}) {
    _currentPoints.clear();
    _currentPath = Path();
    _currentPoints.add(position);

    if (brushSize != null) {
      _currentBrushSize = brushSize;
    }

    if (brushColor != null) {
      _currentColor = brushColor;
    }

    _updateCurrentPath();
    _updateDirtyBounds(position);
  }

  /// 撤销上一个路径
  void undo() {
    if (_completedPaths.isNotEmpty) {
      final pathInfo = _completedPaths.removeLast();
      _redoPaths.add(pathInfo); // 保存到重做列表
    }
  }

  /// Performs an undo operation
  bool undoPath() {
    if (_undoStack.isEmpty) return false;

    final lastPath = _undoStack.removeLast();
    _redoPaths.addAll(lastPath);

    // Remove the corresponding path from completed paths
    _completedPaths.removeWhere((path) => path == lastPath);
    return true;
  }

  /// 更新所有已完成路径的颜色 (用于图像反转或笔刷反转时同步更新)
  void updateAllPathColors(bool imageInverted, bool brushReversed) {
    if (_completedPaths.isEmpty) return;

    // 基于笔刷反转状态，确定应该使用的颜色
    // 图像反转不应影响笔刷颜色的确定
    final targetColor = brushReversed ? Colors.black : Colors.white;

    // 不要修改已完成的路径颜色，只更新当前路径的颜色
    if (_currentPath != null && _currentColor != null) {
      _currentColor = targetColor;
    }
  }

  /// 更新所有路径以适应图像反转状态变化
  void updateAllPathsForImageInversion(bool imageInverted) {
    if (_completedPaths.isEmpty) return;

    final updatedPaths = <PathInfo>[];

    for (final entry in _completedPaths) {
      // 获取新颜色 - 在图像反转时，反转路径颜色，使其在视觉上保持一致
      final newColor = _invertColor(entry.brushColor);

      updatedPaths.add(PathInfo(
        path: entry.path,
        brushSize: entry.brushSize,
        brushColor: newColor,
      ));
    }

    // 替换路径列表
    _completedPaths.clear();
    _completedPaths.addAll(updatedPaths);
  }

  /// 更新当前路径的颜色
  void updateCurrentColor(Color color) {
    if (_currentPath != null) {
      _currentColor = color;
    }
  }

  /// Updates the current path with a new point
  void updateCurrentPathWithPoint(Offset position) {
    if (_currentPath != null) {
      _currentPath!.lineTo(position.dx, position.dy);

      // Update dirty rect to include the new position
      if (_dirtyBounds != null) {
        final halfBrushSize = _currentBrushSize / 2;
        final pointRect = Rect.fromLTWH(
          position.dx - halfBrushSize,
          position.dy - halfBrushSize,
          _currentBrushSize,
          _currentBrushSize,
        );
        _dirtyBounds = _dirtyBounds!.expandToInclude(pointRect);
      }
    }
  }

  /// 更新当前路径
  void updatePath(Offset position) {
    if (_currentPath == null) return;

    _currentPoints.add(position);
    _updateCurrentPath();
    _updateDirtyBounds(position);
  }

  /// 反转颜色 (黑变白，白变黑)
  Color _invertColor(Color color) {
    return color == Colors.black ? Colors.white : Colors.black;
  }

  // 更新当前路径的实际形状
  void _updateCurrentPath() {
    if (_currentPoints.isEmpty) return;

    Path path = Path();

    if (_currentPoints.length == 1) {
      // 单点情况，创建圆形路径
      final point = _currentPoints.first;
      // 使用当前笔刷大小的一半作为半径，不进行四舍五入
      path.addOval(
          Rect.fromCircle(center: point, radius: _currentBrushSize / 2));
    } else {
      // 多点情况 - 使用PathUtils创建实心路径
      if (_currentPoints.length == 2) {
        // 仅有两个点，直接创建一个Gap
        path = PathUtils.createSolidGap(
          _currentPoints.first,
          _currentPoints.last,
          _currentBrushSize,
        );
      } else {
        // 多个点，逐段创建并合并
        path = Path(); // 创建空路径

        // 首先添加第一个点的圆形
        path.addOval(Rect.fromCircle(
          center: _currentPoints.first,
          radius: _currentBrushSize / 2,
        ));

        // 然后逐段连接
        for (int i = 1; i < _currentPoints.length; i++) {
          final gap = PathUtils.createSolidGap(
            _currentPoints[i - 1],
            _currentPoints[i],
            _currentBrushSize,
          );
          path.addPath(gap, Offset.zero);
        }
      }
    }

    _currentPath = path;
  }

  // 更新脏区域
  void _updateDirtyBounds([Offset? position]) {
    if (position != null) {
      final pointBounds =
          Rect.fromCircle(center: position, radius: _currentBrushSize / 2);
      _dirtyBounds = _dirtyBounds?.expandToInclude(pointBounds) ?? pointBounds;
    } else {
      Rect? bounds;
      for (final entry in _completedPaths) {
        bounds = bounds?.expandToInclude(entry.path.getBounds()) ??
            entry.path.getBounds();
      }
      _dirtyBounds = bounds;
    }
  }
}
