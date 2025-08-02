import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';
import '../../../common/editable_number_field.dart';
import '../../../common/m3_color_picker.dart';
import '../../../image/cached_image.dart';
import 'interactive_crop_overlay.dart';

/// 几何属性面板
class ImagePropertyGeometryPanel extends StatelessWidget {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final Function(String, dynamic) onPropertyUpdate;

  const ImagePropertyGeometryPanel({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onPropertyUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
          title: Text(l10n.geometryProperties),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Information alert
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer
                        .withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.imagePropertyPanelGeometryWarning,
                          style: TextStyle(
                              fontSize: 14, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                // X and Y position
                Row(
                  children: [
                    Expanded(
                      child: EditableNumberField(
                        label: 'X',
                        value: x,
                        suffix: 'px',
                        min: 0,
                        max: 10000,
                        onChanged: (value) => onPropertyUpdate('x', value),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: EditableNumberField(
                        label: 'Y',
                        value: y,
                        suffix: 'px',
                        min: 0,
                        max: 10000,
                        onChanged: (value) => onPropertyUpdate('y', value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // Width and height
                Row(
                  children: [
                    Expanded(
                      child: EditableNumberField(
                        label: l10n.width,
                        value: width,
                        suffix: 'px',
                        min: 10,
                        max: 10000,
                        onChanged: (value) => onPropertyUpdate('width', value),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: EditableNumberField(
                        label: l10n.height,
                        value: height,
                        suffix: 'px',
                        min: 10,
                        max: 10000,
                        onChanged: (value) => onPropertyUpdate('height', value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // Rotation
                EditableNumberField(
                  label: l10n.rotation,
                  value: rotation,
                  suffix: '°',
                  min: -360,
                  max: 360,
                  decimalPlaces: 1,
                  onChanged: (value) => onPropertyUpdate('rotation', value),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 视觉属性面板
class ImagePropertyVisualPanel extends StatelessWidget {
  final double opacity;
  final Color Function() backgroundColor;
  final Function(String, dynamic) onPropertyUpdate;
  final Function(String, dynamic) onContentPropertyUpdate;

  const ImagePropertyVisualPanel({
    super.key,
    required this.opacity,
    required this.backgroundColor,
    required this.onPropertyUpdate,
    required this.onContentPropertyUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
        title: Text(l10n.visualSettings),
        initiallyExpanded: true,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Opacity
                Text('${l10n.opacity}:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Slider(
                        value: opacity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: '${(opacity * 100).toStringAsFixed(0)}%',
                        activeColor: colorScheme.primary,
                        thumbColor: colorScheme.primary,
                        onChanged: (value) =>
                            onPropertyUpdate('opacity', value),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      flex: 2,
                      child: EditableNumberField(
                        label: l10n.opacity,
                        value: opacity * 100, // Convert to percentage
                        suffix: '%',
                        min: 0,
                        max: 100,
                        decimalPlaces: 0,
                        onChanged: (value) {
                          // Convert back to 0-1 range
                          onPropertyUpdate('opacity', value / 100);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                // Background color
                Text('${l10n.backgroundColor}:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final color = await M3ColorPicker.show(
                          context,
                          initialColor: backgroundColor(),
                          enableAlpha: true,
                        );
                        if (color != null) {
                          if (color == Colors.transparent) {
                            onContentPropertyUpdate(
                                'backgroundColor', 'transparent');
                          } else {
                            // Use toARGB32() for an explicit conversion
                            final argb = color.toARGB32();
                            final hexColor =
                                '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
                            onContentPropertyUpdate(
                                'backgroundColor', hexColor);
                          }
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: backgroundColor(),
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                          image: backgroundColor() == Colors.transparent
                              ? const DecorationImage(
                                  image: AssetImage(
                                      'assets/images/transparent_bg.png'),
                                  repeat: ImageRepeat.repeat,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l10n.backgroundColor,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 图像选择面板
class ImagePropertySelectionPanel extends StatelessWidget {
  final VoidCallback onSelectFromLibrary;
  final VoidCallback onSelectFromLocal;

  const ImagePropertySelectionPanel({
    super.key,
    required this.onSelectFromLibrary,
    required this.onSelectFromLocal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
        title: Text(l10n.imageSelection),
        initiallyExpanded: true,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.collections_bookmark),
                  onPressed: onSelectFromLibrary,
                  label: Text(l10n.fromGallery),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8.0),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.photo_library),
                  onPressed: onSelectFromLocal,
                  label: Text(l10n.fromLocal),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 适应模式面板
class ImagePropertyFitModePanel extends StatelessWidget {
  final String fitMode;
  final Function(String) onFitModeChanged;

  const ImagePropertyFitModePanel({
    super.key,
    required this.fitMode,
    required this.onFitModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
        title: Text(l10n.fitMode),
        initiallyExpanded: true,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'contain',
                          label: Text(l10n.fitContain),
                          icon: const Icon(Icons.fit_screen),
                        ),
                        ButtonSegment<String>(
                          value: 'cover',
                          label: Text(l10n.fitCover),
                          icon: const Icon(Icons.crop),
                        ),
                        ButtonSegment<String>(
                          value: 'fill',
                          label: Text(l10n.fitFill),
                          icon: const Icon(Icons.aspect_ratio),
                        ),
                        ButtonSegment<String>(
                          value: 'none',
                          label: Text(l10n.original),
                          icon: const Icon(Icons.image),
                        ),
                      ],
                      selected: {fitMode},
                      onSelectionChanged: (Set<String> selection) {
                        if (selection.isNotEmpty) {
                          onFitModeChanged(selection.first);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 图像预览面板
class ImagePropertyPreviewPanel extends StatelessWidget {
  final String imageUrl;
  final String fitMode;
  final double cropX; // Left edge of crop area in pixels
  final double cropY; // Top edge of crop area in pixels
  final double cropWidth; // Width of crop area in pixels
  final double cropHeight; // Height of crop area in pixels
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final bool isTransformApplied;
  final Size? imageSize;
  final Size? renderSize;
  final Function(Size, Size) onImageSizeAvailable;
  final Function(double, double, double, double, {bool isDragging})?
      onCropChanged; // (x, y, width, height, isDragging)

  const ImagePropertyPreviewPanel({
    super.key,
    required this.imageUrl,
    required this.fitMode,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.contentRotation,
    required this.isTransformApplied,
    required this.imageSize,
    required this.renderSize,
    required this.onImageSizeAvailable,
    this.onCropChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
        title: Text(l10n.preview),
        initiallyExpanded: true,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片信息显示区域
                if (imageUrl.isNotEmpty && imageSize != null)
                  _buildImageInfo(context, l10n, colorScheme),
                const SizedBox(height: 8.0),
                
                _buildImagePreviewWithTransformBox(context),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// 构建图片信息显示区域
  Widget _buildImageInfo(BuildContext context, AppLocalizations l10n, ColorScheme colorScheme) {
    final sizeText = imageSize != null 
        ? '${imageSize!.width.toInt()} × ${imageSize!.height.toInt()} px'
        : l10n.unknown;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.aspect_ratio, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            l10n.imageSizeInfo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sizeText,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewWithTransformBox(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Preview always uses "contain" fit mode
    const previewFitMode = 'contain';

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12.0),
        color:
            colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
      ),
      child: imageUrl.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Layer 1: Transformed image (background)
                    Positioned.fill(
                      child: ClipRect(
                        child: IgnorePointer(  // 防止变换后的图像接收触摸事件
                          child: Transform(
                            transform: Matrix4.identity()
                              ..translate(constraints.maxWidth / 2, constraints.maxHeight / 2)
                              ..rotateZ(contentRotation * (math.pi / 180.0))
                              ..scale(
                                flipHorizontal ? -1.0 : 1.0,
                                flipVertical ? -1.0 : 1.0,
                              )
                              ..translate(-constraints.maxWidth / 2, -constraints.maxHeight / 2),
                            child: _buildImageWithSizeListener(
                              context: context,
                              imageUrl: imageUrl,
                              fitMode: _getFitMode(previewFitMode),
                              onImageSizeAvailable: onImageSizeAvailable,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Layer 2: Normal image (invisible) for coordinate mapping
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.0,  // 完全透明，只用于坐标参考
                        child: _buildImageWithSizeListener(
                          context: context,
                          imageUrl: imageUrl,
                          fitMode: _getFitMode(previewFitMode),
                          onImageSizeAvailable: (_, __) {}, // 避免重复调用
                        ),
                      ),
                    ),
                    
                    // Layer 3: Crop overlay (在正常坐标系中，不应用旋转)
                    if (imageSize != null &&
                        renderSize != null &&
                        onCropChanged != null)
                      Positioned.fill(
                        child: InteractiveCropOverlay(
                          imageSize: imageSize!,
                          renderSize: renderSize!,
                          cropX: cropX,
                          cropY: cropY,
                          cropWidth: cropWidth,
                          cropHeight: cropHeight,
                          contentRotation: 0.0, // 强制设为0，不让裁剪框旋转
                          onCropChanged: onCropChanged!,
                          enabled: true,
                        ),
                      ),
                  ],
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported,
                      size: 48, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(l10n.noImageSelected,
                      style: TextStyle(color: colorScheme.outline)),
                ],
              ),
            ),
    );
  }

  Widget _buildImageWithSizeListener({
    required BuildContext context,
    required String imageUrl,
    required BoxFit fitMode,
    required Function(Size, Size) onImageSizeAvailable,
  }) {
    final l10n = AppLocalizations.of(context);

    // Handle local file paths
    if (imageUrl.startsWith('file://')) {
      try {
        String filePath = imageUrl.substring(7); // Remove 'file://' prefix
        final file = File(filePath);

        if (!file.existsSync()) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(
                  l10n.fileNotExist(filePath),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return CachedImage(
              path: filePath,
              fit: fitMode,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        l10n.imageLoadError(error.toString().substring(
                            0, math.min(error.toString().length, 50))),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
              onImageLoaded: (Size size) {
                // 图像加载完成后获取尺寸
                final imageSize = size;

                // 计算渲染尺寸
                final renderSize = _calculateRenderSize(
                    imageSize,
                    constraints.biggest,
                    fitMode == BoxFit.contain
                        ? 'contain'
                        : fitMode == BoxFit.cover
                            ? 'cover'
                            : fitMode == BoxFit.fill
                                ? 'fill'
                                : 'none');

                // 检查当前 widget 是否仍然挂载
                if (context.mounted) {
                  onImageSizeAvailable(imageSize, renderSize);
                }
              },
            );
          },
        );
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                l10n.imageProcessingPathError(e.toString()),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else {
      // Handle network images
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final imageProvider = NetworkImage(imageUrl);

          final imageStream = imageProvider.resolve(ImageConfiguration(
            size: constraints.biggest,
          ));

          imageStream.addListener(ImageStreamListener(
            (ImageInfo info, bool _) {
              final imageSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );

              final renderSize = _calculateRenderSize(
                imageSize,
                constraints.biggest,
                fitMode == BoxFit.contain
                    ? 'contain'
                    : fitMode == BoxFit.cover
                        ? 'cover'
                        : fitMode == BoxFit.fill
                            ? 'fill'
                            : 'none',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 检查当前 widget 是否仍然挂载
                if (context.mounted) {
                  onImageSizeAvailable(imageSize, renderSize);
                }
              });
            },
            onError: (exception, stackTrace) {
              EditPageLogger.propertyPanelError(
                '图像加载错误',
                tag: EditPageLoggingConfig.TAG_IMAGE_PANEL,
                error: exception,
                stackTrace: stackTrace,
                data: {
                  'operation': 'image_loading',
                  'imageUrl': imageUrl,
                },
              );
            },
          ));

          return Image(
            image: imageProvider,
            fit: fitMode,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              return child;
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      l10n.imageLoadError(error
                          .toString()
                          .substring(0, math.min(error.toString().length, 50))),
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  Size _calculateRenderSize(
      Size imageSize, Size containerSize, String fitMode) {
    final imageRatio = imageSize.width / imageSize.height;
    final containerRatio = containerSize.width / containerSize.height;

    switch (fitMode) {
      case 'contain':
        if (imageRatio > containerRatio) {
          return Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        } else {
          return Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        }
      case 'cover':
        if (imageRatio > containerRatio) {
          return Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        } else {
          return Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        }
      case 'fill':
        return containerSize;
      case 'none':
        return imageSize;
      default:
        return Size(
          math.min(imageSize.width, containerSize.width),
          math.min(imageSize.height, containerSize.height),
        );
    }
  }

  BoxFit _getFitMode(String fitMode) {
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
}

/// 图像变换面板
class ImagePropertyTransformPanel extends StatelessWidget {
  final double cropX; // Left edge of crop area in pixels
  final double cropY; // Top edge of crop area in pixels
  final double cropWidth; // Width of crop area in pixels
  final double cropHeight; // Height of crop area in pixels
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final Function(String, dynamic) onFlipChanged;
  final Function(double) onRotationChanged;
  final VoidCallback onApplyTransform;
  final VoidCallback onResetTransform;

  const ImagePropertyTransformPanel({
    super.key,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.contentRotation,
    required this.onFlipChanged,
    required this.onRotationChanged,
    required this.onApplyTransform,
    required this.onResetTransform,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
        title: Text(l10n.imageTransform),
        initiallyExpanded: true,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message
                // Container(
                //   padding: const EdgeInsets.all(12.0),
                //   margin: const EdgeInsets.only(bottom: 16.0),
                //   decoration: BoxDecoration(
                //     color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                //     borderRadius: BorderRadius.circular(8.0),
                //   ),
                //   child: Row(
                //     children: [
                //       Icon(Icons.info_outline,
                //           color: colorScheme.tertiary, size: 20),
                //       const SizedBox(width: 8),
                //       Expanded(
                //         child: Text(
                //           l10n.imagePropertyPanelTransformWarning,
                //           style: TextStyle(
                //               fontSize: 14, color: colorScheme.tertiary),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // Interactive cropping info
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer
                        .withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.crop_free,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.cropAdjustmentHint,
                          style: TextStyle(
                              fontSize: 14, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                // Current crop values display
                Text(l10n.cropping,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('X: ${cropX.round()}px'),
                            ),
                            Expanded(
                              child: Text('Y: ${cropY.round()}px'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text('${l10n.width}: ${cropWidth.round()}px'),
                            ),
                            Expanded(
                              child: Text('${l10n.height}: ${cropHeight.round()}px'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Flip buttons
                Text(l10n.flip,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),

                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: Text(l10n.flipHorizontal),
                          selected: flipHorizontal,
                          onSelected: (value) =>
                              onFlipChanged('isFlippedHorizontally', value),
                          avatar: const Icon(Icons.flip),
                        ),
                        FilterChip(
                          label: Text(l10n.flipVertical),
                          selected: flipVertical,
                          onSelected: (value) =>
                              onFlipChanged('isFlippedVertically', value),
                          avatar: const Icon(Icons.flip),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Rotation
                Text(l10n.rotation,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Slider(
                        value: contentRotation.clamp(-180.0, 180.0),
                        min: -180.0,
                        max: 180.0,
                        divisions: 360,
                        label: '${contentRotation.toStringAsFixed(0)}°',
                        activeColor: colorScheme.primary,
                        thumbColor: colorScheme.primary,
                        onChanged: onRotationChanged,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      flex: 2,
                      child: EditableNumberField(
                        label: l10n.rotation,
                        value: contentRotation,
                        suffix: '°',
                        min: -180,
                        max: 180,
                        decimalPlaces: 1,
                        onChanged: onRotationChanged,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),

                // 精细角度控制
                Text(l10n.fineRotation,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFineRotationButton(context, l10n, '-0.1°', () {
                          double newRotation = contentRotation - 0.1;
                          // 确保在范围内
                          while (newRotation < -180) {
                            newRotation += 360;
                          }
                          onRotationChanged(newRotation);
                        }),
                        _buildFineRotationButton(context, l10n, '+0.1°', () {
                          double newRotation = contentRotation + 0.1;
                          // 确保在范围内
                          while (newRotation > 180) {
                            newRotation -= 360;
                          }
                          onRotationChanged(newRotation);
                        }),
                      ],
                    ),
                  ),
                ),

                // Quick rotation buttons
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRotationButton(context, '0°', () {
                          onRotationChanged(0.0);
                        }),
                        _buildRotationButton(context, '+90°', () {
                          double newRotation = contentRotation + 90;
                          while (newRotation > 180) {
                            newRotation -= 360;
                          }
                          onRotationChanged(newRotation);
                        }),
                        _buildRotationButton(context, '-90°', () {
                          double newRotation = contentRotation - 90;
                          while (newRotation < -180) {
                            newRotation += 360;
                          }
                          onRotationChanged(newRotation);
                        }),
                        _buildRotationButton(context, '180°', () {
                          double newRotation = contentRotation + 180;
                          while (newRotation > 180) {
                            newRotation -= 360;
                          }
                          onRotationChanged(newRotation);
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24.0),

                // Apply and Reset buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        onPressed: onApplyTransform,
                        label: Text(l10n.applyTransform),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        onPressed: onResetTransform,
                        label: Text(l10n.resetTransform),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRotationButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Text(label),
      tooltip: label,
    );
  }

  Widget _buildFineRotationButton(
      BuildContext context, AppLocalizations l10n, String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: 60,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(6.0),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 图像对齐方式面板
class ImagePropertyAlignmentPanel extends StatelessWidget {
  final String alignment;
  final Function(String) onAlignmentChanged;

  const ImagePropertyAlignmentPanel({
    super.key,
    required this.alignment,
    required this.onAlignmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
        title: Text(l10n.imageAlignment),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 紧凑的工具栏风格按钮组 - 3x3网格布局
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 第一行：上对齐
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactAlignmentButton(context, l10n, 'topLeft', Icons.north_west),
                            const SizedBox(width: 2.0),
                            _buildCompactAlignmentButton(context, l10n, 'topCenter', Icons.north),
                            const SizedBox(width: 2.0),
                            _buildCompactAlignmentButton(context, l10n, 'topRight', Icons.north_east),
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        
                        // 第二行：中对齐
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactAlignmentButton(context, l10n, 'centerLeft', Icons.west),
                            const SizedBox(width: 2.0),
                            _buildCompactAlignmentButton(context, l10n, 'center', Icons.center_focus_strong),
                            const SizedBox(width: 2.0),
                            _buildCompactAlignmentButton(context, l10n, 'centerRight', Icons.east),
                          ],
                        ),
                        const SizedBox(height: 2.0),
                        
                        // 第三行：下对齐
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactAlignmentButton(context, l10n, 'bottomLeft', Icons.south_west),
                            const SizedBox(width: 2.0),
                            _buildCompactAlignmentButton(context, l10n, 'bottomCenter', Icons.south),
                            const SizedBox(width: 2.0),
                            _buildCompactAlignmentButton(context, l10n, 'bottomRight', Icons.south_east),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                
                // 当前选择显示
                Center(
                  child: Text(
                    _getAlignmentDisplayName(l10n, alignment),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCompactAlignmentButton(
    BuildContext context, 
    AppLocalizations l10n,
    String alignmentValue, 
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = alignment == alignmentValue;

    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        border: isSelected ? null : Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(6.0),
          onTap: () => onAlignmentChanged(alignmentValue),
          child: Tooltip(
            message: _getAlignmentDisplayName(l10n, alignmentValue),
            child: Center(
              child: Icon(
                icon,
                size: 14,
                color: isSelected 
                  ? colorScheme.onPrimary 
                  : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getAlignmentDisplayName(AppLocalizations l10n, String alignment) {
    switch (alignment) {
      case 'topLeft': return l10n.topLeft;
      case 'topCenter': return l10n.topCenter;
      case 'topRight': return l10n.topRight;
      case 'centerLeft': return l10n.centerLeft;
      case 'center': return l10n.alignmentCenter;
      case 'centerRight': return l10n.centerRight;
      case 'bottomLeft': return l10n.bottomLeft;
      case 'bottomCenter': return l10n.bottomCenter;
      case 'bottomRight': return l10n.bottomRight;
      default: return l10n.unknown;
    }
  }
}

/// 图像二值化处理面板
class ImagePropertyBinarizationPanel extends StatelessWidget {
  final bool isBinarizationEnabled;
  final double threshold;
  final bool isNoiseReductionEnabled; 
  final double noiseReductionLevel;
  final Function(String, dynamic) onContentPropertyUpdate;

  const ImagePropertyBinarizationPanel({
    super.key,
    required this.isBinarizationEnabled,
    required this.threshold,
    required this.isNoiseReductionEnabled,
    required this.noiseReductionLevel,
    required this.onContentPropertyUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
          title: Text(l10n.binarizationProcessing),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 二值化开关
                  Row(
                    children: [
                      Icon(Icons.tune, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.enableBinarization,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: isBinarizationEnabled,
                        onChanged: (value) => onContentPropertyUpdate('isBinarizationEnabled', value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // 二值化参数组（仅在开关打开时启用）
                  AnimatedOpacity(
                    opacity: isBinarizationEnabled ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 二值化阈值
                        Text(l10n.binaryThreshold,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8.0),
                        
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.contrast, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Slider(
                                    value: threshold.clamp(0.0, 255.0),
                                    min: 0.0,
                                    max: 255.0,
                                    divisions: 255,
                                    label: threshold.toStringAsFixed(0),
                                    activeColor: isBinarizationEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.38),
                                    thumbColor: isBinarizationEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.38),
                                    onChanged: isBinarizationEnabled ? (value) => onContentPropertyUpdate('binaryThreshold', value) : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    threshold.toStringAsFixed(0),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isBinarizationEnabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.38),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // 降噪开关
                        Row(
                          children: [
                            Icon(Icons.blur_on, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.noiseReductionToggle,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Switch(
                              value: isNoiseReductionEnabled,
                              onChanged: isBinarizationEnabled ? (value) => onContentPropertyUpdate('isNoiseReductionEnabled', value) : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),

                        // 降噪强度（仅在降噪开关打开时启用）
                        AnimatedOpacity(
                          opacity: (isBinarizationEnabled && isNoiseReductionEnabled) ? 1.0 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          child: Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.tune, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Slider(
                                      value: noiseReductionLevel.clamp(0.0, 10.0),
                                      min: 0.0,
                                      max: 10.0,
                                      divisions: 100,
                                      label: noiseReductionLevel.toStringAsFixed(1),
                                      activeColor: (isBinarizationEnabled && isNoiseReductionEnabled) ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.38),
                                      thumbColor: (isBinarizationEnabled && isNoiseReductionEnabled) ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.38),
                                      onChanged: (isBinarizationEnabled && isNoiseReductionEnabled) ? (value) => onContentPropertyUpdate('noiseReductionLevel', value) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      noiseReductionLevel.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (isBinarizationEnabled && isNoiseReductionEnabled) ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.38),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
