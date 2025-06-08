import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../practice_edit_controller.dart';
import '../m3_element_common_property_panel.dart';
import '../m3_layer_info_panel.dart';
import 'image_property_panel_mixins.dart';
import 'image_property_panel_widgets.dart';
import 'image_selection_handler.dart';
import 'image_transform_handler.dart';

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

class _M3ImagePropertyPanelState extends State<M3ImagePropertyPanel>
    with
        ImagePropertyAccessors,
        ImagePropertyUpdaters,
        ImageSelectionHandler,
        ImageTransformHandler {
  // 内部状态
  late final ValueNotifier<bool> _isImageLoadedNotifier;
  late final AppLocalizations _l10n;
  bool _isImporting = false;
  BuildContext? _dialogContext;

  @override
  PracticeEditController get controller => widget.controller;

  @override
  BuildContext? get dialogContext => _dialogContext;

  @override
  set dialogContext(BuildContext? value) {
    _dialogContext = value;
  }

  @override
  Map<String, dynamic> get element => widget.element;

  @override
  bool get isImporting => _isImporting;

  @override
  set isImporting(bool value) {
    if (mounted) {
      setState(() {
        _isImporting = value;
      });
    }
  }

  @override
  WidgetRef get ref => widget.ref;

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
          onElementPropertiesChanged: handlePropertyChange,
          controller: controller,
        ),

        // Layer information
        M3LayerInfoPanel(layer: layer),

        // Geometry properties section
        ImagePropertyGeometryPanel(
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          onPropertyUpdate: updateProperty,
        ),

        // Visual properties section
        ImagePropertyVisualPanel(
          opacity: opacity,
          backgroundColor: getBackgroundColor,
          onPropertyUpdate: updateProperty,
          onContentPropertyUpdate: updateContentProperty,
        ),

        // Image selection section
        ImagePropertySelectionPanel(
          onSelectFromLibrary: () => selectImageFromLibrary(context),
          onSelectFromLocal: () => selectImageFromLocal(context),
        ),

        // Fit mode section
        ImagePropertyFitModePanel(
          fitMode: fitMode,
          onFitModeChanged: (mode) => updateContentProperty('fitMode', mode),
        ),

        // Image preview section
        ImagePropertyPreviewPanel(
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
          imageSize: imageSize,
          renderSize: renderSize,
          onImageSizeAvailable: updateImageState,
        ),

        // Image transform section
        ImagePropertyTransformPanel(
          cropTop: cropTop,
          cropBottom: cropBottom,
          cropLeft: cropLeft,
          cropRight: cropRight,
          flipHorizontal: isFlippedHorizontally,
          flipVertical: isFlippedVertically,
          contentRotation: contentRotation,
          maxCropWidth: maxCropWidth,
          maxCropHeight: maxCropHeight,
          onCropChanged: updateCropValue,
          onFlipChanged: updateContentProperty,
          onRotationChanged: (value) =>
              updateContentProperty('rotation', value),
          onApplyTransform: () => applyTransform(context),
          onResetTransform: () => resetTransform(context),
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

  /// 处理属性变更
  @override
  void handlePropertyChange(Map<String, dynamic> updates) {
    widget.onElementPropertiesChanged(updates);
  }

  @override
  void initState() {
    super.initState();
    _isImageLoadedNotifier = ValueNotifier<bool>(false);
  }

  // 处理图片选择事件
  @override
  void onSelectImage() {
    if (!_isImporting) {
      widget.onSelectImage();
    }
  }
}
