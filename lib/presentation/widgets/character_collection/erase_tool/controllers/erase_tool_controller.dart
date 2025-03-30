import 'package:flutter/material.dart';

import '../models/erase_mode.dart';
import '../models/erase_operation.dart';

/// 擦除工具控制器接口
/// 定义擦除工具的所有操作和状态管理
abstract class EraseToolController extends ChangeNotifier {
  /// 当前笔刷大小
  double get brushSize;

  /// 是否可以重做
  bool get canRedo;

  /// 是否可以撤销
  bool get canUndo;

  /// 获取当前的擦除点
  List<Offset> get currentPoints;

  /// 是否正在擦除
  bool get isErasing;

  /// 当前擦除模式
  EraseMode get mode;

  /// 获取所有已提交的擦除操作
  List<EraseOperation> get operations;

  /// 取消当前擦除操作
  void cancelErase();

  /// 清除所有擦除操作
  void clearAll();

  /// 继续擦除操作
  void continueErase(Offset point);

  /// 释放资源
  @override
  void dispose();

  /// 结束擦除操作
  void endErase();

  /// 重做最近撤销的操作
  void redo();

  /// 设置笔刷大小
  void setBrushSize(double size);

  /// 设置擦除模式
  void setMode(EraseMode mode);

  /// 开始擦除操作
  void startErase(Offset point);

  /// 撤销最近的操作
  void undo();
}
