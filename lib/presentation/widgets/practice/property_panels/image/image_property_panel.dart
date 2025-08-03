import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../practice_edit_controller.dart';
import '../m3_element_common_property_panel.dart';
import '../m3_layer_info_panel.dart';
import 'image_processing_pipeline.dart';
import 'image_property_panel_mixins.dart';
import 'image_property_panel_widgets.dart';
import 'image_selection_handler.dart';

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
        ImageProcessingPipeline {
  // 内部状态
  late final ValueNotifier<bool> _isImageLoadedNotifier;
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

    // Cropping properties - use new coordinate format directly
    final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final cropWidth = (content['cropWidth'] as num?)?.toDouble() ??
        (imageSize?.width ?? 100.0);
    final cropHeight = (content['cropHeight'] as num?)?.toDouble() ??
        (imageSize?.height ?? 100.0);

    // 记录 build 方法中读取的裁剪值
    print('=== M3ImagePropertyPanel.build 读取裁剪值 ===');
    print(
        '从content读取: cropX=$cropX, cropY=$cropY, cropWidth=$cropWidth, cropHeight=$cropHeight');
    // print('content内容: ${content.toString()}');

    // Flip properties
    final isFlippedHorizontally =
        content['isFlippedHorizontally'] as bool? ?? false;
    final isFlippedVertically =
        content['isFlippedVertically'] as bool? ?? false;

    // Content rotation property
    final contentRotation = (content['rotation'] as num?)?.toDouble() ?? 0.0;

    // Fit mode
    final fitMode = content['fitMode'] as String? ?? 'contain';
    
    // Image alignment
    final imageAlignment = content['alignment'] as String? ?? 'center';

    // Binarization properties - 确保现有元素有正确的默认值
    final isBinarizationEnabled = content['isBinarizationEnabled'] as bool? ?? false;
    final binaryThreshold = (content['binaryThreshold'] as num?)?.toDouble() ?? 128.0;
    final isNoiseReductionEnabled = content['isNoiseReductionEnabled'] as bool? ?? false;
    final noiseReductionLevel = (content['noiseReductionLevel'] as num?)?.toDouble() ?? 3.0;

    // 🔧 修复：如果现有元素缺少二值化属性，则添加默认值
    if (!content.containsKey('isBinarizationEnabled')) {
      content['isBinarizationEnabled'] = false;
      content['binaryThreshold'] = 128.0;
      content['isNoiseReductionEnabled'] = false;
      content['noiseReductionLevel'] = 3.0;
      content['binarizedImageData'] = null;
      
      // 立即更新元素数据以确保持久化
      updateProperty('content', content, createUndoOperation: false);
      
      print('🔧 已为现有图像元素添加二值化默认属性');
    }

    // 🔍 调试日志：检查二值化开关状态
    print('=== 二值化属性调试 ===');
    print('isBinarizationEnabled: $isBinarizationEnabled');
    print('content[isBinarizationEnabled]: ${content['isBinarizationEnabled']}');
    print('element id: ${element['id']}');
    print('=== 调试结束 ===');

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

        // Image alignment section
        ImagePropertyAlignmentPanel(
          alignment: imageAlignment,
          onAlignmentChanged: (alignment) => updateContentProperty('alignment', alignment),
        ),

        // Image preview section
        ImagePropertyPreviewPanel(
          imageUrl: imageUrl,
          fitMode: fitMode,
          cropX: cropX,
          cropY: cropY,
          cropWidth: cropWidth,
          cropHeight: cropHeight,
          flipHorizontal: isFlippedHorizontally,
          flipVertical: isFlippedVertically,
          contentRotation: contentRotation,
          isTransformApplied: isTransformApplied,
          imageSize: imageSize,
          renderSize: renderSize,
          onImageSizeAvailable: updateImageState,
          onCropChanged: (x, y, width, height, {bool isDragging = false}) {
            // Use new coordinate format directly
            // 在拖动过程中不创建撤销操作，只在拖动结束时创建

            // 获取当前的裁剪值用于对比
            final currentContent = element['content'] as Map<String, dynamic>;
            final currentCropX =
                (currentContent['cropX'] as num?)?.toDouble() ?? 0.0;
            final currentCropY =
                (currentContent['cropY'] as num?)?.toDouble() ?? 0.0;
            final currentCropWidth =
                (currentContent['cropWidth'] as num?)?.toDouble() ?? 0.0;
            final currentCropHeight =
                (currentContent['cropHeight'] as num?)?.toDouble() ?? 0.0;

            // 记录属性面板接收到的回调
            print('=== 图像属性面板 onCropChanged 回调 ===');
            print('接收值: x=${x.toStringAsFixed(1)}, y=${y.toStringAsFixed(1)}, '
                'width=${width.toStringAsFixed(1)}, height=${height.toStringAsFixed(1)}');
            print(
                '当前值: cropX=${currentCropX.toStringAsFixed(1)}, cropY=${currentCropY.toStringAsFixed(1)}, '
                'cropWidth=${currentCropWidth.toStringAsFixed(1)}, cropHeight=${currentCropHeight.toStringAsFixed(1)}');
            print(
                '拖拽状态: isDragging=$isDragging, createUndoOperation=${!isDragging}');
            print(
                '值变化: x=${(x - currentCropX).abs() > 0.1}, y=${(y - currentCropY).abs() > 0.1}, '
                'width=${(width - currentCropWidth).abs() > 0.1}, height=${(height - currentCropHeight).abs() > 0.1}');

            // 批量更新裁剪值，避免单独更新时的相互干扰
            print('=== 开始批量更新裁剪值 ===');
            updateAllCropValues(x, y, width, height,
                createUndoOperation: !isDragging);

            // 强制触发UI更新以确保实时反馈
            if (isDragging && mounted) {
              setState(() {
                // 触发重建以显示实时更新
              });
            }
            print('=== 批量更新完成 ===');
          },
        ),

        // Image transform section (裁剪和旋转)
        ImagePropertyTransformPanel(
          cropX: cropX,
          cropY: cropY,
          cropWidth: cropWidth,
          cropHeight: cropHeight,
          contentRotation: contentRotation,
          onRotationChanged: (value) {
            print('🔍 旋转参数变化: rotation = $value');
            // 🔧 修复：只更新属性，不立即执行处理管线
            // 用户需要点击"应用变换"按钮才会应用变换
            updateContentProperty('rotation', value, createUndoOperation: false);
          },
          onApplyTransform: () => applyTransform(context),
          onResetTransform: () => resetTransform(context),
        ),

        // Image flip section (独立的翻转面板，翻转即时生效，现在在画布渲染阶段处理)
        ImagePropertyFlipPanel(
          flipHorizontal: isFlippedHorizontally,
          flipVertical: isFlippedVertically,
          onFlipChanged: (key, value) {
            print('🔍 翻转参数变化: $key = $value');
            print('🔍 当前状态:');
            print('  - flipHorizontal: $isFlippedHorizontally');
            print('  - flipVertical: $isFlippedVertically');
            print('  - 尝试设置 $key = $value');
            
            // 🔧 大幅简化：翻转现在在画布渲染阶段处理，只需要更新属性
            print('  - 💡 翻转现在在画布渲染阶段处理，只更新元素属性');
            updateContentProperty(key, value, createUndoOperation: true);
            
            print('🔍 翻转属性更新完成，无需执行图像处理管线');
          },
        ),

        // Binarization processing section
        ImagePropertyBinarizationPanel(
          isBinarizationEnabled: isBinarizationEnabled,
          threshold: binaryThreshold,
          isNoiseReductionEnabled: isNoiseReductionEnabled,
          noiseReductionLevel: noiseReductionLevel,
          onContentPropertyUpdate: updateContentProperty,
          onBinarizationToggle: handleBinarizationToggle,
          onBinarizationParameterChange: handleBinarizationParameterChange,
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 本地化对象直接在需要时从context获取，无需缓存
  }

  @override
  void dispose() {
    _isImageLoadedNotifier.dispose();
    super.dispose();
  }

  /// 处理属性变更
  @override
  void handlePropertyChange(Map<String, dynamic> updates,
      {bool createUndoOperation = true}) {
    print('=== handlePropertyChange ===');
    print('updates: $updates');
    print('createUndoOperation: $createUndoOperation');

    // 🔧 特别检查翻转相关的更新
    if (updates.containsKey('content')) {
      final content = updates['content'] as Map<String, dynamic>;
      if (content.containsKey('isFlippedHorizontally') || content.containsKey('isFlippedVertically')) {
        print('🔍 检测到翻转状态更新:');
        print('  - content[isFlippedHorizontally]: ${content['isFlippedHorizontally']}');
        print('  - content[isFlippedVertically]: ${content['isFlippedVertically']}');
        
        final flipH = content['isFlippedHorizontally'] as bool? ?? false;
        final flipV = content['isFlippedVertically'] as bool? ?? false;
        
        if (!flipH && !flipV) {
          print('  - 🎯 即将更新状态：两个翻转都为false');
        }
      }
    }

    if (createUndoOperation) {
      print('调用 widget.onElementPropertiesChanged (创建撤销)');
      widget.onElementPropertiesChanged(updates);
    } else {
      print('调用 updateElementPropertiesWithoutUndo (不创建撤销)');
      // 直接更新UI状态，不创建撤销操作
      // 使用现有的无撤销更新方法
      final elementId = widget.element['id'];
      widget.controller.updateElementPropertiesWithoutUndo(elementId, updates);
    }

    // 🔧 修复：强制触发UI重建以确保翻转选项状态立即更新
    if (mounted) {
      setState(() {
        // 触发重建以显示最新的翻转状态
      });
    }

    print('=== handlePropertyChange 结束 ===');
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
