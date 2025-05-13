import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'improved_texture_painter.dart';

/// 纹理使用示例 - 可以直接复制到您的集字元素渲染器中
class TextureUsageExample extends ConsumerWidget {
  final Map<String, dynamic>? textureData;
  final String fillMode;
  final double opacity;
  final String applicationMode;
  
  const TextureUsageExample({
    Key? key,
    required this.textureData,
    this.fillMode = 'cover',
    this.opacity = 1.0,
    this.applicationMode = 'background',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatefulBuilder(
      builder: (context, setState) {
        return CustomPaint(
          painter: ImprovedTexturePainter(
            textureData: textureData,
            fillMode: fillMode,
            opacity: opacity,
            ref: ref,
            onTextureLoaded: () {
              // 纹理加载完成后触发重绘
              setState(() {});
            },
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// 在集字元素渲染器中使用改进的纹理绘制器的示例代码
/// 
/// 在 _CollectionPainter 类中的 _paintTexture 方法中，
/// 替换现有的纹理绘制代码为以下代码：
/// 
/// ```dart
/// void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
///   final startTime = DateTime.now();
///   debugPrint('''开始纹理渲染:
///     ┌─ 模式: $mode (${mode == 'background' ? '背景纹理' : '字符纹理'})
///     ├─ 区域: $rect
///     ├─ 填充: ${textureConfig.fillMode}
///     ├─ 透明度: ${textureConfig.opacity}
///     ├─ 路径: ${textureConfig.data?['path']}
///     └─ 缓存键: ${textureConfig.data?['id']}''');
///   
///   try {
///     // 使用改进的纹理绘制器
///     final painter = ImprovedTexturePainter(
///       textureData: textureConfig.data,
///       fillMode: textureConfig.fillMode,
///       opacity: textureConfig.opacity,
///       ref: ref,
///       onTextureLoaded: () {
///         // 纹理加载完成后，使用 SchedulerBinding 安排下一帧重绘
///         if (_repaintCallback != null) {
///           SchedulerBinding.instance.addPostFrameCallback((_) {
///             _repaintCallback!();
///           });
///         }
///       },
///     );
///     
///     // 直接绘制纹理
///     painter.paint(canvas, rect.size);
///     
///     final endTime = DateTime.now();
///     final duration = endTime.difference(startTime);
///     debugPrint('''✅ 纹理渲染完成:
///       ┌─ 模式: $mode
///       ├─ 耗时: ${duration.inMilliseconds}ms
///       └─ 微秒: ${duration.inMicroseconds}μs''');
///   } catch (e, stack) {
///     debugPrint('❌ 纹理绘制错误: $e\n$stack');
///   }
/// }
/// ```
/// 
/// 同时，确保在文件顶部导入改进的纹理绘制器：
/// 
/// ```dart
/// import 'improved_texture_painter.dart';
/// ```
