import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../infrastructure/logging/logger.dart';
import '../../../../../utils/image_path_converter.dart';
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

  // 滑块拖动时的原始值保存
  double? _originalOpacity;
  double? _originalBinaryThreshold;
  double? _originalNoiseReductionLevel;

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
    return FutureBuilder<String>(
      future: _getAbsoluteImagePath(),
      builder: (context, snapshot) {
        final absoluteImageUrl = snapshot.data ?? '';
        return _buildPanelContent(context, absoluteImageUrl);
      },
    );
  }

  /// 获取绝对图像路径
  Future<String> _getAbsoluteImagePath() async {
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';
    
    if (imageUrl.isEmpty) {
      return '';
    }

    // 如果是相对路径，转换为绝对路径
    if (ImagePathConverter.isRelativePath(imageUrl)) {
      try {
        return await ImagePathConverter.toAbsolutePath(imageUrl);
      } catch (e) {
        AppLogger.warning('路径转换失败，使用原路径', 
          tag: 'ImagePropertyPanel', 
          data: {'path': imageUrl, 'error': e.toString()});
        return imageUrl;
      }
    }
    
    return imageUrl;
  }

  /// 构建面板内容
  Widget _buildPanelContent(BuildContext context, String absoluteImageUrl) {
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

    // Cropping properties - use new coordinate format directly
    final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
    final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
    final cropWidth = (content['cropWidth'] as num?)?.toDouble() ??
        (imageSize?.width ?? 100.0);
    final cropHeight = (content['cropHeight'] as num?)?.toDouble() ??
        (imageSize?.height ?? 100.0);

    // 记录 build 方法中读取的裁剪值
    AppLogger.debug(
      'Reading crop values in build method',
      tag: 'ImagePropertyPanel',
      data: {
        'cropX': cropX,
        'cropY': cropY,
        'cropWidth': cropWidth,
        'cropHeight': cropHeight,
      },
    );
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
    final isBinarizationEnabled =
        content['isBinarizationEnabled'] as bool? ?? false;
    final binaryThreshold =
        (content['binaryThreshold'] as num?)?.toDouble() ?? 128.0;
    final isNoiseReductionEnabled =
        content['isNoiseReductionEnabled'] as bool? ?? false;
    final noiseReductionLevel =
        (content['noiseReductionLevel'] as num?)?.toDouble() ?? 3.0;

    // 🔧 修复：如果现有元素缺少二值化属性，则静默添加默认值（不创建撤销操作）
    if (!content.containsKey('isBinarizationEnabled')) {
      content['isBinarizationEnabled'] = false;
      content['binaryThreshold'] = 128.0;
      content['isNoiseReductionEnabled'] = false;
      content['noiseReductionLevel'] = 3.0;
      content['binarizedImageData'] = null;

      AppLogger.debug(
        '🔧 静默为现有图像元素添加二值化默认属性（不创建撤销操作）',
        tag: 'ImagePropertyPanel',
      );

      // 使用控制器直接更新元素属性，不创建撤销操作
      final elementId = widget.element['id'];
      widget.controller.updateElementPropertiesWithoutUndo(elementId, {'content': content});
    }

    // 🔍 调试日志：检查二值化开关状态
    AppLogger.debug(
      '二值化属性调试',
      tag: 'ImagePropertyPanel',
      data: {
        'isBinarizationEnabled': isBinarizationEnabled,
        'contentBinarizationEnabled': content['isBinarizationEnabled'],
        'elementId': element['id'],
      },
    );

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
          onPropertyUpdatePreview: _updatePropertyPreview,
          onPropertyUpdateStart: _updatePropertyStart,
          onPropertyUpdateWithUndo: _updatePropertyWithUndo,
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
          onAlignmentChanged: (alignment) =>
              updateContentProperty('alignment', alignment),
        ),

        // Image preview section
        ImagePropertyPreviewPanel(
          imageUrl: absoluteImageUrl,
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
            AppLogger.debug(
              '图像属性面板 onCropChanged 回调',
              tag: 'ImagePropertyPanel',
              data: {
                'received': {
                  'x': x.toStringAsFixed(1),
                  'y': y.toStringAsFixed(1),
                  'width': width.toStringAsFixed(1),
                  'height': height.toStringAsFixed(1),
                },
                'current': {
                  'cropX': currentCropX.toStringAsFixed(1),
                  'cropY': currentCropY.toStringAsFixed(1),
                  'cropWidth': currentCropWidth.toStringAsFixed(1),
                  'cropHeight': currentCropHeight.toStringAsFixed(1),
                },
                'dragState': {
                  'isDragging': isDragging,
                  'createUndoOperation': !isDragging,
                },
                'valueChanges': {
                  'xChanged': (x - currentCropX).abs() > 0.1,
                  'yChanged': (y - currentCropY).abs() > 0.1,
                  'widthChanged': (width - currentCropWidth).abs() > 0.1,
                  'heightChanged': (height - currentCropHeight).abs() > 0.1,
                },
              },
            );

            // 批量更新裁剪值，避免单独更新时的相互干扰
            AppLogger.debug('开始批量更新裁剪值', tag: 'ImagePropertyPanel');
            updateAllCropValues(x, y, width, height,
                createUndoOperation: !isDragging);

            // 强制触发UI更新以确保实时反馈
            if (isDragging && mounted) {
              setState(() {
                // 触发重建以显示实时更新
              });
            }
            AppLogger.debug('批量更新完成', tag: 'ImagePropertyPanel');
          },
        ),

        // Image transform section (裁剪)
        ImagePropertyTransformPanel(
          cropX: cropX,
          cropY: cropY,
          cropWidth: cropWidth,
          cropHeight: cropHeight,
          onApplyTransform: () => applyTransform(context),
          onResetTransform: () => resetTransform(context),
        ),

        // Image flip section (独立的翻转面板，翻转即时生效，现在在画布渲染阶段处理)
        ImagePropertyFlipPanel(
          flipHorizontal: isFlippedHorizontally,
          flipVertical: isFlippedVertically,
          onFlipChanged: (key, value) {
            AppLogger.debug(
              '🔍 翻转参数变化',
              tag: 'ImagePropertyPanel',
              data: {
                'key': key,
                'value': value,
                'currentState': {
                  'flipHorizontal': isFlippedHorizontally,
                  'flipVertical': isFlippedVertically,
                },
              },
            );

            // 🔧 大幅简化：翻转现在在画布渲染阶段处理，只需要更新属性
            AppLogger.debug(
              '💡 翻转现在在画布渲染阶段处理，只更新元素属性',
              tag: 'ImagePropertyPanel',
            );
            updateContentProperty(key, value, createUndoOperation: true);

            AppLogger.debug(
              '🔍 翻转属性更新完成，无需执行图像处理管线',
              tag: 'ImagePropertyPanel',
            );
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
          onContentPropertyUpdatePreview: _updateContentPropertyPreview,
          onContentPropertyUpdateStart: _updateContentPropertyStart,
          onContentPropertyUpdateWithUndo: _updateContentPropertyWithUndo,
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
    AppLogger.debug(
      'handlePropertyChange called',
      tag: 'ImagePropertyPanel',
      data: {
        'createUndoOperation': createUndoOperation,
      },
    );

    // 🔧 特别检查翻转相关的更新
    if (updates.containsKey('content')) {
      final content = updates['content'] as Map<String, dynamic>;
      if (content.containsKey('isFlippedHorizontally') ||
          content.containsKey('isFlippedVertically')) {
        AppLogger.debug(
          '🔍 检测到翻转状态更新',
          tag: 'ImagePropertyPanel',
          data: {
            'contentFlipHorizontal': content['isFlippedHorizontally'],
            'contentFlipVertical': content['isFlippedVertically'],
          },
        );

        final flipH = content['isFlippedHorizontally'] as bool? ?? false;
        final flipV = content['isFlippedVertically'] as bool? ?? false;

        if (!flipH && !flipV) {
          AppLogger.debug(
            '🎯 即将更新状态：两个翻转都为false',
            tag: 'ImagePropertyPanel',
          );
        }
      }
    }

    if (createUndoOperation) {
      AppLogger.debug(
        '调用 widget.onElementPropertiesChanged (创建撤销)',
        tag: 'ImagePropertyPanel',
      );
      widget.onElementPropertiesChanged(updates);
    } else {
      AppLogger.debug(
        '调用 updateElementPropertiesWithoutUndo (不创建撤销)',
        tag: 'ImagePropertyPanel',
      );
      // 直接更新UI状态，不创建撤销操作
      // 使用现有的无撤销更新方法
      final elementId = widget.element['id'];
      widget.controller.updateElementPropertiesWithoutUndo(elementId, updates);
    }

    // 🔧 修复：延迟UI重建到构建完成后，避免setState during build错误
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // 触发重建以显示最新的翻转状态
        });
      }
    });

    AppLogger.debug('handlePropertyChange 结束', tag: 'ImagePropertyPanel');
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

  // 内容属性滑块拖动开始回调 - 保存原始值
  void _updateContentPropertyStart(String key, dynamic originalValue) {
    if (key == 'binaryThreshold') {
      _originalBinaryThreshold = originalValue as double?;
      AppLogger.debug(
        '图像二值化阈值拖动开始',
        tag: 'ImagePropertyPanel',
        data: {
          'originalBinaryThreshold': _originalBinaryThreshold,
          'operation': 'binary_threshold_drag_start',
        },
      );
    } else if (key == 'noiseReductionLevel') {
      _originalNoiseReductionLevel = originalValue as double?;
      AppLogger.debug(
        '图像降噪级别拖动开始',
        tag: 'ImagePropertyPanel',
        data: {
          'originalNoiseReductionLevel': _originalNoiseReductionLevel,
          'operation': 'noise_reduction_level_drag_start',
        },
      );
    }
  }

  // 内容属性滑块拖动预览回调 - 临时禁用undo并更新预览
  void _updateContentPropertyPreview(String key, dynamic value) {
    AppLogger.debug(
      '图像内容属性预览更新',
      tag: 'ImagePropertyPanel',
      data: {
        'key': key,
        'value': value,
        'operation': 'content_property_preview_update',
      },
    );

    // 临时禁用undo
    widget.controller.undoRedoManager.undoEnabled = false;
    updateContentProperty(key, value);
    // 重新启用undo
    widget.controller.undoRedoManager.undoEnabled = true;
  }

  // 内容属性滑块拖动结束回调 - 基于原始值创建undo操作
  void _updateContentPropertyWithUndo(String key, dynamic newValue) {
    double? originalValue;
    String operationName = '';

    switch (key) {
      case 'binaryThreshold':
        originalValue = _originalBinaryThreshold;
        operationName = 'binary_threshold_undo_optimized_update';
        break;
      case 'noiseReductionLevel':
        originalValue = _originalNoiseReductionLevel;
        operationName = 'noise_reduction_level_undo_optimized_update';
        break;
    }

    if (originalValue != null && originalValue != newValue) {
      try {
        AppLogger.debug(
          '图像内容属性undo优化更新开始',
          tag: 'ImagePropertyPanel',
          data: {
            'key': key,
            'originalValue': originalValue,
            'newValue': newValue,
            'operation': operationName,
          },
        );

        // 先临时禁用undo，恢复到原始值
        widget.controller.undoRedoManager.undoEnabled = false;
        updateContentProperty(key, originalValue);

        // 重新启用undo，然后更新到新值（这会记录一次从原始值到新值的undo）
        widget.controller.undoRedoManager.undoEnabled = true;
        updateContentProperty(key, newValue);

        // 对于二值化参数，触发图像处理管线
        if ((key == 'binaryThreshold' || key == 'noiseReductionLevel')) {
          handleBinarizationParameterChange(key, newValue);
        }

        AppLogger.debug(
          '图像内容属性undo优化更新完成',
          tag: 'ImagePropertyPanel',
          data: {
            'key': key,
            'originalValue': originalValue,
            'newValue': newValue,
            'operation': '${operationName}_complete',
          },
        );
      } catch (error) {
        // 确保在错误情况下也重新启用undo
        widget.controller.undoRedoManager.undoEnabled = true;
        AppLogger.error(
          '图像内容属性undo更新失败',
          tag: 'ImagePropertyPanel',
          error: error,
          data: {
            'key': key,
            'newValue': newValue,
            'originalValue': originalValue,
            'operation': 'content_property_undo_update_error',
          },
        );

        // 发生错误时，回退到直接更新
        updateContentProperty(key, newValue);
        // 对于二值化参数，触发图像处理管线
        if ((key == 'binaryThreshold' || key == 'noiseReductionLevel')) {
          handleBinarizationParameterChange(key, newValue);
        }
      }
    } else {
      // 如果没有原始值或值没有改变，直接更新
      updateContentProperty(key, newValue);
      // 对于二值化参数，触发图像处理管线
      if ((key == 'binaryThreshold' || key == 'noiseReductionLevel')) {
        handleBinarizationParameterChange(key, newValue);
      }
    }

    // 清空相应的原始值
    switch (key) {
      case 'binaryThreshold':
        _originalBinaryThreshold = null;
        break;
      case 'noiseReductionLevel':
        _originalNoiseReductionLevel = null;
        break;
    }
  }

  // 属性滑块拖动开始回调 - 保存原始值
  void _updatePropertyStart(String key, dynamic originalValue) {
    if (key == 'opacity') {
      _originalOpacity = originalValue as double?;
      AppLogger.debug(
        '图像属性透明度拖动开始',
        tag: 'ImagePropertyPanel',
        data: {
          'originalOpacity': _originalOpacity,
          'operation': 'opacity_drag_start',
        },
      );
    }
  }

  // 属性滑块拖动预览回调 - 临时禁用undo并更新预览
  void _updatePropertyPreview(String key, dynamic value) {
    AppLogger.debug(
      '图像属性预览更新',
      tag: 'ImagePropertyPanel',
      data: {
        'key': key,
        'value': value,
        'operation': 'property_preview_update',
      },
    );

    // 临时禁用undo
    widget.controller.undoRedoManager.undoEnabled = false;
    updateProperty(key, value);
    // 重新启用undo
    widget.controller.undoRedoManager.undoEnabled = true;
  }

  // 属性滑块拖动结束回调 - 基于原始值创建undo操作
  void _updatePropertyWithUndo(String key, dynamic newValue) {
    if (key == 'opacity' &&
        _originalOpacity != null &&
        _originalOpacity != newValue) {
      try {
        AppLogger.debug(
          '图像属性透明度undo优化更新开始',
          tag: 'ImagePropertyPanel',
          data: {
            'originalOpacity': _originalOpacity,
            'newOpacity': newValue,
            'operation': 'opacity_undo_optimized_update',
          },
        );

        // 先临时禁用undo，恢复到原始值
        widget.controller.undoRedoManager.undoEnabled = false;
        updateProperty(key, _originalOpacity!);

        // 重新启用undo，然后更新到新值（这会记录一次从原始值到新值的undo）
        widget.controller.undoRedoManager.undoEnabled = true;
        updateProperty(key, newValue);

        AppLogger.debug(
          '图像属性透明度undo优化更新完成',
          tag: 'ImagePropertyPanel',
          data: {
            'originalOpacity': _originalOpacity,
            'newOpacity': newValue,
            'operation': 'opacity_undo_optimized_update_complete',
          },
        );
      } catch (error) {
        // 确保在错误情况下也重新启用undo
        widget.controller.undoRedoManager.undoEnabled = true;
        AppLogger.error(
          '图像属性透明度undo更新失败',
          tag: 'ImagePropertyPanel',
          error: error,
          data: {
            'key': key,
            'newValue': newValue,
            'originalValue': _originalOpacity,
            'operation': 'property_undo_update_error',
          },
        );

        // 发生错误时，回退到直接更新
        updateProperty(key, newValue);
      }
    } else {
      // 如果没有原始值或值没有改变，直接更新
      updateProperty(key, newValue);
    }

    // 清空原始值
    if (key == 'opacity') {
      _originalOpacity = null;
    }
  }
}
