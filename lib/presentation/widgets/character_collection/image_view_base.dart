import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../providers/character/tool_mode_provider.dart';

/// 图片预览组件的抽象基类
/// 定义了移动端和桌面端实现的通用接口
abstract class ImageViewBase extends ConsumerStatefulWidget {
  const ImageViewBase({super.key});

  /// 子类需要实现的手势处理方法
  
  /// 处理缩放手势
  void handleScale(ScaleStartDetails details, ScaleUpdateDetails updateDetails, ScaleEndDetails endDetails);
  
  /// 处理平移手势
  void handlePan(DragStartDetails details, DragUpdateDetails updateDetails, DragEndDetails endDetails);
  
  /// 处理点击手势
  void handleTap(TapUpDetails details);
  
  /// 处理长按手势
  void handleLongPress(LongPressStartDetails details);
  
  /// 处理选区创建
  void handleSelectionCreate(Offset start, Offset end);
  
  /// 处理选区调整
  void handleSelectionAdjust(String regionId, Rect newRect, double rotation);
  
  /// 处理选区选择
  void handleSelectionSelect(String regionId);
  
  /// 获取当前工具模式
  Tool getCurrentTool(WidgetRef ref) {
    return ref.watch(toolModeProvider);
  }
  
  /// 获取当前选区列表
  List<CharacterRegion> getCurrentRegions(WidgetRef ref);
  
  /// 检查点击位置是否在选区内
  CharacterRegion? hitTestRegion(Offset position, List<CharacterRegion> regions);
  
  /// 构建手势检测器
  Widget buildGestureDetector({
    required Widget child,
    required Tool currentTool,
    required bool isAdjusting,
    required VoidCallback? onTap,
    required VoidCallback? onPanStart,
    required VoidCallback? onPanUpdate,
    required VoidCallback? onPanEnd,
    required VoidCallback? onScaleStart,
    required VoidCallback? onScaleUpdate,
    required VoidCallback? onScaleEnd,
  });
  
  /// 构建选区调整句柄
  Widget buildAdjustmentHandles({
    required CharacterRegion region,
    required bool isActive,
    required int? activeHandleIndex,
    required VoidCallback? onHandleDrag,
  });
}