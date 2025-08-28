import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../infrastructure/logging/logger.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/config/edit_page_logging_config.dart';
import '../../../../utils/image_validator.dart' as validator;
import '../../../common/editable_number_field.dart';
import '../../../common/m3_color_picker.dart';
import '../../../image/cached_image.dart';
import '../m3_panel_styles.dart';
import 'interactive_crop_overlay.dart';
import 'image_zoom_preview_dialog.dart';

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

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_geometry_properties',
      title: l10n.geometryProperties,
      defaultExpanded: true,
      children: [
        // Information alert
        Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt()),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.imagePropertyPanelGeometryWarning,
                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
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
    );
  }
}

/// 视觉属性面板
class ImagePropertyVisualPanel extends StatelessWidget {
  final double opacity;
  final Color Function() backgroundColor;
  final Function(String, dynamic) onPropertyUpdate;
  final Function(String, dynamic) onContentPropertyUpdate;
  final Function(String, dynamic)? onPropertyUpdatePreview; // 新增预览回调
  final Function(String, dynamic)? onPropertyUpdateStart; // 新增开始回调
  final Function(String, dynamic)? onPropertyUpdateWithUndo; // 新增基于原始值的undo回调

  const ImagePropertyVisualPanel({
    super.key,
    required this.opacity,
    required this.backgroundColor,
    required this.onPropertyUpdate,
    required this.onContentPropertyUpdate,
    this.onPropertyUpdatePreview, // 可选参数
    this.onPropertyUpdateStart, // 可选参数
    this.onPropertyUpdateWithUndo, // 可选参数
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_visual_settings',
      title: l10n.visualSettings,
      defaultExpanded: true,
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
                onChangeStart: onPropertyUpdateStart != null
                    ? (value) => onPropertyUpdateStart!('opacity', opacity)
                    : null,
                onChanged: (value) {
                  if (onPropertyUpdatePreview != null) {
                    onPropertyUpdatePreview!('opacity', value);
                  } else {
                    onPropertyUpdate('opacity', value);
                  }
                },
                onChangeEnd: (value) {
                  // 优先使用基于原始值的undo回调
                  if (onPropertyUpdateWithUndo != null) {
                    onPropertyUpdateWithUndo!('opacity', value);
                  } else {
                    onPropertyUpdate('opacity', value);
                  }
                },
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
                    onContentPropertyUpdate('backgroundColor', 'transparent');
                  } else {
                    // Use toARGB32() for an explicit conversion
                    final argb = color.toARGB32();
                    final hexColor =
                        '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
                    onContentPropertyUpdate('backgroundColor', hexColor);
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
                          image: AssetImage('assets/images/transparent_bg.png'),
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

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_selection',
      title: l10n.imageSelection,
      defaultExpanded: true,
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

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_fit_mode',
      title: l10n.fitMode,
      defaultExpanded: true,
      children: [
        // 4个独立按钮，支持自动换行和居中对齐
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            // Contain 按钮
            _buildFitModeButton(
              context,
              l10n,
              colorScheme,
              'contain',
              l10n.fitContain,
              Icons.fit_screen,
            ),

            // Cover 按钮
            _buildFitModeButton(
              context,
              l10n,
              colorScheme,
              'cover',
              l10n.fitCover,
              Icons.crop,
            ),

            // Fill 按钮
            _buildFitModeButton(
              context,
              l10n,
              colorScheme,
              'fill',
              l10n.fitFill,
              Icons.aspect_ratio,
            ),

            // None 按钮
            _buildFitModeButton(
              context,
              l10n,
              colorScheme,
              'none',
              l10n.original,
              Icons.image,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFitModeButton(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    String modeValue,
    String label,
    IconData icon,
  ) {
    final isSelected = fitMode == modeValue;

    return SizedBox(
      height: 48.0,
      child: ElevatedButton.icon(
        onPressed: () => onFitModeChanged(modeValue),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          foregroundColor:
              isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}

/// 图像预览面板 - 简化版本，去掉缩放平移功能
class ImagePropertyPreviewPanel extends StatelessWidget {
  final String imageUrl;
  final String fitMode;
  final double cropX;
  final double cropY;
  final double cropWidth;
  final double cropHeight;
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final bool isTransformApplied;
  final Size? imageSize;
  final Size? renderSize;
  final Function(Size, Size) onImageSizeAvailable;
  final Function(double, double, double, double, {bool isDragging})?
      onCropChanged;

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

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_preview',
      title: l10n.preview,
      defaultExpanded: true,
      children: [
        // 图片信息显示区域
        if (imageUrl.isNotEmpty && imageSize != null)
          _buildImageInfo(context, l10n, colorScheme),
        const SizedBox(height: 8.0),

        _buildImagePreview(context),
      ],
    );
  }

  /// 构建图片信息显示区域
  Widget _buildImageInfo(
      BuildContext context, AppLocalizations l10n, ColorScheme colorScheme) {
    final sizeText = imageSize != null
        ? '${imageSize!.width.toInt()} × ${imageSize!.height.toInt()} px'
        : l10n.unknown;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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

  Widget _buildImagePreview(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12.0),
        color:
            colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
      ),
      child: Stack(
        children: [
          // 主要图像显示区域
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      Size? currentImageSize = imageSize;
                      Size? currentRenderSize = renderSize;

                      return Stack(
                        children: [
                          // Simple centered image with Transform
                          Positioned.fill(
                            child: Center(
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateZ(contentRotation * (math.pi / 180.0))
                                  ..scale(
                                    flipHorizontal ? -1.0 : 1.0,
                                    flipVertical ? -1.0 : 1.0,
                                  ),
                                child: _buildImageWithSizeListener(
                                  context: context,
                                  imageUrl: imageUrl,
                                  fitMode: BoxFit.contain, // 🔧 关键修复：预览面板固定使用 contain 模式，不受属性面板 fitMode 影响
                                  onImageSizeAvailable:
                                      (detectedImageSize, detectedRenderSize) {
                                    // Always call when image size is detected
                                    // This ensures that when a new image is loaded,
                                    // the size information gets updated properly
                                    onImageSizeAvailable(
                                        detectedImageSize, detectedRenderSize);
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Simple crop overlay
                          if (currentImageSize != null &&
                              currentRenderSize != null &&
                              onCropChanged != null)
                            Positioned.fill(
                              child: InteractiveCropOverlay(
                                imageSize: currentImageSize,
                                renderSize: currentRenderSize,
                                cropX: cropX,
                                cropY: cropY,
                                cropWidth: cropWidth,
                                cropHeight: cropHeight,
                                contentRotation: contentRotation,
                                flipHorizontal: flipHorizontal,
                                flipVertical: flipVertical,
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
          ),

          // 放大预览按钮
          if (imageUrl.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showZoomPreviewDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withAlpha((0.9 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.zoomPreview,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 显示放大预览对话框
  Future<void> _showZoomPreviewDialog(BuildContext context) async {
    if (imageUrl.isEmpty || imageSize == null || renderSize == null) return;

    await showDialog<bool>(
      context: context,
      builder: (context) => ImageZoomPreviewDialog(
        imageUrl: imageUrl,
        fitMode: fitMode,
        cropX: cropX,
        cropY: cropY,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
        flipHorizontal: flipHorizontal,
        flipVertical: flipVertical,
        contentRotation: contentRotation,
        imageSize: imageSize,
        renderSize: renderSize,
        onImageSizeAvailable: onImageSizeAvailable,
        onCropChanged: onCropChanged,
      ),
    );

    // 如果用户确认了更改，对话框内部已经通过 onCropChanged 回调更新了裁剪参数
    // 这里不需要额外处理
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
        // Remove file:/// prefix for Windows or file:// for compatibility
        String filePath = imageUrl.startsWith('file:///')
            ? imageUrl.substring(8)  // file:///C:/... -> C:/...
            : imageUrl.substring(7); // file://path -> path (for compatibility)
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
              onImageLoaded: (Size size) async {
                // 🔧 关键修复：先尝试获取真实图像尺寸，解决Flutter的16384限制问题
                Size? realImageSize;
                
                // 尝试直接从文件获取真实尺寸（绕过Flutter限制）
                try {
                  realImageSize = await validator.ImageValidator.getRealImageSize(filePath);
                } catch (e) {
                  AppLogger.debug('获取真实图像尺寸失败，使用Flutter检测尺寸', data: {
                    'error': e.toString(),
                    'filePath': filePath,
                  });
                }
                
                // 使用真实尺寸或Flutter检测尺寸
                final imageSize = realImageSize ?? size;
                
                AppLogger.debug('图像尺寸检测结果', data: {
                  'flutterDetected': '${size.width.toInt()}x${size.height.toInt()}',
                  'realDetected': realImageSize != null ? '${realImageSize.width.toInt()}x${realImageSize.height.toInt()}' : 'null',
                  'finalUsed': '${imageSize.width.toInt()}x${imageSize.height.toInt()}',
                  'hasLimitation': realImageSize != null && (realImageSize.width != size.width || realImageSize.height != size.height),
                });

                // 🔧 修复：延迟到构建完成后再调用回调，避免setState during build错误
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    // 🔧 智能修复：只有在确实需要时才调用onImageSizeAvailable
                    // 检查当前是否缺少图像尺寸信息（新建元素）还是已有完整信息（防止重置）
                    
                    final hasExistingImageSize = this.imageSize != null;
                    final hasExistingRenderSize = renderSize != null;
                    
                    if (!hasExistingImageSize || !hasExistingRenderSize) {
                      // 情况1：新建元素或缺少尺寸信息，需要初始化
                      // 🔧 关键修复：预览面板始终使用 'contain' 模式，不受属性面板 fitMode 影响
                      const previewFitMode = 'contain'; // 预览面板固定使用 contain 模式
                      final renderSize = _calculateRenderSize(
                        imageSize,
                        constraints.biggest,
                        previewFitMode, // 使用固定的预览适配模式
                      );
                      
                      AppLogger.debug(
                        '🔍 新建图像元素需要初始化尺寸信息',
                        tag: 'ImagePropertyPreviewPanel', 
                        data: {
                          'imageSize': '${imageSize.width}x${imageSize.height}',
                          'renderSize': '${renderSize.width}x${renderSize.height}',
                          'reason': '新建元素或缺少尺寸信息（预览面板固定contain模式）',
                          'hasExistingImageSize': hasExistingImageSize,
                          'hasExistingRenderSize': hasExistingRenderSize,
                        },
                      );
                      
                      onImageSizeAvailable(imageSize, renderSize);
                    } else {
                      // 情况2：已有完整尺寸信息，跳过调用以保护现有裁剪区域
                      AppLogger.debug(
                        '✅ 图像元素已有完整尺寸信息，跳过onImageSizeAvailable调用以保护裁剪区域',
                        tag: 'ImagePropertyPreviewPanel', 
                        data: {
                          'imageSize': '${imageSize.width}x${imageSize.height}',
                          'reason': '避免重置现有裁剪区域',
                          'hasExistingImageSize': hasExistingImageSize,
                          'hasExistingRenderSize': hasExistingRenderSize,
                        },
                      );
                    }
                  }
                });
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

              // 🔧 修复：延迟到构建完成后再调用回调，避免setState during build错误
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  // 🔧 智能修复：只有在确实需要时才调用onImageSizeAvailable（网络图像）
                  // 检查当前是否缺少图像尺寸信息（新建元素）还是已有完整信息（防止重置）
                  
                  final hasExistingImageSize = this.imageSize != null;
                  final hasExistingRenderSize = renderSize != null;
                  
                  if (!hasExistingImageSize || !hasExistingRenderSize) {
                    // 情况1：新建元素或缺少尺寸信息，需要初始化
                    // 🔧 关键修复：预览面板始终使用 'contain' 模式，不受属性面板 fitMode 影响
                    const previewFitMode = 'contain'; // 预览面板固定使用 contain 模式
                    final renderSize = _calculateRenderSize(
                      imageSize,
                      constraints.biggest,
                      previewFitMode, // 使用固定的预览适配模式
                    );
                    
                    AppLogger.debug(
                      '🔍 新建网络图像元素需要初始化尺寸信息',
                      tag: 'ImagePropertyPreviewPanel',
                      data: {
                        'imageSize': '${imageSize.width}x${imageSize.height}',
                        'renderSize': '${renderSize.width}x${renderSize.height}',
                        'reason': '新建元素或缺少尺寸信息（网络图像，预览面板固定contain模式）',
                        'hasExistingImageSize': hasExistingImageSize,
                        'hasExistingRenderSize': hasExistingRenderSize,
                      },
                    );
                    
                    onImageSizeAvailable(imageSize, renderSize);
                  } else {
                    // 情况2：已有完整尺寸信息，跳过调用以保护现有裁剪区域
                    AppLogger.debug(
                      '✅ 网络图像元素已有完整尺寸信息，跳过onImageSizeAvailable调用以保护裁剪区域',
                      tag: 'ImagePropertyPreviewPanel',
                      data: {
                        'imageSize': '${imageSize.width}x${imageSize.height}',
                        'reason': '避免重置现有裁剪区域（网络图像）',
                        'hasExistingImageSize': hasExistingImageSize,
                        'hasExistingRenderSize': hasExistingRenderSize,
                      },
                    );
                  }
                }
              });
            },
            onError: (exception, stackTrace) {
              EditPageLogger.propertyPanelError(
                '图像加载错误',
                tag: EditPageLoggingConfig.tagImagePanel,
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

    Size result;
    switch (fitMode) {
      case 'contain':
        if (imageRatio > containerRatio) {
          // Image is wider, fit by width
          result = Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        } else {
          // Image is taller, fit by height
          result = Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        }
        break;
      case 'cover':
        if (imageRatio > containerRatio) {
          result = Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
        } else {
          result = Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        }
        break;
      case 'fill':
        result = containerSize;
        break;
      case 'none':
        result = imageSize;
        break;
      default:
        result = Size(
          math.min(imageSize.width, containerSize.width),
          math.min(imageSize.height, containerSize.height),
        );
        break;
    }

    return result;
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

  /// 将BoxFit枚举转换为字符串
  String _boxFitToString(BoxFit fitMode) {
    switch (fitMode) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      default:
        return 'contain';
    }
  }
}

/// 图像变换面板 (只包含裁剪)
class ImagePropertyTransformPanel extends StatelessWidget {
  final double cropX; // Left edge of crop area in pixels
  final double cropY; // Top edge of crop area in pixels
  final double cropWidth; // Width of crop area in pixels
  final double cropHeight; // Height of crop area in pixels
  final VoidCallback onApplyTransform;
  final VoidCallback onResetTransform;

  const ImagePropertyTransformPanel({
    super.key,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.onApplyTransform,
    required this.onResetTransform,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_transform',
      title: l10n.imageTransform,
      defaultExpanded: true,
      children: [
        // Interactive cropping info
        Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt()),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(Icons.crop_free, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.cropAdjustmentHint,
                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
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
                // 显示裁剪参数
                _buildCropDisplay(context),
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
    );
  }

  /// 构建裁剪参数显示
  Widget _buildCropDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 裁剪区域标题
        Text(
          '裁剪区域',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'X: ${cropX.round()}px',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Y: ${cropY.round()}px',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.width}: ${cropWidth.round()}px',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${l10n.height}: ${cropHeight.round()}px',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
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

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_alignment',
      title: l10n.imageAlignment,
      defaultExpanded: false,
      children: [
        // 紧凑的工具栏风格按钮组 - 3x3网格布局
        Center(
          child: Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
              border:
                  Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行：上对齐
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactAlignmentButton(
                        context, l10n, 'topLeft', Icons.north_west),
                    const SizedBox(width: 2.0),
                    _buildCompactAlignmentButton(
                        context, l10n, 'topCenter', Icons.north),
                    const SizedBox(width: 2.0),
                    _buildCompactAlignmentButton(
                        context, l10n, 'topRight', Icons.north_east),
                  ],
                ),
                const SizedBox(height: 2.0),

                // 第二行：中对齐
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactAlignmentButton(
                        context, l10n, 'centerLeft', Icons.west),
                    const SizedBox(width: 2.0),
                    _buildCompactAlignmentButton(
                        context, l10n, 'center', Icons.center_focus_strong),
                    const SizedBox(width: 2.0),
                    _buildCompactAlignmentButton(
                        context, l10n, 'centerRight', Icons.east),
                  ],
                ),
                const SizedBox(height: 2.0),

                // 第三行：下对齐
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactAlignmentButton(
                        context, l10n, 'bottomLeft', Icons.south_west),
                    const SizedBox(width: 2.0),
                    _buildCompactAlignmentButton(
                        context, l10n, 'bottomCenter', Icons.south),
                    const SizedBox(width: 2.0),
                    _buildCompactAlignmentButton(
                        context, l10n, 'bottomRight', Icons.south_east),
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
        border: isSelected
            ? null
            : Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
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
      case 'topLeft':
        return l10n.topLeft;
      case 'topCenter':
        return l10n.topCenter;
      case 'topRight':
        return l10n.topRight;
      case 'centerLeft':
        return l10n.centerLeft;
      case 'center':
        return l10n.alignmentCenter;
      case 'centerRight':
        return l10n.centerRight;
      case 'bottomLeft':
        return l10n.bottomLeft;
      case 'bottomCenter':
        return l10n.bottomCenter;
      case 'bottomRight':
        return l10n.bottomRight;
      default:
        return l10n.unknown;
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
  final Function(bool) onBinarizationToggle;
  final Function(String, dynamic) onBinarizationParameterChange;
  final Function(String, dynamic)? onContentPropertyUpdatePreview; // 新增预览回调
  final Function(String, dynamic)? onContentPropertyUpdateStart; // 新增开始回调
  final Function(String, dynamic)?
      onContentPropertyUpdateWithUndo; // 新增基于原始值的undo回调

  const ImagePropertyBinarizationPanel({
    super.key,
    required this.isBinarizationEnabled,
    required this.threshold,
    required this.isNoiseReductionEnabled,
    required this.noiseReductionLevel,
    required this.onContentPropertyUpdate,
    required this.onBinarizationToggle,
    required this.onBinarizationParameterChange,
    this.onContentPropertyUpdatePreview, // 可选参数
    this.onContentPropertyUpdateStart, // 可选参数
    this.onContentPropertyUpdateWithUndo, // 可选参数
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_binarization',
      title: l10n.binarizationProcessing,
      defaultExpanded: false,
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
              onChanged: (value) {
                onBinarizationToggle(value);
              },
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
                      Icon(Icons.contrast,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: threshold.clamp(0.0, 255.0),
                          min: 0.0,
                          max: 255.0,
                          divisions: 255,
                          label: threshold.toStringAsFixed(0),
                          activeColor: isBinarizationEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                          thumbColor: isBinarizationEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                          onChangeStart: (isBinarizationEnabled &&
                                  onContentPropertyUpdateStart != null)
                              ? (value) => onContentPropertyUpdateStart!(
                                  'binaryThreshold', threshold)
                              : null,
                          onChanged: isBinarizationEnabled
                              ? (value) {
                                  // 仅预览更新，不记录undo
                                  if (onContentPropertyUpdatePreview != null) {
                                    onContentPropertyUpdatePreview!(
                                        'binaryThreshold', value);
                                  } else {
                                    onContentPropertyUpdate(
                                        'binaryThreshold', value);
                                  }
                                }
                              : null,
                          onChangeEnd: isBinarizationEnabled
                              ? (value) {
                                  // 优先使用基于原始值的undo回调
                                  if (onContentPropertyUpdateWithUndo != null) {
                                    onContentPropertyUpdateWithUndo!(
                                        'binaryThreshold', value);
                                  } else {
                                    // 拖动结束时记录undo - 只调用一次
                                    onContentPropertyUpdate('binaryThreshold', value);
                                  }
                                }
                              : null,
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
                            color: isBinarizationEnabled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface.withValues(alpha: 0.38),
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
                  Icon(Icons.blur_on,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.noiseReductionToggle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Switch(
                    value: isNoiseReductionEnabled,
                    onChanged: isBinarizationEnabled
                        ? (value) {
                            onContentPropertyUpdate(
                                'isNoiseReductionEnabled', value);
                            // 移除重复调用：onBinarizationParameterChange 会创建额外的undo操作
                            // onBinarizationParameterChange(
                            //     'isNoiseReductionEnabled', value);
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // 降噪强度（仅在降噪开关打开时启用）
              AnimatedOpacity(
                opacity: (isBinarizationEnabled && isNoiseReductionEnabled)
                    ? 1.0
                    : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.tune,
                            size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Slider(
                            value: noiseReductionLevel.clamp(0.0, 10.0),
                            min: 0.0,
                            max: 10.0,
                            divisions: 100,
                            label: noiseReductionLevel.toStringAsFixed(1),
                            activeColor: (isBinarizationEnabled &&
                                    isNoiseReductionEnabled)
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                            thumbColor: (isBinarizationEnabled &&
                                    isNoiseReductionEnabled)
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                            onChangeStart: ((isBinarizationEnabled &&
                                        isNoiseReductionEnabled) &&
                                    onContentPropertyUpdateStart != null)
                                ? (value) => onContentPropertyUpdateStart!(
                                    'noiseReductionLevel', noiseReductionLevel)
                                : null,
                            onChanged: (isBinarizationEnabled &&
                                    isNoiseReductionEnabled)
                                ? (value) {
                                    // 仅预览更新，不记录undo
                                    if (onContentPropertyUpdatePreview !=
                                        null) {
                                      onContentPropertyUpdatePreview!(
                                          'noiseReductionLevel', value);
                                    } else {
                                      onContentPropertyUpdate(
                                          'noiseReductionLevel', value);
                                    }
                                  }
                                : null,
                            onChangeEnd: (isBinarizationEnabled &&
                                    isNoiseReductionEnabled)
                                ? (value) {
                                    // 优先使用基于原始值的undo回调
                                    if (onContentPropertyUpdateWithUndo !=
                                        null) {
                                      onContentPropertyUpdateWithUndo!(
                                          'noiseReductionLevel', value);
                                    } else {
                                      // 拖动结束时记录undo - 只调用一次
                                      onContentPropertyUpdate('noiseReductionLevel', value);
                                    }
                                  }
                                : null,
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
                              color: (isBinarizationEnabled &&
                                      isNoiseReductionEnabled)
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.38),
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
    );
  }
}

/// 图像翻转面板 (独立面板，翻转即时生效)
class ImagePropertyFlipPanel extends StatelessWidget {
  final bool flipHorizontal;
  final bool flipVertical;
  final Function(String, dynamic) onFlipChanged;

  const ImagePropertyFlipPanel({
    super.key,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.onFlipChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return M3PanelStyles.buildPersistentPanelCard(
      context: context,
      panelId: 'image_flip',
      title: l10n.flip,
      defaultExpanded: false,
      children: [
        // Information alert about flip processing order
        Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withAlpha((0.3 * 255).toInt()),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.imagePropertyPanelFlipInfo,
                  style: TextStyle(fontSize: 14, color: colorScheme.tertiary),
                ),
              ),
            ],
          ),
        ),

        // Flip options (immediately effective)
        Text(l10n.flipOptions,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),

        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 水平翻转选项
                Row(
                  children: [
                    const Icon(Icons.flip),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.flipHorizontal,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: flipHorizontal,
                      onChanged: (value) {
                        onFlipChanged('isFlippedHorizontally', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 垂直翻转选项
                Row(
                  children: [
                    Transform.rotate(
                      angle: 1.5708, // 90 degrees in radians (π/2)
                      child: const Icon(Icons.flip),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.flipVertical,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: flipVertical,
                      onChanged: (value) {
                        onFlipChanged('isFlippedVertically', value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),
      ],
    );
  }
}
