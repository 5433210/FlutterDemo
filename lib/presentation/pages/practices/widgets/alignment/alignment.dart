/// 参考线自动对齐功能模块
///
/// 这个模块提供了完整的参考线自动对齐功能，包括：
/// - 核心数据结构和枚举类型
/// - 参考线生成和对齐检测算法
/// - 拖拽过程中的实时对齐处理
/// - 参考线的视觉渲染
/// - 对齐模式管理
///
/// 使用示例：
/// ```dart
/// // 1. 初始化对齐模式管理器
/// AlignmentModeManager.setMode(AlignmentMode.guideLine);
///
/// // 2. 创建拖拽对齐处理器
/// final dragHandler = DragAlignmentHandler(
///   allElements: elements,
///   getScaleFactor: () => scaleFactor,
/// );
///
/// // 3. 在拖拽过程中调用
/// dragHandler.onDragUpdate(elementId, delta);
///
/// // 4. 在拖拽结束时调用
/// final adjustedDelta = dragHandler.onDragEnd(elementId, finalDelta);
///
/// // 5. 在Canvas中渲染参考线
/// GuideLineRenderer.paintGuideLines(
///   canvas,
///   canvasSize,
///   dragHandler.activeAlignments.value,
///   draggedElementId,
/// );
/// ```

// 导出配置类
export 'alignment_config.dart';
export 'alignment_detector.dart';
export 'alignment_mode_manager.dart';
// 导出UI组件
export 'alignment_mode_selector.dart';
// 导出核心类型和枚举
export 'alignment_types.dart';
// 导出处理器和管理器
export 'drag_alignment_handler.dart';
// 导出核心算法
export 'guide_line_generator.dart';
// 导出渲染器
export 'guide_line_renderer.dart';
