import 'package:flutter/material.dart';

import '../../../domain/models/character/path_info.dart';
import '../../../domain/models/character/processing_options.dart';

/// 擦除模式枚举
enum EraseMode {
  draw, // 绘制模式
  pan, // 平移模式
}

/// 擦除工具状态
class EraseState {
  final List<List<PathInfo>> history;
  final int historyIndex;
  // 已完成的路径
  final List<PathInfo> completedPaths;

  // 当前活动路径
  final PathInfo? currentPath;

  // 脏区域（需要重绘的区域）
  final Rect? dirtyBounds;

  // 画笔大小
  final double brushSize;

  // 笔刷颜色反转（擦白变成擦黑）
  final bool isReversed;

  // 是否显示轮廓
  final bool showContour;

  // 图像反转模式
  final bool imageInvertMode;

  // 处理选项
  final ProcessingOptions processingOptions;

  // 当前活动模式
  final EraseMode mode;

  // 重做路径列表(通过PathManager访问)
  final List<PathInfo>? _redoPaths;
  final bool? forceImageUpdate;

  // 构造函数
  const EraseState({
    this.history = const [],
    this.historyIndex = -1,
    this.completedPaths = const [],
    this.currentPath,
    this.dirtyBounds,
    this.brushSize = 10.0,
    this.isReversed = false,
    this.showContour = false,
    this.imageInvertMode = false,
    this.processingOptions = const ProcessingOptions(),
    this.mode = EraseMode.draw,
    this.forceImageUpdate = false,
    List<PathInfo>? redoPaths,
  }) : _redoPaths = redoPaths;

  // 创建初始状态
  factory EraseState.initial() {
    return const EraseState(
      processingOptions: ProcessingOptions(),
    );
  }

  // 获取当前画笔颜色 - 基于笔刷反转状态，不受图像反转影响
  Color get brushColor {
    // 笔刷颜色只取决于笔刷反转状态，与图像反转无关
    // 正常模式(isReversed=false): 白色 - 擦除效果
    // 反转模式(isReversed=true): 黑色 - 填充效果
    final brushColor = isReversed ? Colors.black : Colors.white;

    // if (kDebugMode) {
    //   print(
    //       '获取笔刷颜色 - isReversed=$isReversed => ${brushColor == Colors.black ? "黑色" : "白色"}');
    // }

    return brushColor;
  }

  // 是否可以重做
  bool get canRedo => (_redoPaths?.isNotEmpty ?? false);

  // 是否可以撤销
  bool get canUndo => completedPaths.isNotEmpty;

  // 是否处于平移模式
  bool get isPanMode => mode == EraseMode.pan;
  // 复制并修改部分属性
  EraseState copyWith({
    List<List<PathInfo>>? history,
    int? historyIndex,
    List<PathInfo>? completedPaths,
    PathInfo? currentPath,
    Rect? dirtyBounds,
    double? brushSize,
    bool? isReversed,
    bool? showContour,
    bool? imageInvertMode,
    ProcessingOptions? processingOptions,
    EraseMode? mode,
    List<PathInfo>? redoPaths,
    bool? forceImageUpdate,
  }) {
    return EraseState(
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      completedPaths: completedPaths ?? this.completedPaths,
      currentPath: currentPath, // 允许设置为null
      dirtyBounds: dirtyBounds, // 允许设置为null
      brushSize: brushSize ?? this.brushSize,
      isReversed: isReversed ?? this.isReversed,
      showContour: showContour ?? this.showContour,
      imageInvertMode: imageInvertMode ?? this.imageInvertMode,
      processingOptions: processingOptions ?? this.processingOptions,
      mode: mode ?? this.mode,
      forceImageUpdate: forceImageUpdate,
      redoPaths: redoPaths ?? _redoPaths, // 添加redoPaths参数
    );
  }

  // Get the default brush color for the current mode
  Color getDefaultBrushColor(bool forImageInvert) {
    if (forImageInvert) {
      return isReversed ? Colors.white : Colors.black;
    } else {
      return isReversed ? Colors.black : Colors.white;
    }
  }
}
