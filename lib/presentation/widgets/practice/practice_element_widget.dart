import 'package:flutter/material.dart';

import '../../../domain/models/practice/practice_element.dart';

/// 集字内容元素Widget
class CollectionElementWidget extends PracticeElementWidget {
  @override
  final CollectionElement element;

  const CollectionElementWidget({
    Key? key,
    required this.element,
    required ElementState state,
    VoidCallback? onTap,
    Function(Offset delta)? onDragUpdate,
    Function(Offset position, double width, double height)? onResizeUpdate,
    Function(double angle)? onRotateUpdate,
  }) : super(
          key: key,
          element: element,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );

  @override
  Widget build(BuildContext context) {
    final borderColor =
        state == ElementState.normal ? Colors.grey : Colors.blue;
    final borderWidth = state == ElementState.normal ? 1.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        // 只有未锁定时才能移动
        if (!element.isLocked) {
          onDragUpdate?.call(details.delta);
        }
      },
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          color: Color(
                  int.parse(element.backgroundColor.substring(1), radix: 16) +
                      0xFF000000)
              .withAlpha((element.opacity * 255).toInt()),
        ),
        padding: element.padding,
        child: Stack(
          children: [
            // 集字内容
            Align(
              alignment: element.alignment,
              child: element.characters.isEmpty
                  ? const Center(child: Text('请输入汉字'))
                  : _buildCollectionContent(),
            ),

            // 控制点 (仅在编辑状态显示)
            if (state == ElementState.editing)
              _buildControlHandles(element.width, element.height),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionContent() {
    final characters = element.characters.split('');

    // 计算每个字符的大小和布局
    final charSize = element.characterSize;

    // 横向或纵向排列
    final isHorizontal = element.direction == CollectionDirection.horizontal ||
        element.direction == CollectionDirection.horizontalReversed;

    // 反向排列
    final isReversed =
        element.direction == CollectionDirection.horizontalReversed ||
            element.direction == CollectionDirection.verticalReversed;

    // 处理排列方向
    if (isReversed) {
      characters.reversed.toList();
    }

    return Wrap(
      direction: isHorizontal ? Axis.horizontal : Axis.vertical,
      alignment: WrapAlignment.start,
      spacing: element.characterSpacing,
      runSpacing: element.lineSpacing,
      textDirection:
          isHorizontal && isReversed ? TextDirection.rtl : TextDirection.ltr,
      verticalDirection: !isHorizontal && isReversed
          ? VerticalDirection.up
          : VerticalDirection.down,
      children: characters.map((char) {
        // 查找该字符对应的集字图片
        final charImage = _findCharacterImage(char);

        return Container(
          width: charSize,
          height: charSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.withAlpha((0.3 * 255).toInt()),
            ),
          ),
          child: charImage != null
              ? Image.network(
                  charImage['imageUrl'] as String,
                  fit: BoxFit.contain,
                )
              : Center(
                  child: Text(
                    char,
                    style: TextStyle(
                      fontSize: charSize * 0.7,
                      color: Color(
                          int.parse(element.fontColor.substring(1), radix: 16) +
                              0xFF000000),
                    ),
                  ),
                ),
        );
      }).toList(),
    );
  }

  // 查找字符对应的集字图片
  Map<String, dynamic>? _findCharacterImage(String char) {
    if (element.characterImages.isEmpty) return null;

    try {
      return element.characterImages.firstWhere(
        (img) => img['character'] == char,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }
}

enum ElementState {
  normal, // 普通状态（灰色线框）
  selected, // 选中状态（蓝色线框，不带变换控制点）
  editing, // 编辑状态（蓝色线框，带有变换控制点）
}

/// 组合内容元素Widget
class GroupElementWidget extends PracticeElementWidget {
  @override
  final GroupElement element;

  const GroupElementWidget({
    Key? key,
    required this.element,
    required ElementState state,
    VoidCallback? onTap,
    Function(Offset delta)? onDragUpdate,
    Function(Offset position, double width, double height)? onResizeUpdate,
    Function(double angle)? onRotateUpdate,
  }) : super(
          key: key,
          element: element,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );

  @override
  Widget build(BuildContext context) {
    final borderColor =
        state == ElementState.normal ? Colors.grey : Colors.blue;
    final borderWidth = state == ElementState.normal ? 1.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        // 只有未锁定时才能移动
        if (!element.isLocked) {
          onDragUpdate?.call(details.delta);
        }
      },
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Stack(
          children: [
            // 组合中的子元素
            ...element.children.map((child) {
              return Positioned(
                left: child.x,
                top: child.y,
                child: Transform.rotate(
                  angle: child.rotation * 3.1415926 / 180, // 转换为弧度
                  child: Opacity(
                    opacity: child.opacity * element.opacity, // 组合透明度 * 子元素透明度
                    child: PracticeElementWidget.create(
                      element: child,
                      state: ElementState.normal, // 子元素始终为普通状态
                    ),
                  ),
                ),
              );
            }).toList(),

            // 控制点 (仅在编辑状态显示)
            if (state == ElementState.editing)
              _buildControlHandles(element.width, element.height),
          ],
        ),
      ),
    );
  }
}

/// 图片内容元素Widget
class ImageElementWidget extends PracticeElementWidget {
  @override
  final ImageElement element;

  const ImageElementWidget({
    Key? key,
    required this.element,
    required ElementState state,
    VoidCallback? onTap,
    Function(Offset delta)? onDragUpdate,
    Function(Offset position, double width, double height)? onResizeUpdate,
    Function(double angle)? onRotateUpdate,
  }) : super(
          key: key,
          element: element,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );

  @override
  Widget build(BuildContext context) {
    final borderColor =
        state == ElementState.normal ? Colors.grey : Colors.blue;
    final borderWidth = state == ElementState.normal ? 1.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        // 只有未锁定时才能移动
        if (!element.isLocked) {
          onDragUpdate?.call(details.delta);
        }
      },
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Stack(
          children: [
            // 图片内容
            Positioned.fill(
              child: Opacity(
                opacity: element.opacity,
                child: element.imageUrl.isNotEmpty
                    ? _buildImage()
                    : Container(
                        color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                        child: const Center(child: Icon(Icons.image)),
                      ),
              ),
            ),

            // 控制点 (仅在编辑状态显示)
            if (state == ElementState.editing)
              _buildControlHandles(element.width, element.height),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    Widget image = element.imageUrl.startsWith('http')
        ? Image.network(element.imageUrl, fit: element.fit)
        : Image.asset(element.imageUrl, fit: element.fit);

    // 应用裁剪
    if (element.crop != EdgeInsets.zero) {
      image = ClipRect(
        child: Padding(
          padding: element.crop.flipped,
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: image,
          ),
        ),
      );
    }

    // 应用水平/垂直翻转
    if (element.flipHorizontal || element.flipVertical) {
      image = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(
            element.flipHorizontal ? -1.0 : 1.0,
            element.flipVertical ? -1.0 : 1.0,
          ),
        child: image,
      );
    }

    return image;
  }
}

/// 内容元素基础Widget
class PracticeElementWidget extends StatelessWidget {
  final PracticeElement element;
  final ElementState state;
  final VoidCallback? onTap;
  final Function(Offset delta)? onDragUpdate;
  final Function(Offset position, double width, double height)? onResizeUpdate;
  final Function(double angle)? onRotateUpdate;

  const PracticeElementWidget({
    Key? key,
    required this.element,
    this.state = ElementState.normal,
    this.onTap,
    this.onDragUpdate,
    this.onResizeUpdate,
    this.onRotateUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(); // Base class doesn't render anything
  }

  // 控制点绘制
  Widget _buildControlHandles(double width, double height) {
    const controlSize = 10.0;

    return Stack(
      children: [
        // 四个角控制点 (缩放)
        // 左上
        Positioned(
          left: -controlSize / 2,
          top: -controlSize / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x + delta.dx, element.y + delta.dy),
              element.width - delta.dx,
              element.height - delta.dy,
            ),
            cursor: SystemMouseCursors.resizeUpLeft,
          ),
        ),
        // 右上
        Positioned(
          right: -controlSize / 2,
          top: -controlSize / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x, element.y + delta.dy),
              element.width + delta.dx,
              element.height - delta.dy,
            ),
            cursor: SystemMouseCursors.resizeUpRight,
          ),
        ),
        // 左下
        Positioned(
          left: -controlSize / 2,
          bottom: -controlSize / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x + delta.dx, element.y),
              element.width - delta.dx,
              element.height + delta.dy,
            ),
            cursor: SystemMouseCursors.resizeDownLeft,
          ),
        ),
        // 右下
        Positioned(
          right: -controlSize / 2,
          bottom: -controlSize / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x, element.y),
              element.width + delta.dx,
              element.height + delta.dy,
            ),
            cursor: SystemMouseCursors.resizeDownRight,
          ),
        ),

        // 四个边中点控制点 (水平/垂直缩放)
        // 上中
        Positioned(
          left: (width - controlSize) / 2,
          top: -controlSize / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x, element.y + delta.dy),
              element.width,
              element.height - delta.dy,
            ),
            cursor: SystemMouseCursors.resizeUp,
          ),
        ),
        // 右中
        Positioned(
          right: -controlSize / 2,
          top: (height - controlSize) / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x, element.y),
              element.width + delta.dx,
              element.height,
            ),
            cursor: SystemMouseCursors.resizeRight,
          ),
        ),
        // 下中
        Positioned(
          left: (width - controlSize) / 2,
          bottom: -controlSize / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x, element.y),
              element.width,
              element.height + delta.dy,
            ),
            cursor: SystemMouseCursors.resizeDown,
          ),
        ),
        // 左中
        Positioned(
          left: -controlSize / 2,
          top: (height - controlSize) / 2,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) => onResizeUpdate?.call(
              Offset(element.x + delta.dx, element.y),
              element.width - delta.dx,
              element.height,
            ),
            cursor: SystemMouseCursors.resizeLeft,
          ),
        ),

        // 旋转控制点
        Positioned(
          left: (width - controlSize) / 2,
          top: -30,
          child: _buildControlPoint(
            size: controlSize,
            onDrag: (delta) {
              // 计算旋转角度
              final center = Offset(element.x + element.width / 2,
                  element.y + element.height / 2);
              final position = Offset(center.dx, center.dy - 30) + delta;
              final angle = (position - center).direction;
              onRotateUpdate?.call(angle * 180 / 3.1415926);
            },
            isCircle: true,
            cursor: SystemMouseCursors.move,
          ),
        ),
        // 旋转控制线
        Positioned(
          left: width / 2,
          top: -30 + controlSize / 2,
          child: Container(
            width: 1,
            height: 30 - controlSize / 2,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  // 构建控制点
  Widget _buildControlPoint({
    required double size,
    required Function(Offset) onDrag,
    bool isCircle = false,
    MouseCursor cursor = SystemMouseCursors.move,
  }) {
    // 增加实际点击区域，但保持视觉大小不变
    const hitAreaExpansion = 6.0;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        // 这里使用 onPanStart 捕获拖拽开始事件
        onPanStart: (details) {
          // 防止事件冒泡导致误触发父级容器的拖拽
          details.sourceTimeStamp; // 读取属性防止警告
        },
        onPanUpdate: (details) => onDrag(details.delta),
        // 扩大点击区域，但视觉上保持原来大小
        child: Container(
          width: size + hitAreaExpansion,
          height: size + hitAreaExpansion,
          padding: const EdgeInsets.all(hitAreaExpansion / 2),
          color: Colors.transparent, // 点击区域透明
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 2),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        ),
      ),
    );
  }

  // 创建对应类型的内容元素Widget
  static Widget create({
    required PracticeElement element,
    ElementState state = ElementState.normal,
    VoidCallback? onTap,
    Function(Offset delta)? onDragUpdate,
    Function(Offset position, double width, double height)? onResizeUpdate,
    Function(double angle)? onRotateUpdate,
  }) {
    switch (element.type) {
      case 'text':
        return TextElementWidget(
          element: element as TextElement,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );
      case 'image':
        return ImageElementWidget(
          element: element as ImageElement,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );
      case 'collection':
        return CollectionElementWidget(
          element: element as CollectionElement,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );
      case 'group':
        return GroupElementWidget(
          element: element as GroupElement,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );
      default:
        return Container();
    }
  }
}

/// 文本内容元素Widget
class TextElementWidget extends PracticeElementWidget {
  @override
  final TextElement element;

  const TextElementWidget({
    Key? key,
    required this.element,
    required ElementState state,
    VoidCallback? onTap,
    Function(Offset delta)? onDragUpdate,
    Function(Offset position, double width, double height)? onResizeUpdate,
    Function(double angle)? onRotateUpdate,
  }) : super(
          key: key,
          element: element,
          state: state,
          onTap: onTap,
          onDragUpdate: onDragUpdate,
          onResizeUpdate: onResizeUpdate,
          onRotateUpdate: onRotateUpdate,
        );

  @override
  Widget build(BuildContext context) {
    final borderColor =
        state == ElementState.normal ? Colors.grey : Colors.blue;
    final borderWidth = state == ElementState.normal ? 1.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        // 只有未锁定时才能移动
        if (!element.isLocked) {
          onDragUpdate?.call(details.delta);
        }
      },
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          color: Color(
                  int.parse(element.backgroundColor.substring(1), radix: 16) +
                      0xFF000000)
              .withValues(alpha: element.opacity),
        ),
        padding: element.padding,
        child: Stack(
          children: [
            // 文本内容
            Text(
              element.text,
              style: TextStyle(
                fontSize: element.fontSize,
                fontFamily: element.fontFamily,
                color: Color(
                    int.parse(element.fontColor.substring(1), radix: 16) +
                        0xFF000000),
                height: element.lineSpacing,
                letterSpacing: element.letterSpacing,
              ),
              textAlign: element.textAlign,
            ),

            // 控制点 (仅在编辑状态显示)
            if (state == ElementState.editing)
              _buildControlHandles(element.width, element.height),
          ],
        ),
      ),
    );
  }
}

// 扩展EdgeInsets以支持翻转（用于图片裁剪）
extension EdgeInsetsExt on EdgeInsets {
  EdgeInsets get flipped => EdgeInsets.only(
        left: -left,
        top: -top,
        right: -right,
        bottom: -bottom,
      );
}
