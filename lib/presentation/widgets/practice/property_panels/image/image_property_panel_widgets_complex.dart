import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../infrastructure/logging/logger.dart';
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
            ),
          ),
        ],
      ),
      ),
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
          backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          foregroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
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

/// 图像预览面板
class ImagePropertyPreviewPanel extends StatefulWidget {
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
  State<ImagePropertyPreviewPanel> createState() => _ImagePropertyPreviewPanelState();
}

class _ImagePropertyPreviewPanelState extends State<ImagePropertyPreviewPanel> {
  // 缩放和平移状态
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  late TransformationController _transformationController;

  // 缩放范围
  static const double minZoom = 0.5;
  static const double maxZoom = 5.0;
  static const double zoomStep = 0.2;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    setState(() {
      _zoomScale = matrix.getMaxScaleOnAxis();
      // Extract translation from the matrix
      final translation = matrix.getTranslation();
      _panOffset = Offset(translation.x, translation.y);
    });
  }

  void _zoomIn() {
    final newScale = (_zoomScale + zoomStep).clamp(minZoom, maxZoom);
    _setZoom(newScale);
  }

  void _zoomOut() {
    final newScale = (_zoomScale - zoomStep).clamp(minZoom, maxZoom);
    _setZoom(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _setZoom(double scale) {
    // Use dynamic preview center based on actual container size
    final containerSize = context.size ?? const Size(320, 320);
    final previewCenter = Offset(containerSize.width / 2, containerSize.height / 2);
    
    // Calculate zoom transformation around the preview center
    final matrix = Matrix4.identity()
      ..translate(previewCenter.dx, previewCenter.dy)
      ..scale(scale)
      ..translate(-previewCenter.dx, -previewCenter.dy)
      ..translate(_panOffset.dx, _panOffset.dy);
    _transformationController.value = matrix;
  }

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
                if (widget.imageUrl.isNotEmpty && widget.imageSize != null)
                  _buildImageInfo(context, l10n, colorScheme),
                const SizedBox(height: 8.0),
                
                // 缩放控制按钮
                _buildZoomControls(context, colorScheme),
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

  /// 构建缩放控制按钮
  Widget _buildZoomControls(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // 4个独立按钮，支持自动换行和居中对齐
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            // 缩小按钮
            IconButton(
              onPressed: _zoomScale > minZoom ? _zoomOut : null,
              icon: const Icon(Icons.zoom_out),
              tooltip: '缩小',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            
            // 放大按钮
            IconButton(
              onPressed: _zoomScale < maxZoom ? _zoomIn : null,
              icon: const Icon(Icons.zoom_in),
              tooltip: '放大',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            
            // 重置按钮
            IconButton(
              onPressed: _resetZoom,
              icon: const Icon(Icons.fit_screen),
              tooltip: '重置缩放',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            
            // 缩放比例显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${(_zoomScale * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 提示文本
        Center(
          child: Text(
            '支持手势缩放和拖拽',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建图片信息显示区域
  Widget _buildImageInfo(BuildContext context, AppLocalizations l10n, ColorScheme colorScheme) {
    final sizeText = widget.imageSize != null 
        ? '${widget.imageSize!.width.toInt()} × ${widget.imageSize!.height.toInt()} px'
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

  Widget _buildImagePreviewWithTransformBox(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    AppLogger.debug('🔍 _buildImagePreviewWithTransformBox', tag: 'ImagePropertyPanelWidgetsComplex', data: {
      'imageUrl': widget.imageUrl,
      'contentRotation': '${widget.contentRotation}°',
      'imageSize': '${widget.imageSize?.width.toStringAsFixed(1)}×${widget.imageSize?.height.toStringAsFixed(1)}',
      'renderSize': '${widget.renderSize?.width.toStringAsFixed(1)}×${widget.renderSize?.height.toStringAsFixed(1)}',
      'zoomScale': _zoomScale.toStringAsFixed(2),
      'panOffset': '${_panOffset.dx.toStringAsFixed(1)}, ${_panOffset.dy.toStringAsFixed(1)}'
    });

    // Preview should use the selected fit mode, not hardcoded "contain"
    final previewFitMode = widget.fitMode;

    return Container(
      height: 320, // 🔧 增加高度以更好适应旋转后的图像
      width: double.infinity,  // 🔧 使用可变宽度，非固定宽度
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12.0),
        color:
            colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
      ),
      child: widget.imageUrl.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                AppLogger.debug('🔍 LayoutBuilder constraints', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                  'constraintsSize': '${constraints.maxWidth.toStringAsFixed(1)}×${constraints.maxHeight.toStringAsFixed(1)}'
                });
                
                // 🔧 使用原始的imageSize和renderSize，不再基于动态边界重新计算
                // 因为裁剪框应该与Transform变换后的视觉效果匹配，而不是动态边界
                Size? currentImageSize = widget.imageSize;
                Size? currentRenderSize = widget.renderSize;

                return Stack(
                  children: [
                    // Layer 1: Transformed image (background)
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: minZoom,
                        maxScale: maxZoom,
                        panEnabled: true,
                        scaleEnabled: true,
                        boundaryMargin: EdgeInsets.zero,
                        constrained: false,
                        clipBehavior: Clip.hardEdge,
                          child: Builder(
                            builder: (context) {
                              // 🔍 Transform矩陣計算日誌
                              final centerX = constraints.maxWidth / 2;
                              final centerY = constraints.maxHeight / 2;
                              final rotationRadians = widget.contentRotation * (math.pi / 180.0);
                              
                              AppLogger.debug('🔍 Transform矩陣構建', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                'containerSize': '${constraints.maxWidth.toStringAsFixed(1)}×${constraints.maxHeight.toStringAsFixed(1)}',
                                'rotationCenter': '(${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)})',
                                'rotationAngle': '${widget.contentRotation}° = ${rotationRadians.toStringAsFixed(4)} radians',
                                'flipState': 'flipH=${widget.flipHorizontal}, flipV=${widget.flipVertical}'
                              });
                              
                              // 構建變換矩陣
                              final transformMatrix = Matrix4.identity()
                                ..translate(centerX, centerY)
                                ..rotateZ(rotationRadians)
                                ..scale(
                                  widget.flipHorizontal ? -1.0 : 1.0,
                                  widget.flipVertical ? -1.0 : 1.0,
                                )
                                ..translate(-centerX, -centerY);
                              
                              AppLogger.debug('變換順序', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                'transformSequence': 'translate(${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)}) → rotateZ(${rotationRadians.toStringAsFixed(4)}) → scale(${widget.flipHorizontal ? -1.0 : 1.0}, ${widget.flipVertical ? -1.0 : 1.0}) → translate(-${centerX.toStringAsFixed(1)}, -${centerY.toStringAsFixed(1)})'
                              });
                              
                              // 測試角點變換
                              if (widget.renderSize != null) {
                                final imageLeft = (constraints.maxWidth - widget.renderSize!.width) / 2;
                                final imageTop = (constraints.maxHeight - widget.renderSize!.height) / 2;
                                final imageRight = imageLeft + widget.renderSize!.width;
                                final imageBottom = imageTop + widget.renderSize!.height;
                                
                                AppLogger.debug('原始圖像區域', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                  'imageRegion': 'Rect.fromLTWH(${imageLeft.toStringAsFixed(1)}, ${imageTop.toStringAsFixed(1)}, ${widget.renderSize!.width.toStringAsFixed(1)}, ${widget.renderSize!.height.toStringAsFixed(1)})'
                                });
                                
                                if (widget.contentRotation != 0) {
                                  // 計算四個角點變換後的位置
                                  final corners = [
                                    {'name': '左上', 'point': [imageLeft, imageTop]},
                                    {'name': '右上', 'point': [imageRight, imageTop]},
                                    {'name': '右下', 'point': [imageRight, imageBottom]},
                                    {'name': '左下', 'point': [imageLeft, imageBottom]},
                                  ];
                                  
                                  double minX = double.infinity, maxX = double.negativeInfinity;
                                  double minY = double.infinity, maxY = double.negativeInfinity;
                                  
                                  AppLogger.debug('🔄 角點變換計算', tag: 'ImagePropertyPanelWidgetsComplex');
                                  for (final corner in corners) {
                                    final point = corner['point'] as List<double>;
                                    final x = point[0];
                                    final y = point[1];
                                    
                                    // 簡化的90度旋轉計算（用於日誌對比）
                                    if (widget.contentRotation.abs() == 90 || widget.contentRotation.abs() == 270) {
                                      final deltaX = x - centerX;
                                      final deltaY = y - centerY;
                                      final newX = widget.contentRotation == 90 ? -deltaY + centerX : deltaY + centerX;
                                      final newY = widget.contentRotation == 90 ? deltaX + centerY : -deltaX + centerY;
                                      
                                      AppLogger.debug('角點變換結果', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                        'corner': corner['name'],
                                        'original': '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})',
                                        'transformed': '(${newX.toStringAsFixed(1)}, ${newY.toStringAsFixed(1)})'
                                      });
                                      
                                      minX = math.min(minX, newX);
                                      maxX = math.max(maxX, newX);
                                      minY = math.min(minY, newY);
                                      maxY = math.max(maxY, newY);
                                    }
                                  }
                                  
                                  if (widget.contentRotation.abs() == 90 || widget.contentRotation.abs() == 270) {
                                    AppLogger.debug('變換後邊界框計算結果', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                      'boundingBox': 'Rect.fromLTRB(${minX.toStringAsFixed(1)}, ${minY.toStringAsFixed(1)}, ${maxX.toStringAsFixed(1)}, ${maxY.toStringAsFixed(1)})',
                                      'transformedSize': '${(maxX - minX).toStringAsFixed(1)}×${(maxY - minY).toStringAsFixed(1)}'
                                    });
                                  }
                                }
                              }
                              
                              AppLogger.debug('🔍 Transform矩陣構建結束', tag: 'ImagePropertyPanelWidgetsComplex');
                              
                              return Transform(
                                transform: transformMatrix,
                                child: _buildImageWithSizeListener(
                                  context: context,
                                  imageUrl: widget.imageUrl,
                                  fitMode: _getFitMode(previewFitMode),
                                  onImageSizeAvailable: (detectedImageSize, detectedRenderSize) {
                                    AppLogger.debug('图像监听器回调', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                      'operation': 'onImageLoaded',
                                      'detectedImageSize': '${detectedImageSize.width.toStringAsFixed(1)}×${detectedImageSize.height.toStringAsFixed(1)}',
                                      'detectedRenderSize': '${detectedRenderSize.width.toStringAsFixed(1)}×${detectedRenderSize.height.toStringAsFixed(1)}'
                                    });
                                    
                                    // 只在首次加载时调用
                                    if (widget.imageSize == null) {
                                      AppLogger.debug('首次图像加载', tag: 'ImagePropertyPanelWidgetsComplex');
                                      widget.onImageSizeAvailable(detectedImageSize, detectedRenderSize);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ),
                    
                    // Layer 2: Crop overlay (使用zoom-aware版本支持缩放)
                    if (currentImageSize != null &&
                        currentRenderSize != null &&
                        widget.onCropChanged != null)
                      Positioned.fill(
                        child: ZoomedCropOverlay(
                          imageSize: currentImageSize,
                          renderSize: currentRenderSize,
                          cropX: widget.cropX,
                          cropY: widget.cropY,
                          cropWidth: widget.cropWidth,
                          cropHeight: widget.cropHeight,
                          contentRotation: widget.contentRotation, // 🔧 使用实际旋转角度，不再强制为0
                          flipHorizontal: widget.flipHorizontal,
                          flipVertical: widget.flipVertical,
                          onCropChanged: widget.onCropChanged!,
                          enabled: true,
                          zoomScale: _zoomScale,
                          panOffset: _panOffset,
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
                AppLogger.debug('图像加载完成', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                  'operation': 'onImageLoaded_start',
                  'imageSize': '${size.width.toStringAsFixed(1)}×${size.height.toStringAsFixed(1)}',
                  'contentRotation': '${widget.contentRotation}°',
                  'flipHorizontal': widget.flipHorizontal,
                  'flipVertical': widget.flipVertical
                });
                
                // 图像加载完成后获取尺寸
                final imageSize = size;

                // 🔧 修复：计算动态边界尺寸用于裁剪框计算
                final dynamicBounds = _calculateDynamicBounds(imageSize, widget.contentRotation, widget.flipHorizontal, widget.flipVertical);
                
                // 计算渲染尺寸（基于动态边界）
                final renderSize = _calculateRenderSize(
                    dynamicBounds, // 使用动态边界而不是原始图像尺寸
                    constraints.biggest,
                    fitMode == BoxFit.contain
                        ? 'contain'
                        : fitMode == BoxFit.cover
                            ? 'cover'
                            : fitMode == BoxFit.fill
                                ? 'fill'
                                : 'none');

                AppLogger.debug('渲染尺寸计算完成', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                  'dynamicBounds': '${dynamicBounds.width.toStringAsFixed(1)}×${dynamicBounds.height.toStringAsFixed(1)}',
                  'constraintsBiggest': '${constraints.biggest.width.toStringAsFixed(1)}×${constraints.biggest.height.toStringAsFixed(1)}',
                  'renderSize': '${renderSize.width.toStringAsFixed(1)}×${renderSize.height.toStringAsFixed(1)}'
                });

                // 检查当前 widget 是否仍然挂载
                if (context.mounted) {
                  AppLogger.debug('调用图像尺寸回调', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                    'imageSize': '$imageSize',
                    'renderSize': '$renderSize'
                  });
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
          final imageProvider = NetworkImage(widget.imageUrl);

          final imageStream = imageProvider.resolve(ImageConfiguration(
            size: constraints.biggest,
          ));

          imageStream.addListener(ImageStreamListener(
            (ImageInfo info, bool _) {
              final imageSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
              
              AppLogger.debug('网络图像加载完成', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                'operation': 'network_image_loaded_start',
                'imageSize': '${imageSize.width.toStringAsFixed(1)}×${imageSize.height.toStringAsFixed(1)}',
                'contentRotation': '${widget.contentRotation}°',
                'flipHorizontal': widget.flipHorizontal,
                'flipVertical': widget.flipVertical
              });

              // 🔧 修复：计算动态边界尺寸用于裁剪框计算
              final dynamicBounds = _calculateDynamicBounds(imageSize, widget.contentRotation, widget.flipHorizontal, widget.flipVertical);
              
              final renderSize = _calculateRenderSize(
                dynamicBounds, // 使用动态边界而不是原始图像尺寸
                constraints.biggest,
                fitMode == BoxFit.contain
                    ? 'contain'
                    : fitMode == BoxFit.cover
                        ? 'cover'
                        : fitMode == BoxFit.fill
                            ? 'fill'
                            : 'none',
              );
              
              AppLogger.debug('网络图像渲染尺寸计算完成', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                'dynamicBounds': '${dynamicBounds.width.toStringAsFixed(1)}×${dynamicBounds.height.toStringAsFixed(1)}',
                'constraintsBiggest': '${constraints.biggest.width.toStringAsFixed(1)}×${constraints.biggest.height.toStringAsFixed(1)}',
                'renderSize': '${renderSize.width.toStringAsFixed(1)}×${renderSize.height.toStringAsFixed(1)}'
              });
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 检查当前 widget 是否仍然挂载
                if (context.mounted) {
                  AppLogger.debug('调用网络图像尺寸回调', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                    'imageSize': '$imageSize',
                    'renderSize': '$renderSize'
                  });
                  onImageSizeAvailable(imageSize, renderSize);
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
    
    AppLogger.debug('渲染尺寸计算开始', tag: 'ImagePropertyPanelWidgetsComplex', data: {
      'imageSize': '${imageSize.width.toStringAsFixed(1)}×${imageSize.height.toStringAsFixed(1)}',
      'containerSize': '${containerSize.width.toStringAsFixed(1)}×${containerSize.height.toStringAsFixed(1)}',
      'fitMode': fitMode,
      'imageRatio': imageRatio.toStringAsFixed(3),
      'containerRatio': containerRatio.toStringAsFixed(3)
    });

    Size result;
    String adaptationMethod;
    switch (fitMode) {
      case 'contain':
        if (imageRatio > containerRatio) {
          // 图像更宽，按宽度适配
          result = Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
          adaptationMethod = '图像更宽，按宽度适配';
        } else {
          // 图像更高，按高度适配
          result = Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
          adaptationMethod = '图像更高，按高度适配';
        }
        break;
      case 'cover':
        if (imageRatio > containerRatio) {
          result = Size(
            containerSize.height * imageRatio,
            containerSize.height,
          );
          adaptationMethod = 'Cover模式-按高度适配';
        } else {
          result = Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
          adaptationMethod = 'Cover模式-按宽度适配';
        }
        break;
      case 'fill':
        result = containerSize;
        adaptationMethod = '填充整个容器';
        break;
      case 'none':
        result = imageSize;
        adaptationMethod = '保持原始尺寸';
        break;
      default:
        result = Size(
          math.min(imageSize.width, containerSize.width),
          math.min(imageSize.height, containerSize.height),
        );
        adaptationMethod = '默认模式-取最小值';
        break;
    }
    
    // 🔧 计算空间利用率
    final spaceUtilization = (result.width * result.height) / (containerSize.width * containerSize.height);
    
    AppLogger.debug('渲染尺寸计算完成', tag: 'ImagePropertyPanelWidgetsComplex', data: {
      'adaptationMethod': adaptationMethod,
      'result': '${result.width.toStringAsFixed(1)}×${result.height.toStringAsFixed(1)}',
      'spaceUtilization': '${(spaceUtilization * 100).toStringAsFixed(1)}%'
    });
    
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

  /// 计算动态边界尺寸（考虑旋转变换）
  Size _calculateDynamicBounds(Size originalSize, double rotation, bool flipH, bool flipV) {
    AppLogger.debug('动态边界计算开始', tag: 'ImagePropertyPanelWidgetsComplex', data: {
      'originalSize': '${originalSize.width.toStringAsFixed(1)}×${originalSize.height.toStringAsFixed(1)}',
      'rotation': '$rotation°'
    });
    
    Size result;
    String calculationMethod;
    
    // 對於90度的倍數，直接交換寬高（更精確）
    if (rotation == 90 || rotation == 270 || rotation == -90 || rotation == -270) {
      result = Size(originalSize.height, originalSize.width);
      calculationMethod = '90度倍數旋轉，直接交換寬高';
    }
    else if (rotation == 0 || rotation == 180 || rotation == -180) {
      result = originalSize;
      calculationMethod = '0度或180度旋轉，保持原始尺寸';
    }
    else {
      // 對於其他角度，計算包圍框
      final rotationRadians = rotation * (math.pi / 180.0);
      final cos = math.cos(rotationRadians).abs();
      final sin = math.sin(rotationRadians).abs();
      
      final newWidth = originalSize.width * cos + originalSize.height * sin;
      final newHeight = originalSize.width * sin + originalSize.height * cos;
      
      result = Size(newWidth, newHeight);
      calculationMethod = '任意角度包圍框計算';
    }
    
    AppLogger.debug('动态边界计算完成', tag: 'ImagePropertyPanelWidgetsComplex', data: {
      'calculationMethod': calculationMethod,
      'result': '${result.width.toStringAsFixed(1)}×${result.height.toStringAsFixed(1)}'
    });
    
    return result;
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
            ),
          ),
        ],
      ),
      ),
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
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
  final Function(bool) onBinarizationToggle;
  final Function(String, dynamic) onBinarizationParameterChange;

  const ImagePropertyBinarizationPanel({
    super.key,
    required this.isBinarizationEnabled,
    required this.threshold,
    required this.isNoiseReductionEnabled,
    required this.noiseReductionLevel,
    required this.onContentPropertyUpdate,
    required this.onBinarizationToggle,
    required this.onBinarizationParameterChange,
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
                        onChanged: (value) {
                          AppLogger.debug('二值化开关状态变更', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                            'currentValue': isBinarizationEnabled,
                            'newValue': value
                          });
                          
                          // 只调用 onBinarizationToggle，它会处理所有必要的属性更新
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
                                    activeColor: isBinarizationEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38),
                                    thumbColor: isBinarizationEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38),
                                    onChanged: isBinarizationEnabled ? (value) {
                                      // 拖拽过程中只更新属性值，不触发图像处理
                                      onContentPropertyUpdate('binaryThreshold', value);
                                    } : null,
                                    onChangeEnd: isBinarizationEnabled ? (value) {
                                      // 滑块释放时才触发图像处理
                                      onBinarizationParameterChange('binaryThreshold', value);
                                    } : null,
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
                                      color: isBinarizationEnabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withValues(alpha: 0.38),
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
                              onChanged: isBinarizationEnabled ? (value) {
                                onContentPropertyUpdate('isNoiseReductionEnabled', value);
                                onBinarizationParameterChange('isNoiseReductionEnabled', value);
                              } : null,
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
                                      activeColor: (isBinarizationEnabled && isNoiseReductionEnabled) ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38),
                                      thumbColor: (isBinarizationEnabled && isNoiseReductionEnabled) ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38),
                                      onChanged: (isBinarizationEnabled && isNoiseReductionEnabled) ? (value) {
                                        // 拖拽过程中只更新属性值，不触发图像处理
                                        onContentPropertyUpdate('noiseReductionLevel', value);
                                      } : null,
                                      onChangeEnd: (isBinarizationEnabled && isNoiseReductionEnabled) ? (value) {
                                        // 滑块释放时才触发图像处理
                                        onBinarizationParameterChange('noiseReductionLevel', value);
                                      } : null,
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
                                        color: (isBinarizationEnabled && isNoiseReductionEnabled) ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withValues(alpha: 0.38),
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
        title: Text(l10n.flip),
        initiallyExpanded: false,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information alert about flip processing order
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer
                        .withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colorScheme.tertiary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.imagePropertyPanelFlipInfo,
                          style: TextStyle(
                              fontSize: 14, color: colorScheme.tertiary),
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
                                AppLogger.debug('水平翻转开关点击', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                  'newValue': value,
                                  'currentState': {
                                    'flipHorizontal': flipHorizontal,
                                    'flipVertical': flipVertical
                                  },
                                  'expectedState': {
                                    'flipHorizontal': value,
                                    'flipVertical': flipVertical
                                  },
                                  'bothFlipsDisabled': (!value && !flipVertical)
                                });
                                
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
                                AppLogger.debug('垂直翻转开关点击', tag: 'ImagePropertyPanelWidgetsComplex', data: {
                                  'newValue': value,
                                  'currentState': {
                                    'flipHorizontal': flipHorizontal,
                                    'flipVertical': flipVertical
                                  },
                                  'expectedState': {
                                    'flipHorizontal': flipHorizontal,
                                    'flipVertical': value
                                  },
                                  'bothFlipsDisabled': (!flipHorizontal && !value)
                                });
                                
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
            ),
          ),
        ],
      ),
      ),
    );
  }
}
