import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../../application/providers/service_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/library/library_management_provider.dart';
import '../../common/editable_number_field.dart';
import '../../common/m3_color_picker.dart';
import '../../image/cached_image.dart';
import '../../library/m3_library_picker_dialog.dart';
import '../practice_edit_controller.dart';
import 'm3_element_common_property_panel.dart';
import 'm3_layer_info_panel.dart';

/// Material 3 图像属性面板组件
class M3ImagePropertyPanel extends StatefulWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final VoidCallback onSelectImage;
  final WidgetRef ref;
  final PracticeEditController controller;

  const M3ImagePropertyPanel({
    super.key,
    required this.controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
    required this.ref,
  });

  @override
  State<M3ImagePropertyPanel> createState() => _M3ImagePropertyPanelState();
}

class _M3ImagePropertyPanelState extends State<M3ImagePropertyPanel> {
  // 内部状态
  late final ValueNotifier<bool> _isImageLoadedNotifier;
  late final AppLocalizations _l10n;
  bool _isImporting = false; // 添加导入状态标记
  BuildContext? _dialogContext; // 添加对话框context引用

  double get bottomCrop =>
      (element['content']['cropBottom'] as num?)?.toDouble() ?? 0.0;
  PracticeEditController get controller => widget.controller;
  Map<String, dynamic> get element => widget.element;
  // 图像属性访问器
  Size? get imageSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['originalWidth'] as num?;
    final height = content['originalHeight'] as num?;
    return (width != null && height != null)
        ? Size(width.toDouble(), height.toDouble())
        : null;
  }

  bool get isImageLoaded => _isImageLoadedNotifier.value;

  // 访问器
  AppLocalizations get l10n => _l10n;

  // 裁剪属性访问器
  double get leftCrop =>
      (element['content']['cropLeft'] as num?)?.toDouble() ?? 0.0;

  // 图像属性访问器
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

  WidgetRef get ref => widget.ref;

  Size? get renderSize {
    final content = element['content'] as Map<String, dynamic>;
    final width = content['renderWidth'] as num?;
    final height = content['renderHeight'] as num?;
    return (width != null && height != null)
        ? Size(width.toDouble(), height.toDouble())
        : null;
  }

  double get rightCrop =>
      (element['content']['cropRight'] as num?)?.toDouble() ?? 0.0;

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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // Basic element properties
        M3ElementCommonPropertyPanel(
          element: element,
          onElementPropertiesChanged: _handlePropertyChange,
          controller: controller,
        ),

        // Layer information
        M3LayerInfoPanel(layer: layer),

        // Geometry properties section
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
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
                            onChanged: (value) => updateProperty('x', value),
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
                            onChanged: (value) => updateProperty('y', value),
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
                            onChanged: (value) =>
                                updateProperty('width', value),
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
                                updateProperty('height', value),
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
                      onChanged: (value) => updateProperty('rotation', value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Visual properties section
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(12.0),
          // ),
          clipBehavior: Clip.antiAlias,
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
                                updateProperty('opacity', value),
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
                              updateProperty('opacity', value / 100);
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
                              initialColor: _getBackgroundColor(),
                              enableAlpha: true,
                            );
                            if (color != null) {
                              if (color == Colors.transparent) {
                                updateContentProperty(
                                    'backgroundColor', 'transparent');
                              } else {
                                final hexColor =
                                    '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                                updateContentProperty(
                                    'backgroundColor', hexColor);
                              }
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getBackgroundColor(),
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                              image: _getBackgroundColor() == Colors.transparent
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

        // Image selection section
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(l10n.imagePropertyPanelImageSelection),
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
                      onPressed: () => _selectImageFromLibrary(context),
                      label: Text(l10n.imagePropertyPanelSelectFromLibrary),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8.0),
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
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(l10n.imagePropertyPanelFitMode),
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
                              updateContentProperty('fitMode', selection.first);
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

        // Image preview section
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(l10n.imagePropertyPanelPreview),
            initiallyExpanded: true,
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
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(l10n.imagePropertyPanelImageTransform),
            initiallyExpanded: true,
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
                    Text(l10n.imagePropertyPanelCropping,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),

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

                    const SizedBox(height: 16.0),

                    // Flip buttons
                    Text(l10n.imagePropertyPanelFlip,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),

                    // Using Material 3 FilterChips for flip toggles with a Card wrapper for consistent style
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
                              label:
                                  Text(l10n.imagePropertyPanelFlipHorizontal),
                              selected: isFlippedHorizontally,
                              onSelected: (value) => updateContentProperty(
                                  'isFlippedHorizontally', value),
                              avatar: const Icon(Icons.flip),
                            ),
                            FilterChip(
                              label: Text(l10n.imagePropertyPanelFlipVertical),
                              selected: isFlippedVertically,
                              onSelected: (value) => updateContentProperty(
                                  'isFlippedVertically', value),
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
                            onChanged: (value) =>
                                updateContentProperty('rotation', value),
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
                            decimalPlaces: 0,
                            onChanged: (value) =>
                                updateContentProperty('rotation', value),
                          ),
                        ),
                      ],
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
                              updateContentProperty('rotation', 0.0);
                            }),
                            _buildRotationButton(context, '+90°', () {
                              double newRotation = contentRotation + 90;
                              while (newRotation > 180) {
                                newRotation -= 360;
                              }
                              updateContentProperty('rotation', newRotation);
                            }),
                            _buildRotationButton(context, '-90°', () {
                              double newRotation = contentRotation - 90;
                              while (newRotation < -180) {
                                newRotation += 360;
                              }
                              updateContentProperty('rotation', newRotation);
                            }),
                            _buildRotationButton(context, '180°', () {
                              double newRotation = contentRotation + 180;
                              while (newRotation > 180) {
                                newRotation -= 360;
                              }
                              updateContentProperty('rotation', newRotation);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    _isImageLoadedNotifier.dispose();
    super.dispose();
  }

  // 生命周期方法
  @override
  void initState() {
    super.initState();
    _isImageLoadedNotifier = ValueNotifier<bool>(false);
  }

  // Helper method to create Material-wrapped ExpansionTile
  Widget materialExpansionTile({
    required Widget title,
    List<Widget> children = const <Widget>[],
    bool initiallyExpanded = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: title,
        initiallyExpanded: initiallyExpanded,
        children: children,
      ),
    );
  }

  // 处理元素属性变更
  void onElementPropertiesChanged(Map<String, dynamic> updates) {
    widget.onElementPropertiesChanged(updates);
  } // 处理图片选择事件

  void onSelectImage() {
    // Only call the parent handler if we're not in the middle of an import
    // This prevents the recursive loop that causes file picker to reopen
    if (!_isImporting) {
      widget.onSelectImage();
    }
  }

  // Update content property
  void updateContentProperty(String key, dynamic value) {
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    content[key] = value;
    updateProperty('content', content);
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
      updateProperty('content', content);
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
    updateProperty('content', content);
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

    // 防止在组件已销毁后更新通知器
    if (!mounted) return;
    try {
      _isImageLoadedNotifier.value = true;
    } catch (e) {
      // 忽略可能的错误，例如通知器已被销毁
      debugPrint('无法更新图片加载状态: $e');
    }
  }

  // Update property
  void updateProperty(String key, dynamic value) {
    final updates = {key: value};
    _handlePropertyChange(updates);

    final currentImageSize = imageSize;
    final currentRenderSize = renderSize;
    if (currentImageSize != null && currentRenderSize != null) {
      updateImageState(currentImageSize, currentRenderSize);
    }
  }

  // Apply transform to the image
  void _applyTransform(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content =
        Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);
    final imageUrl = content['imageUrl'] as String? ?? '';

    if (imageUrl.isEmpty) {
      final l10n = AppLocalizations.of(context);
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
            content: Text(AppLocalizations.of(context)
                .imagePropertyPanelCroppingValueTooLarge),
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

        updateProperty('content', content);
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

          Uint8List? imageData = await _loadImageFromUrl(context, imageUrl);

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
            message += AppLocalizations.of(context)
                .imagePropertyPanelCroppingApplied(
                    originalCropLeft.toInt().toString(),
                    originalCropTop.toInt().toString(),
                    originalCropRight.toInt().toString(),
                    originalCropBottom.toInt().toString());
          }

          if (context.mounted) {
            updateProperty('content', content);
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
    final colorScheme = Theme.of(context).colorScheme;
    // Ensure max is at least 1.0 to avoid Slider min/max issues
    final safeMax = max > 0 ? max : 1.0;
    // Ensure value is in valid range
    final safeValue = value.clamp(0.0, safeMax);
    // Calculate percentage
    final percentage = max > 0 ? (safeValue / safeMax * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: safeValue,
                min: 0,
                max: safeMax,
                activeColor: colorScheme.primary,
                thumbColor: colorScheme.primary,
                label: '$percentage%',
                onChanged: (newValue) => updateCropValue(cropKey, newValue),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: label,
                value: percentage.toDouble(),
                suffix: '%',
                min: 0,
                max: 100,
                decimalPlaces: 0,
                onChanged: (newPercentage) {
                  // Convert percentage back to absolute value
                  final newValue = (newPercentage / 100) * safeMax;
                  updateCropValue(cropKey, newValue);
                },
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

    // Preview always uses "contain" fit mode
    const previewFitMode = 'contain';

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12.0),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                              // 检查当前 widget 是否仍然挂载
                              if (mounted) {
                                Future.microtask(() {
                                  // 再次检查是否仍然挂载
                                  if (mounted) {
                                    updateImageState(imageSize, renderSize);
                                  }
                                });
                              }
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
                      size: 48, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(l10n.imagePropertyPanelNoImageSelected,
                      style: TextStyle(color: colorScheme.outline)),
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
            return CachedImage(
              path: filePath,
              fit: fitMode,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Image loading error: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
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
                                : 'none'); // 调用回调
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
                // 检查当前 widget 是否仍然挂载
                if (mounted) {
                  onImageSizeAvailable(imageSize, renderSize);
                }
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
    return IconButton(
      onPressed: onPressed,
      icon: Text(label),
      tooltip: label,
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

  Future<bool> _checkImageExists(String imageUrl) async {
    if (imageUrl.isEmpty) return false;

    // Handle different URL types
    if (imageUrl.startsWith('http')) {
      try {
        final response = await http.head(Uri.parse(imageUrl));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    } else {
      // Local file path
      try {
        String filePath = imageUrl;
        if (imageUrl.startsWith('file://')) {
          filePath = imageUrl.substring(7);
        }
        final file = File(filePath);
        return await file.exists();
      } catch (e) {
        return false;
      }
    }
  }

  // Generate thumbnail for library item
  Future<Uint8List?> _generateThumbnail(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // 计算缩略图尺寸，保持宽高比
      const maxSize = 256.0;
      final ratio = image.width / image.height;
      int thumbnailWidth;
      int thumbnailHeight;

      if (ratio > 1) {
        thumbnailWidth = maxSize.toInt();
        thumbnailHeight = (maxSize / ratio).toInt();
      } else {
        thumbnailHeight = maxSize.toInt();
        thumbnailWidth = (maxSize * ratio).toInt();
      }

      // 生成缩略图
      final thumbnail = img.copyResize(
        image,
        width: thumbnailWidth,
        height: thumbnailHeight,
        interpolation: img.Interpolation.linear,
      );

      // 优化图片质量和大小
      final compressedBytes = img.encodeJpg(
        thumbnail,
        quality: 85, // 适中的压缩质量
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      return null;
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

  // 处理属性变更
  void _handlePropertyChange(Map<String, dynamic> updates) {
    widget.onElementPropertiesChanged(updates);
  }

  // Load image from URL
  Future<Uint8List?> _loadImageFromUrl(
      BuildContext context, String imageUrl) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (imageUrl.startsWith('file://')) {
        String filePath = imageUrl.substring(7);
        final file = File(filePath);

        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          debugPrint(
              l10n.imagePropertyPanelLoadError('File not found: $filePath'));
          return null;
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint(l10n.imagePropertyPanelLoadError(
              'HTTP request failed: ${response.statusCode}'));
          return null;
        }
      }
    } catch (e) {
      debugPrint(AppLocalizations.of(context)
          .imagePropertyPanelLoadError(e.toString()));
      return null;
    }
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

    updateProperty('content', content);

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

  // Implementation for selecting an image from the library
  Future<void> _selectImageFromLibrary(BuildContext context) async {
    try {
      // 使用新的图库选择对话框
      final selectedItem = await M3LibraryPickerDialog.show(context);

      // 用户从图库选择了图片
      if (selectedItem != null) {
        setState(() {
          _isImporting = true;
        });

        try {
          // 更新图层属性
          final content = Map<String, dynamic>.from(
              element['content'] as Map<String, dynamic>);

          content['imageUrl'] = 'file://${selectedItem.path}';
          content['sourceId'] = selectedItem.id;
          content['sourceType'] = 'library';
          content['libraryItem'] = selectedItem; // 保存图库项的完整引用

          // 重置变换属性
          content['cropTop'] = 0.0;
          content['cropBottom'] = 0.0;
          content['cropLeft'] = 0.0;
          content['cropRight'] = 0.0;
          content['isFlippedHorizontally'] = false;
          content['isFlippedVertically'] = false;
          content['rotation'] = 0.0;
          content['isTransformApplied'] = true; // 设置为true确保图片立即显示

          content.remove('transformedImageData');
          content.remove('transformedImageUrl');
          content.remove('transformRect');

          // 检查文件是否存在
          final file = File(selectedItem.path);
          if (!await file.exists()) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      l10n.imagePropertyPanelFileNotExist(selectedItem.path)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          // 更新元素
          updateProperty('content', content);

          // 通知UI更新
          controller.notifyListeners();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.imagePropertyPanelFileRestored),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // 通知上层图片已选择
          onSelectImage();
        } catch (e) {
          print('Error importing image from library: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导入图片失败: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isImporting = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error showing library picker: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开图库失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Select image from local
  Future<void> _selectImageFromLocal(BuildContext context) async {
    // Guard against multiple simultaneous invocations
    if (_isImporting) {
      return; // Already importing, do nothing
    }

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 弹出提示对话框，说明会自动导入图库
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.imagePropertyPanelSelectFromLocal),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.imagePropertyPanelAutoImportNotice,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (shouldProceed != true) {
      return; // User cancelled, exit method
    }

    // Set importing state right away to prevent multiple invocations
    setState(() {
      _isImporting = true;
    });

    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      // 如果没有选择文件直接返回
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
        });
        return;
      } // Get file path immediately to avoid any race conditions
      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Invalid file path');
      }
      final filePath = file.path!;

      // 检查组件是否仍然挂载
      if (!context.mounted) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      // 显示加载指示器
      _dialogContext = null; // 确保每次都重置对话框引用
      if (context.mounted) {
        // 使用非阻塞方式显示加载对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            _dialogContext = ctx;
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.imagePropertyPanelImporting),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      // 使用 LibraryImportService 导入文件
      final importService = ref.read(libraryImportServiceProvider);
      final importedItem = await importService.importFile(filePath);

      if (importedItem == null) {
        throw Exception('Failed to import image to library');
      }

      // 刷新图库
      final libraryNotifier = ref.read(libraryManagementProvider.notifier);
      await libraryNotifier.loadData();

      // 更新图片元素
      if (!context.mounted) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final content =
          Map<String, dynamic>.from(element['content'] as Map<String, dynamic>);

      content['imageUrl'] = 'file://${importedItem.path}';
      content['sourceId'] = importedItem.id;
      content['sourceType'] = 'library';
      content['libraryItem'] = importedItem; // 重置变换属性
      content['cropTop'] = 0.0;
      content['cropBottom'] = 0.0;
      content['cropLeft'] = 0.0;
      content['cropRight'] = 0.0;
      content['isFlippedHorizontally'] = false;
      content['isFlippedVertically'] = false;
      content['rotation'] = 0.0;
      content['isTransformApplied'] = true; // 设置为true确保图片立即显示
      content.remove('transformedImageData');
      content.remove('transformedImageUrl');
      content.remove(
          'transformRect'); // Update the property (outside of setState to avoid nested setState calls)
      updateProperty('content', content);

      // 通知UI更新
      controller.notifyListeners();

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagePropertyPanelImportSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagePropertyPanelImportError(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Always ensure we clean up, regardless of success or failure

      // 关闭加载指示器
      if (_dialogContext != null) {
        Navigator.of(_dialogContext!).pop();
        _dialogContext = null;
      }

      // 重置导入状态
      setState(() {
        _isImporting = false;
      });
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
  bool shouldRepaint(_TransformPreviewPainter oldDelegate) {
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
