import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_mode.dart';
import '../models/erase_operation.dart';

/// 擦除工具控制器
abstract class EraseToolController extends ChangeNotifier {
  /// 当前笔刷大小
  double get brushSize;

  /// 是否可以重做
  bool get canRedo;

  /// 是否可以撤销
  bool get canUndo;

  /// 当前操作
  EraseOperation? get currentOperation;

  /// 当前点集
  List<Offset> get currentPoints;

  /// 是否正在擦除
  bool get isErasing;

  /// 当前擦除模式
  EraseMode get mode;

  /// 所有擦除操作
  List<EraseOperation> get operations;

  /// 应用当前所有操作到画布
  void applyOperations(Canvas canvas);

  /// 取消当前擦除
  void cancelErase();

  /// 清除所有操作
  void clearAll();

  /// 继续擦除操作
  void continueErase(Offset point);

  /// 结束擦除操作
  void endErase();

  /// 获取当前工作区域图像
  Future<ui.Image?> getResultImage();

  /// 重做上一个擦除操作
  void redo();

  /// 设置笔刷大小
  void setBrushSize(double size);

  /// 设置画布尺寸
  void setCanvasSize(Size size);

  /// 设置擦除模式
  void setMode(EraseMode mode);

  /// 开始擦除操作
  void startErase(Offset point);

  /// 撤销上一个擦除操作
  void undo();
}
