import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../l10n/app_localizations.dart';
import '../../../../providers.dart';
import '../../common/color_palette_widget.dart';
import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';
import 'practice_property_panel_base.dart';

/// Material 3 Image Property Panel
class M3ImagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final VoidCallback onSelectImage;
  final WidgetRef ref;
  final ValueNotifier<bool> _isImageLoadedNotifier = ValueNotifier<bool>(false);

  M3ImagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
    required this.ref,
  }) : super(key: key, controller: controller);

  double get bottomCrop =>
      (element['content']['cropBottom'] as num?)?.toDouble() ?? 0.0;

  // Image size getters
  Size? get imageSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    final height = content['originalHeight'] as num?;
    if (width != null && height != null) {
      return Size(width.toDouble(), height.toDouble());
    }
    return null;
  }

  // Image loaded state
  bool get isImageLoaded => _isImageLoadedNotifier.value;

  double get leftCrop =>
      (element['content']['cropLeft'] as num?)?.toDouble() ?? 0.0;
  double get maxCropHeight {
    final renderSize = this.renderSize;
    if (renderSize != null) {
      return renderSize.height / 2;
    }

    final imageSize = this.imageSize;
    if (imageSize != null) {
      return imageSize.height / 2;
    }

    final content = element['content'] as Map<String, dynamic>;
    final height = content['originalHeight'] as num?;
    if (height != null) {
      return height.toDouble() / 2;
    }

    return 0.0;
  }

  // Maximum crop values
  double get maxCropWidth {
    final renderSize = this.renderSize;
    if (renderSize != null) {
      return renderSize.width / 2;
    }

    final imageSize = this.imageSize;
    if (imageSize != null) {
      return imageSize.width / 2;
    }

    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    if (width != null) {
      return width.toDouble() / 2;
    }

    return 0.0;
  }

  Size? get renderSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['renderWidth'] as num?;
    final height = content['renderHeight'] as num?;
    if (width != null && height != null) {
      return Size(width.toDouble(), height.toDouble());
    }
    return null;
  }

  double get rightCrop =>
      (element['content']['cropRight'] as num?)?.toDouble() ?? 0.0;

  // Cropping getters
  double get topCrop =>
      (element['content']['cropTop'] as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Basic element properties
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = element['layerId'] as String?;

    // Get layer info
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = controller.state.getLayerById(layerId);
    }

    // Image specific properties
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';

    // Cropping properties
    final cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    final cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    final cropLeft = (content['cropLeft'] as num?)?.toDouble() ?? 0.0;
    final cropRight = (content['cropRight'] as num?)?.toDouble() ?? 0.0;

    // Flip properties
    final isFlippedHorizontally =
        content['isFlippedHorizontally'] as bool? ?? false;
    final isFlippedVertically =
        content['isFlippedVertically'] as bool? ?? false;

    // Content rotation property
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // Fit mode
    final fitMode = content['fitMode'] as String? ?? 'contain';

    // Transform applied state
    final isTransformApplied = content['isTransformApplied'] as bool? ?? false;

    return ListView(
      children: [
        // Basic element properties
        ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: onElementPropertiesChanged,
          controller: controller,
        ),

        // Layer information
        LayerInfoPanel(layer: layer),

        // Geometry properties section
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(l10n.imagePropertyPanelGeometry),
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
                        color: colorScheme.primaryContainer.withOpacity(0.3),
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

                    // Position
                    Text(l10n.position, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: EditableNumberField(
                            label: 'X',
                            value: x,
                            suffix: 'px',
                            min: 0,
                            max: 10000,
                            onChanged: (value) => _updateProperty('x', value),
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
                            onChanged: (value) => _updateProperty('y', value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dimensions
                    Text(l10n.dimensions, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: EditableNumberField(
                            label: l10n.width,
                            value: width,
                            suffix: 'px',
                            min: 10,
                            max: 10000,
                            onChanged: (value) =>
                                _updateProperty('width', value),
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
                            onChanged: (value) =>
                                _updateProperty('height', value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rotation
                    Text(l10n.rotation, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    EditableNumberField(
                      label: l10n.rotation,
                      value: rotation,
                      suffix: '°',
                      min: -360,
                      max: 360,
                      decimalPlaces: 1,
                      onChanged: (value) => _updateProperty('rotation', value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Visual properties section
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(l10n.imagePropertyPanelVisual),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opacity
                    Text('${l10n.opacity}:', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: opacity,
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            label: '${(opacity * 100).toStringAsFixed(0)}%',
                            onChanged: (value) =>
                                _updateProperty('opacity', value),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text('${(opacity * 100).toStringAsFixed(0)}%'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Background color
                    Text('${l10n.backgroundColor}:',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ColorPaletteWidget(
                      initialColor: _getBackgroundColor(),
                      labelText: l10n.backgroundColor,
                      onColorChanged: (color) {
                        final hexColor =
                            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                        _updateContentProperty('backgroundColor', hexColor);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Image selection section
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(l10n.imagePropertyPanelImageSelection),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () => _selectImageFromLocal(context),
                      label: Text(l10n.imagePropertyPanelSelectFromLocal),
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

        // Fit mode section
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(l10n.imagePropertyPanelFitMode),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'contain',
                          label: Text(l10n.imagePropertyPanelFitContain),
                          icon: const Icon(Icons.fit_screen),
                        ),
                        ButtonSegment<String>(
                          value: 'cover',
                          label: Text(l10n.imagePropertyPanelFitCover),
                          icon: const Icon(Icons.crop),
                        ),
                        ButtonSegment<String>(
                          value: 'fill',
                          label: Text(l10n.imagePropertyPanelFitFill),
                          icon: const Icon(Icons.aspect_ratio),
                        ),
                        ButtonSegment<String>(
                          value: 'none',
                          label: Text(l10n.imagePropertyPanelFitOriginal),
                          icon: const Icon(Icons.image),
                        ),
                      ],
                      selected: {fitMode},
                      onSelectionChanged: (Set<String> selection) {
                        if (selection.isNotEmpty) {
                          _updateContentProperty('fitMode', selection.first);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Image preview section
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(l10n.imagePropertyPanelPreview),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        l10n.imagePropertyPanelPreviewNotice,
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.tertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildImagePreviewWithTransformBox(
                      context: context,
                      imageUrl: imageUrl,
                      fitMode: fitMode,
                      cropTop: cropTop,
                      cropBottom: cropBottom,
                      cropLeft: cropLeft,
                      cropRight: cropRight,
                      flipHorizontal: isFlippedHorizontally,
                      flipVertical: isFlippedVertically,
                      contentRotation: contentRotation,
                      isTransformApplied: isTransformApplied,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Image transform section
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(l10n.imagePropertyPanelImageTransform),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning message
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: colorScheme.tertiary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.imagePropertyPanelTransformWarning,
                              style: TextStyle(
                                  fontSize: 14, color: colorScheme.tertiary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Crop settings
                    Text(l10n.imagePropertyPanelFlip,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 8),

                    // Top crop slider
                    _buildCropSlider(
                      context: context,
                      label: l10n.imagePropertyPanelCropTop,
                      cropKey: 'cropTop',
                      value: cropTop,
                      max: maxCropHeight,
                    ),

                    // Bottom crop slider
                    _buildCropSlider(
                      context: context,
                      label: l10n.imagePropertyPanelCropBottom,
                      cropKey: 'cropBottom',
                      value: cropBottom,
                      max: maxCropHeight,
                    ),

                    // Left crop slider
                    _buildCropSlider(
                      context: context,
                      label: l10n.imagePropertyPanelCropLeft,
                      cropKey: 'cropLeft',
                      value: cropLeft,
                      max: maxCropWidth,
                    ),

                    // Right crop slider
                    _buildCropSlider(
                      context: context,
                      label: l10n.imagePropertyPanelCropRight,
                      cropKey: 'cropRight',
                      value: cropRight,
                      max: maxCropWidth,
                    ),

                    const SizedBox(height: 16),

                    // Flip buttons
                    Text(l10n.imagePropertyPanelFlip,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 8),

                    // Using Material 3 FilterChips for flip toggles
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: Text(l10n.imagePropertyPanelFlipHorizontal),
                          selected: isFlippedHorizontally,
                          onSelected: (value) => _updateContentProperty(
                              'isFlippedHorizontally', value),
                          avatar: const Icon(Icons.flip),
                        ),
                        FilterChip(
                          label: Text(l10n.imagePropertyPanelFlipVertical),
                          selected: isFlippedVertically,
                          onSelected: (value) => _updateContentProperty(
                              'isFlippedVertically', value),
                          avatar: const Icon(Icons.flip),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Rotation
                    Text(l10n.rotation,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: contentRotation.clamp(-180.0, 180.0),
                            min: -180.0,
                            max: 180.0,
                            divisions: 360,
                            label: '${contentRotation.toStringAsFixed(0)}°',
                            onChanged: (value) =>
                                _updateContentProperty('rotation', value),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text('${contentRotation.toStringAsFixed(0)}°'),
                        ),
                      ],
                    ),

                    // Quick rotation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRotationButton(context, '0°', () {
                          _updateContentProperty('rotation', 0.0);
                        }),
                        const SizedBox(width: 8),
                        _buildRotationButton(context, '+90°', () {
                          double newRotation = contentRotation + 90;
                          while (newRotation > 180) {
                            newRotation -= 360;
                          }
                          _updateContentProperty('rotation', newRotation);
                        }),
                        const SizedBox(width: 8),
                        _buildRotationButton(context, '-90°', () {
                          double newRotation = contentRotation - 90;
                          while (newRotation < -180) {
                            newRotation += 360;
                          }
                          _updateContentProperty('rotation', newRotation);
                        }),
                        const SizedBox(width: 8),
                        _buildRotationButton(context, '180°', () {
                          double newRotation = contentRotation + 180;
                          while (newRotation > 180) {
                            newRotation -= 360;
                          }
                          _updateContentProperty('rotation', newRotation);
                        }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Apply and Reset buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check),
                            onPressed: () => _applyTransform(context),
                            label: Text(l10n.imagePropertyPanelApplyTransform),
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
                            onPressed: () => _resetTransform(context),
                            label: Text(l10n.imagePropertyPanelResetTransform),
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
      ],
    );
  }

  // Update crop value
  void updateCropValue(String key, double value) {
    Future.microtask(() {
      final imageSize = this.imageSize;
      final renderSize = this.renderSize;

      if (imageSize == null || renderSize == null) {
        debugPrint('Warning: Image size information unavailable');
        return;
      }

      final content =
          Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

      double maxValue;
      if (key == 'cropTop' || key == 'cropBottom') {
        maxValue = renderSize.height / 2;
      } else {
        maxValue = renderSize.width / 2;
      }

      final safeValue = value.clamp(0.0, maxValue);
      content[key] = safeValue;
      _updateProperty('content', content);
    });
  }

  // Update image size information
  void updateImageSizeInfo(Size imageSize, Size renderSize) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content['originalWidth'] = imageSize.width;
    content['originalHeight'] = imageSize.height;
    content['renderWidth'] = renderSize.width;
    content['renderHeight'] = renderSize.height;
    _updateProperty('content', content);
  }

  // Update image state
  void updateImageState(Size? imageSize, Size? renderSize) {
    if (imageSize == null || renderSize == null) {
      return;
    }

    final currentImageSize = this.imageSize;
    final currentRenderSize = this.renderSize;

    if (currentImageSize != null && currentRenderSize != null) {
      if (currentImageSize == imageSize && currentRenderSize == renderSize) {
        return;
      }
    }

    updateImageSizeInfo(imageSize, renderSize);
    _isImageLoadedNotifier.value = true;
  }

  // Apply transform to the image
  void _applyTransform(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    final imageUrl = content['imageUrl'] as String? ?? '';

    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.imagePropertyPanelCannotApplyNoImage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final imageSize = this.imageSize;
    final renderSize = this.renderSize;

    if (imageSize != null && renderSize != null) {
      final maxCropWidth = renderSize.width / 2;
      final maxCropHeight = renderSize.height / 2;

      final safeCropTop =
          (content['cropTop'] as num?)?.toDouble().clamp(0.0, maxCropHeight) ??
              0.0;
      final safeCropBottom = (content['cropBottom'] as num?)
              ?.toDouble()
              .clamp(0.0, maxCropHeight) ??
          0.0;
      final safeCropLeft =
          (content['cropLeft'] as num?)?.toDouble().clamp(0.0, maxCropWidth) ??
              0.0;
      final safeCropRight =
          (content['cropRight'] as num?)?.toDouble().clamp(0.0, maxCropWidth) ??
              0.0;

      final flipHorizontal = content['isFlippedHorizontally'] as bool? ?? false;
      final flipVertical = content['isFlippedVertically'] as bool? ?? false;
      final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

      final originalCropLeft = safeCropLeft;
      final originalCropTop = safeCropTop;
      final originalCropRight = safeCropRight;
      final originalCropBottom = safeCropBottom;

      content['transformRect'] = {
        'x': safeCropLeft,
        'y': safeCropTop,
        'width': renderSize.width - safeCropLeft - safeCropRight,
        'height': renderSize.height - safeCropTop - safeCropBottom,
        'originalWidth': renderSize.width,
        'originalHeight': renderSize.height,
      };

      content['cropTop'] = originalCropTop;
      content['cropBottom'] = originalCropBottom;
      content['cropLeft'] = originalCropLeft;
      content['cropRight'] = originalCropRight;

      final bool hasOtherTransforms =
          flipHorizontal || flipVertical || contentRotation != 0.0;
      final bool invalidCropping =
          safeCropLeft + safeCropRight >= imageSize.width ||
              safeCropTop + safeCropBottom >= imageSize.height;

      if (invalidCropping) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagePropertyPanelCroppingValueTooLarge),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bool noCropping = safeCropLeft == 0 &&
          safeCropRight == 0 &&
          safeCropTop == 0 &&
          safeCropBottom == 0;
      final bool isInitialState = noCropping && !hasOtherTransforms;

      if (isInitialState) {
        content['isTransformApplied'] = true;
        content.remove('transformedImageData');
        content.remove('transformedImageUrl');

        content['transformRect'] = {
          'x': 0,
          'y': 0,
          'width': renderSize.width,
          'height': renderSize.height,
          'originalWidth': renderSize.width,
          'originalHeight': renderSize.height,
        };

        _updateProperty('content', content);
        controller.notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagePropertyPanelTransformApplied +
                l10n.imagePropertyPanelNoCropping),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Future(() async {
        try {
          final widthRatio = imageSize.width / renderSize.width;
          final heightRatio = imageSize.height / renderSize.height;

          final cropAreaLeft = safeCropLeft * widthRatio;
          final cropAreaTop = safeCropTop * heightRatio;
          final cropAreaRight = safeCropRight * widthRatio;
          final cropAreaBottom = safeCropBottom * heightRatio;

          var left = cropAreaLeft;
          var top = cropAreaTop;
          var right = imageSize.width - cropAreaRight;
          var bottom = imageSize.height - cropAreaBottom;

          final minWidth = imageSize.width * 0.01;
          final minHeight = imageSize.height * 0.01;

          if (right - left < minWidth) {
            right = left + minWidth;
            if (right > imageSize.width) {
              right = imageSize.width;
              left = right - minWidth;
            }
          }

          if (bottom - top < minHeight) {
            bottom = top + minHeight;
            if (bottom > imageSize.height) {
              bottom = imageSize.height;
              top = bottom - minHeight;
            }
          }

          if (right <= left) right = left + 1;
          if (bottom <= top) bottom = top + 1;

          final cropRect = Rect.fromLTRB(left, top, right, bottom);

          Uint8List? imageData = await _loadImageFromUrl(imageUrl);

          if (imageData == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.imagePropertyPanelLoadError('{error}')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final image = img.decodeImage(imageData);
          if (image == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.imagePropertyPanelLoadError('{error}')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final croppedImage =
              ref.read(imageProcessorProvider).rotateAndCropImage(
                    image,
                    cropRect,
                    contentRotation,
                    flipHorizontal: flipHorizontal,
                    flipVertical: flipVertical,
                  );

          final transformedImageData =
              Uint8List.fromList(img.encodePng(croppedImage));
          content['transformedImageData'] = transformedImageData;
          content['isTransformApplied'] = true;

          String message = l10n.imagePropertyPanelTransformApplied;
          if (noCropping) {
            message += l10n.imagePropertyPanelNoCropping;
          } else {
            message += l10n.imagePropertyPanelCroppingApplied(
                originalCropLeft.toInt().toString(),
                originalCropTop.toInt().toString(),
                originalCropRight.toInt().toString(),
                originalCropBottom.toInt().toString());
          }

          if (context.mounted) {
            _updateProperty('content', content);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error applying transform: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(l10n.imagePropertyPanelTransformError(e.toString())),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.imagePropertyPanelCannotApplyNoSizeInfo),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper method to build crop slider
  Widget _buildCropSlider({
    required BuildContext context,
    required String label,
    required String cropKey,
    required double value,
    required double max,
  }) {
    final theme = Theme.of(context);
    // Ensure max is at least 1.0 to avoid Slider min/max issues
    final safeMax = max > 0 ? max : 1.0;
    // Ensure value is in valid range
    final safeValue = value.clamp(0.0, safeMax);
    // Calculate percentage
    final percentage = max > 0 ? (safeValue / safeMax * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: safeValue,
                min: 0,
                max: safeMax,
                onChanged: (newValue) => updateCropValue(cropKey, newValue),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text('$percentage%', textAlign: TextAlign.end),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to build image preview with transform box
  Widget _buildImagePreviewWithTransformBox({
    required BuildContext context,
    required String imageUrl,
    required String fitMode,
    required double cropTop,
    required double cropBottom,
    required double cropLeft,
    required double cropRight,
    required bool flipHorizontal,
    required bool flipVertical,
    required double contentRotation,
    required bool isTransformApplied,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Preview always uses "contain" fit mode
    const previewFitMode = 'contain';

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8.0),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      child: imageUrl.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Original image display
                    Positioned.fill(
                      child: ClipRect(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..scale(
                              flipHorizontal ? -1.0 : 1.0,
                              flipVertical ? -1.0 : 1.0,
                            ),
                          alignment: Alignment.center,
                          child: _buildImageWithSizeListener(
                            context: context,
                            imageUrl: imageUrl,
                            fitMode: _getFitMode(previewFitMode),
                            onImageSizeAvailable:
                                (Size imageSize, Size renderSize) {
                              // Use Future.microtask to update state after the build
                              Future.microtask(() {
                                updateImageState(imageSize, renderSize);
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Transform preview rectangle
                    _buildTransformPreviewRect(
                      context: context,
                      containerConstraints: constraints,
                      cropTop: cropTop,
                      cropBottom: cropBottom,
                      cropLeft: cropLeft,
                      cropRight: cropRight,
                      contentRotation: contentRotation,
                      flipHorizontal: flipHorizontal,
                      flipVertical: flipVertical,
                      fitMode: previewFitMode,
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
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(l10n.imagePropertyPanelNoImageSelected,
                      style: TextStyle(color: theme.colorScheme.outline)),
                ],
              ),
            ),
    );
  }

  // Helper method to build image with size listener
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
                  l10n.imagePropertyPanelFileNotExist(filePath),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final imageProvider = FileImage(file);

            // Preload image and get its size
            final imageStream = imageProvider.resolve(ImageConfiguration(
              size: constraints.biggest,
            ));

            imageStream.addListener(ImageStreamListener(
              (ImageInfo info, bool _) {
                final imageSize = Size(
                  info.image.width.toDouble(),
                  info.image.height.toDouble(),
                );

                // Calculate render size
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

                // Call the callback after the frame is built
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onImageSizeAvailable(imageSize, renderSize);
                });
              },
              onError: (exception, stackTrace) {
                debugPrint('Image loading error: $exception');
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
                        l10n.imagePropertyPanelLoadError(error
                            .toString()
                            .substring(
                                0, math.min(error.toString().length, 50))),
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
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                l10n.imagePropertyPanelProcessingPathError(e.toString()),
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
                onImageSizeAvailable(imageSize, renderSize);
              });
            },
            onError: (exception, stackTrace) {
              debugPrint('Image loading error: $exception');
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
                      l10n.imagePropertyPanelLoadError(error
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

  // Helper method to build rotation button
  Widget _buildRotationButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 36),
      ),
      child: Text(label),
    );
  }

  // Helper method to build transform preview rectangle
  Widget _buildTransformPreviewRect({
    required BuildContext context,
    required BoxConstraints containerConstraints,
    required double cropTop,
    required double cropBottom,
    required double cropLeft,
    required double cropRight,
    required double contentRotation,
    required bool flipHorizontal,
    required bool flipVertical,
    required String fitMode,
  }) {
    final currentImageSize = imageSize;
    final currentRenderSize = renderSize;

    if (currentImageSize == null || currentRenderSize == null) {
      return const SizedBox();
    }

    return SizedBox(
      width: containerConstraints.maxWidth,
      height: containerConstraints.maxHeight,
      child: CustomPaint(
        painter: _TransformPreviewPainter(
          context: context,
          imageSize: currentImageSize,
          renderSize: currentRenderSize,
          cropTop: cropTop,
          cropBottom: cropBottom,
          cropLeft: cropLeft,
          cropRight: cropRight,
          flipHorizontal: flipHorizontal,
          flipVertical: flipVertical,
          contentRotation: contentRotation,
          isTransformApplied:
              element['content']['isTransformApplied'] as bool? ?? false,
        ),
      ),
    );
  }

  // Calculate render size based on fit mode
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

  // Get background color from element content
  Color _getBackgroundColor() {
    final content = element['content'] as Map<String, dynamic>;
    final backgroundColor = content['backgroundColor'] as String?;

    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      try {
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;
        return Color(int.parse(fullColorStr, radix: 16));
      } catch (e) {
        debugPrint('Failed to parse background color: $e');
      }
    }
    return Colors.transparent;
  }

  // Convert string fit mode to BoxFit
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

  // Load image from URL
  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        String filePath = imageUrl.substring(7);
        final file = File(filePath);

        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          debugPrint('File does not exist: $filePath');
          return null;
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint('HTTP request failed: ${response.statusCode}');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Failed to load image data: $e');
    }
    return null;
  }

  // Reset transform
  void _resetTransform(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

    content['cropTop'] = 0.0;
    content['cropBottom'] = 0.0;
    content['cropLeft'] = 0.0;
    content['cropRight'] = 0.0;
    content['isFlippedHorizontally'] = false;
    content['isFlippedVertically'] = false;
    content['rotation'] = 0.0;
    content['isTransformApplied'] = false;

    content.remove('transformedImageData');
    content.remove('transformedImageUrl');
    content.remove('transformRect');

    _updateProperty('content', content);

    if (imageSize != null && renderSize != null) {
      updateImageState(imageSize, renderSize);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.imagePropertyPanelResetSuccess),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Select image from local
  Future<void> _selectImageFromLocal(BuildContext context) async {
    onSelectImage();
  }

  // Update content property
  void _updateContentProperty(String key, dynamic value) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content[key] = value;
    _updateProperty('content', content);
  }

  // Update property
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);

    final currentImageSize = imageSize;
    final currentRenderSize = renderSize;
    if (currentImageSize != null && currentRenderSize != null) {
      updateImageState(currentImageSize, currentRenderSize);
    }
  }
}

// Transform preview painter
class _TransformPreviewPainter extends CustomPainter {
  final BuildContext context;
  final Size imageSize;
  final Size renderSize;
  final double cropTop;
  final double cropBottom;
  final double cropLeft;
  final double cropRight;
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final bool isTransformApplied;

  const _TransformPreviewPainter({
    required this.context,
    required this.imageSize,
    required this.renderSize,
    required this.cropTop,
    required this.cropBottom,
    required this.cropLeft,
    required this.cropRight,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.contentRotation,
    required this.isTransformApplied,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Draw canvas border
    final canvasBorderPaint = Paint()
      ..color = colorScheme.primary.withAlpha(100)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(canvasRect, canvasBorderPaint);

    // Calculate scale for image in canvas
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final scaledImageWidth = imageSize.width * scale;
    final scaledImageHeight = imageSize.height * scale;

    final offsetX = (size.width - scaledImageWidth) / 2;
    final offsetY = (size.height - scaledImageHeight) / 2;

    final actualImageRect =
        Rect.fromLTWH(offsetX, offsetY, scaledImageWidth, scaledImageHeight);

    // Draw image area border
    final imageBorderPaint = Paint()
      ..color = colorScheme.tertiary.withAlpha(150)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(actualImageRect, imageBorderPaint);

    // Calculate crop area
    final displayWidth = actualImageRect.width;
    final displayHeight = actualImageRect.height;

    final uiToDisplayScaleX = displayWidth / renderSize.width;
    final uiToDisplayScaleY = displayHeight / renderSize.height;

    final cropRectLeft = actualImageRect.left + (cropLeft * uiToDisplayScaleX);
    final cropRectTop = actualImageRect.top + (cropTop * uiToDisplayScaleY);
    final cropRectRight =
        actualImageRect.right - (cropRight * uiToDisplayScaleX);
    final cropRectBottom =
        actualImageRect.bottom - (cropBottom * uiToDisplayScaleY);

    final cropRect =
        Rect.fromLTRB(cropRectLeft, cropRectTop, cropRectRight, cropRectBottom);

    // Only draw crop area if it's valid
    if (cropRect.width > 0 && cropRect.height > 0) {
      // Get center of crop area (for rotation)
      final centerX = cropRect.center.dx;
      final centerY = cropRect.center.dy;

      // Create path for rotated crop area
      Path rotatedCropPath = Path();

      if (contentRotation != 0) {
        final rotationRadians = contentRotation * (math.pi / 180.0);

        final matrix4 = Matrix4.identity()
          ..translate(centerX, centerY)
          ..rotateZ(rotationRadians)
          ..translate(-centerX, -centerY);

        rotatedCropPath.addRect(cropRect);
        rotatedCropPath = rotatedCropPath.transform(matrix4.storage);
      } else {
        rotatedCropPath.addRect(cropRect);
      }

      // Draw mask
      final maskPaint = Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.fill;

      final maskPath = Path()..addRect(actualImageRect);
      maskPath.addPath(rotatedCropPath, Offset.zero);
      maskPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(maskPath, maskPaint);

      // Draw crop area border and markers
      canvas.save();

      if (contentRotation != 0) {
        canvas.translate(centerX, centerY);
        canvas.rotate(contentRotation * (math.pi / 180.0));
        canvas.translate(-centerX, -centerY);
      }

      // Draw crop border
      final borderPaint = Paint()
        ..color = colorScheme.error
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(cropRect, borderPaint);

      // Draw corner markers
      const cornerSize = 8.0;
      final cornerPaint = Paint()
        ..color = colorScheme.error
        ..style = PaintingStyle.fill;

      // Top-left corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.left - cornerSize / 2,
              cropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Top-right corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.right - cornerSize / 2,
              cropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Bottom-left corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.left - cornerSize / 2,
              cropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Bottom-right corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.right - cornerSize / 2,
              cropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TransformPreviewPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize ||
        renderSize != oldDelegate.renderSize ||
        cropTop != oldDelegate.cropTop ||
        cropBottom != oldDelegate.cropBottom ||
        cropLeft != oldDelegate.cropLeft ||
        cropRight != oldDelegate.cropRight ||
        flipHorizontal != oldDelegate.flipHorizontal ||
        flipVertical != oldDelegate.flipVertical ||
        contentRotation != oldDelegate.contentRotation ||
        isTransformApplied != oldDelegate.isTransformApplied ||
        context != oldDelegate.context;
  }
}
