import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../image/cached_image.dart';
import 'collection_element_renderer.dart';
import 'text_renderer.dart';

/// 元素渲染器，负责渲染不同类型的元素，将不同类型的元素渲染委托给专门的渲染器处理
class ElementRenderers {
  /// 构建集字元素
  static Widget buildCollectionElement(Map<String, dynamic> element,
      {WidgetRef? ref, bool isPreviewMode = false}) {
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
    final fontColorStr = content['fontColor'] as String? ?? '#000000';
    final backgroundColorStr =
        content['backgroundColor'] as String? ?? '#FFFFFF';
    final backgroundColor = _parseColor(backgroundColorStr);
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final enableSoftLineBreak =
        content['enableSoftLineBreak'] as bool? ?? false;

    // 获取集字图片列表（实际应用中应该从数据库或其他存储中获取）
    final characterImages = content['characterImages'];

    // 获取背景纹理设置
    final hasBackgroundTexture = content.containsKey('backgroundTexture') &&
        content['backgroundTexture'] != null &&
        content['backgroundTexture'] is Map<String, dynamic> &&
        (content['backgroundTexture'] as Map<String, dynamic>).isNotEmpty;
    final backgroundTexture = hasBackgroundTexture
        ? content['backgroundTexture'] as Map<String, dynamic>
        : null;
    final textureApplicationRange =
        content['textureApplicationRange'] as String? ?? 'character';
    final textureFillMode = content['textureFillMode'] as String? ?? 'repeat';
    final textureOpacity =
        (content['textureOpacity'] as num?)?.toDouble() ?? 1.0;

    // 添加调试信息
    debugPrint(
        'ElementRenderers.buildCollectionElement: hasBackgroundTexture=$hasBackgroundTexture');
    if (hasBackgroundTexture) {
      debugPrint(
          'ElementRenderers.buildCollectionElement: backgroundTexture=$backgroundTexture');
      debugPrint(
          'ElementRenderers.buildCollectionElement: textureApplicationRange=$textureApplicationRange');
      debugPrint(
          'ElementRenderers.buildCollectionElement: textureFillMode=$textureFillMode');
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      // 移除背景图片装饰，改为完全由CollectionElementRenderer处理纹理
      decoration: BoxDecoration(color: backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 添加调试信息
          debugPrint('buildCollectionElement纹理参数: \n'
              '  hasTexture: $hasBackgroundTexture\n'
              '  textureData: $backgroundTexture\n'
              '  fillMode: $textureFillMode\n'
              '  opacity: $textureOpacity\n'
              '  range: $textureApplicationRange');

          debugPrint('ElementRenderers: 准备构建集字布局');
          debugPrint('- 纹理数据: $backgroundTexture');
          debugPrint('- 纹理填充模式: $textureFillMode');
          debugPrint('- 纹理不透明度: $textureOpacity');
          debugPrint('- 纹理应用范围: $textureApplicationRange');

          return CollectionElementRenderer.buildCollectionLayout(
            characters: characters,
            writingMode: writingMode,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            lineSpacing: lineSpacing,
            textAlign: textAlign,
            verticalAlign: verticalAlign,
            characterImages: content, // 传递完整的 content 以包含所有纹理相关设置
            constraints: constraints,
            padding: padding,
            fontColor: fontColorStr,
            backgroundColor: backgroundColorStr,
            enableSoftLineBreak: enableSoftLineBreak,
            // 传递纹理设置
            hasCharacterTexture: hasBackgroundTexture,
            characterTextureData: backgroundTexture,
            textureFillMode: textureFillMode,
            textureOpacity: textureOpacity,
            textureApplicationRange:
                textureApplicationRange, // Pass the application mode explicitly
            ref: ref,
          );
        },
      ),
    );
  }

  /// 构建组合元素
  static Widget buildGroupElement(Map<String, dynamic> element,
      {bool isSelected = false, WidgetRef? ref, bool isPreviewMode = false}) {
    final content = element['content'] as Map<String, dynamic>;
    final List<dynamic> children = content['children'] as List<dynamic>;

    // 检查children是否为空
    if (children.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.withAlpha(26), // 0.1 opacity (26/255)
        child: const Center(
          child: Text('空组合'),
        ),
      );
    }

    // 使用Stack来渲染所有子元素
    return Stack(
      children: [
        // 先渲染子元素
        Stack(
          clipBehavior: Clip.none,
          children: children.map<Widget>((child) {
            final String type = child['type'] as String;
            final double x = (child['x'] as num).toDouble();
            final double y = (child['y'] as num).toDouble();
            final double width = (child['width'] as num).toDouble();
            final double height = (child['height'] as num).toDouble();
            final double rotation =
                (child['rotation'] as num? ?? 0.0).toDouble();
            final double opacity = (child['opacity'] as num? ?? 1.0).toDouble();
            final bool isHidden = child['hidden'] as bool? ?? false;

            // 如果元素被隐藏，则不渲染（预览模式）或半透明显示（编辑模式）
            if (isHidden && isPreviewMode) {
              return const SizedBox.shrink();
            }

            // 根据子元素类型渲染不同的内容
            Widget childWidget;
            switch (type) {
              case 'text':
                childWidget =
                    buildTextElement(child, isPreviewMode: isPreviewMode);
                break;
              case 'image':
                childWidget =
                    buildImageElement(child, isPreviewMode: isPreviewMode);
                break;
              case 'collection':
                childWidget = buildCollectionElement(child,
                    ref: ref, isPreviewMode: isPreviewMode);
                break;
              case 'group':
                // 递归处理嵌套组合，并传递选中状态
                childWidget = buildGroupElement(child,
                    isSelected: isSelected,
                    ref: ref,
                    isPreviewMode: isPreviewMode);
                break;
              default:
                childWidget = Container(
                  color: Colors.grey.withAlpha(51), // 0.2 的不透明度
                  child: Center(child: Text('未知元素类型: $type')),
                );
            }

            // 使用Positioned和Transform确保子元素在正确的位置和角度
            return Positioned(
              left: x,
              top: y,
              width: width,
              height: height,
              child: Transform.rotate(
                angle: rotation * (3.14159265359 / 180),
                // 添加原点参数，确保旋转以元素中心为原点
                alignment: Alignment.center,
                child: Opacity(
                  opacity: isHidden && !isPreviewMode ? 0.5 : opacity,
                  child: Container(
                    width: width,
                    height: height,
                    decoration: isPreviewMode
                        ? null // 预览模式下不显示边框
                        : BoxDecoration(
                            border: Border.all(
                              // 根据组合选中状态决定边框颜色
                              color: isSelected
                                  ? Colors.blue
                                      .withAlpha(179) // 选中状态：蓝色边框，70% 的不透明度
                                  : Colors.grey
                                      .withAlpha(128), // 默认状态：灰色边框，50% 的不透明度
                              width: 1.0,
                            ),
                          ),
                    child: childWidget,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // 添加一个透明的背景，确保整个组合区域可点击
        Positioned.fill(
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  /// 构建图片元素
  static Widget buildImageElement(Map<String, dynamic> element,
      {bool isPreviewMode = false}) {
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';
    final transformedImageUrl = content['transformedImageUrl'] as String?;
    final fitMode = content['fitMode'] as String? ?? 'contain';
    final backgroundColor = content['backgroundColor'] as String?;

    // 新增支持：直接存储图像数据
    final String? base64ImageData = content['base64ImageData'] as String?;
    final Uint8List? rawImageData = content['rawImageData'] as Uint8List?;

    // 处理transformedImageData，可能是Uint8List或List<int>
    Uint8List? transformedImageData;
    final dynamic rawTransformedData = content['transformedImageData'];
    if (rawTransformedData is Uint8List) {
      transformedImageData = rawTransformedData;
    } else if (rawTransformedData is List<int>) {
      transformedImageData = Uint8List.fromList(rawTransformedData);
    }

    // 解析背景颜色
    Color? bgColor;
    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      try {
        // 处理带#前缀的颜色代码
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;

        // 添加FF前缀表示完全不透明
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;

        // 解析颜色
        bgColor = Color(int.parse(fullColorStr, radix: 16));
      } catch (e) {
        debugPrint('解析背景颜色失败: $e');
      }
    }

    // 如果图片URL为空且没有图像数据，显示占位符
    if (imageUrl.isEmpty &&
        base64ImageData == null &&
        rawImageData == null &&
        transformedImageData == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        color: bgColor ?? Colors.grey.shade200,
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    // 优先级：转换后的图像数据 > 转换后的图像URL > 原始图像数据（base64或raw）> 原始图像URL
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor, // 应用背景颜色
      child: _buildImageWidget(
        imageUrl: transformedImageUrl ?? imageUrl,
        fitMode: fitMode,
        transformedImageData: transformedImageData,
        base64ImageData: base64ImageData,
        rawImageData: rawImageData,
      ),
    );
  }

  /// 构建文本元素
  static Widget buildTextElement(Map<String, dynamic> element,
      {bool isPreviewMode = false}) {
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final text = content['text'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final fontWeight = content['fontWeight'] as String? ?? 'normal';
    final fontStyle = content['fontStyle'] as String? ?? 'normal';
    final fontColorStr = content['fontColor'] as String? ?? '#000000';
    final backgroundColorStr =
        content['backgroundColor'] as String? ?? 'transparent';
    final textAlignStr = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final lineHeight = (content['lineHeight'] as num?)?.toDouble() ?? 1.2;
    final underline = content['underline'] as bool? ?? false;
    final lineThrough = content['lineThrough'] as bool? ?? false;
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 解析背景颜色（fontColor由TextRenderer处理）
    final backgroundColor = _parseColor(backgroundColorStr);

    // 使用TextRenderer创建文本样式，确保正确应用字重
    final textStyle = TextRenderer.createTextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontColor: fontColorStr,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      underline: underline,
      lineThrough: lineThrough,
    );

    // 使用 LayoutBuilder 获取容器约束
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用与文本属性面板预览区完全相同的容器结构
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Container(
            // 移除固定的对齐方式，让内部的TextRenderer决定对齐方式
            decoration: BoxDecoration(
              color: backgroundColor,
              // 移除非选中状态下的灰色边框
              border: null, // 不再显示边框
              // 移除圆角
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: writingMode.startsWith('vertical')
                  ? TextRenderer.renderVerticalText(
                      text: text,
                      style: textStyle,
                      textAlign: textAlignStr,
                      verticalAlign: verticalAlign,
                      writingMode: writingMode,
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - padding * 2,
                        maxHeight: constraints.maxHeight - padding * 2,
                      ),
                      backgroundColor: Colors.transparent, // 已经在外层容器中设置了背景色
                    )
                  : TextRenderer.renderHorizontalText(
                      text: text,
                      style: textStyle,
                      textAlign: textAlignStr,
                      verticalAlign: verticalAlign,
                      writingMode: writingMode,
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - padding * 2,
                        maxHeight: constraints.maxHeight - padding * 2,
                      ),
                      backgroundColor: Colors.transparent, // 已经在外层容器中设置了背景色
                    ),
            ),
          ),
        );
      },
    );
  }

  /// 构建图像加载错误的占位Widget
  static Widget _buildImageErrorWidget(String errorMessage) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(errorMessage, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// 构建图片小部件，根据数据类型选择不同的加载方式
  static Widget _buildImageWidget({
    required String imageUrl,
    required String fitMode,
    Uint8List? transformedImageData,
    Uint8List? rawImageData,
    String? base64ImageData,
  }) {
    final BoxFit fit = _getFitMode(fitMode);

    // 优先使用转换后的图像数据
    if (transformedImageData != null) {
      return Image.memory(
        transformedImageData,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载内存图片数据失败: $error');
          return _buildImageErrorWidget('加载内存图片数据失败');
        },
      );
    }

    // 其次使用原始图像数据（raw形式）
    if (rawImageData != null) {
      return Image.memory(
        rawImageData,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载原始图片数据失败: $error');
          return _buildImageErrorWidget('加载原始图片数据失败');
        },
      );
    }

    // 再次使用Base64编码的图像数据
    if (base64ImageData != null && base64ImageData.isNotEmpty) {
      try {
        // 解码Base64数据为二进制
        final Uint8List decodedBytes = base64Decode(base64ImageData);
        return Image.memory(
          decodedBytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('解码Base64图片数据失败: $error');
            return _buildImageErrorWidget('解码Base64图片数据失败');
          },
        );
      } catch (e) {
        debugPrint('Base64解码错误: $e');
        return _buildImageErrorWidget('Base64图片数据格式错误');
      }
    }

    // 最后使用URL（文件或网络）
    if (imageUrl.isEmpty) {
      return _buildImageErrorWidget('没有可用的图像数据');
    }

    // 检查是否是本地文件路径
    if (imageUrl.startsWith('file://')) {
      // 提取文件路径（去掉file://前缀）
      final filePath = imageUrl.substring(7);

      // 使用CachedImage加载本地文件
      return CachedImage(
        path: filePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载本地图片失败: $error');
          return _buildImageErrorWidget('加载本地图片失败');
        },
      );
    } else {
      // 使用网络图片加载
      return Image.network(
        imageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget('加载网络图片失败');
        },
      );
    }
  }

  /// 根据填充模式获取BoxFit
  static BoxFit _getBoxFit(String fillMode) {
    switch (fillMode) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'noRepeat':
        return BoxFit.none;
      default:
        return BoxFit.none; // 对于repeat/repeatX/repeatY使用none，由ImageRepeat控制
    }
  }

  /// 获取图片适应模式
  static BoxFit _getFitMode(String fitMode) {
    switch (fitMode) {
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.contain;
    }
  }

  /// 根据填充模式获取ImageRepeat
  static ImageRepeat _getImageRepeat(String fillMode) {
    switch (fillMode) {
      case 'repeat':
        return ImageRepeat.repeat;
      case 'repeatX':
        return ImageRepeat.repeatX;
      case 'repeatY':
        return ImageRepeat.repeatY;
      default:
        return ImageRepeat.noRepeat;
    }
  }

  /// 解析颜色字符串
  static Color _parseColor(String colorStr) {
    if (colorStr == 'transparent') return Colors.transparent;

    try {
      final buffer = StringBuffer();
      if (colorStr.startsWith('#')) {
        if (colorStr.length == 7) {
          // #RRGGBB format
          buffer.write('ff'); // Add full opacity
          buffer.write(colorStr.substring(1));
        } else if (colorStr.length == 9) {
          // #AARRGGBB format
          buffer.write(colorStr.substring(1));
        } else {
          debugPrint('Invalid color format: $colorStr');
          return Colors.black; // Invalid format
        }
      } else {
        buffer.write('ff'); // Default full opacity
        buffer.write(colorStr);
      }

      final hexString = buffer.toString();
      // debugPrint('解析颜色: $colorStr -> 0x$hexString');

      final colorValue = int.parse(hexString, radix: 16);
      final color = Color(colorValue);

      // debugPrint('颜色解析结果: $colorStr -> $color');

      return color;
    } catch (e) {
      debugPrint('Error parsing color: $e, colorStr: $colorStr');
      return Colors.black;
    }
  }
}
