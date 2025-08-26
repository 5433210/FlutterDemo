import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../image/cached_image.dart';
import 'interactive_crop_overlay.dart';

/// 放大图像预览对话框
/// 支持缩放、平移和精确裁剪
class ImageZoomPreviewDialog extends StatefulWidget {
  final String imageUrl;
  final String fitMode;
  final double cropX;
  final double cropY;
  final double cropWidth;
  final double cropHeight;
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final Size? imageSize;
  final Size? renderSize;
  final Function(Size, Size) onImageSizeAvailable;
  final Function(double, double, double, double)? onCropChanged;

  const ImageZoomPreviewDialog({
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
    required this.imageSize,
    required this.renderSize,
    required this.onImageSizeAvailable,
    this.onCropChanged,
  });

  @override
  State<ImageZoomPreviewDialog> createState() => _ImageZoomPreviewDialogState();
}

class _ImageZoomPreviewDialogState extends State<ImageZoomPreviewDialog> {
  // 缩放和平移控制器
  late TransformationController _transformationController;

  // 当前图像和渲染尺寸
  Size? _currentImageSize;
  Size? _currentRenderSize;

  // 当前裁剪参数（用于本地状态管理）
  late double _localCropX;
  late double _localCropY;
  late double _localCropWidth;
  late double _localCropHeight;

  // 用于检测变化的初始值
  late double _initialCropX;
  late double _initialCropY;
  late double _initialCropWidth;
  late double _initialCropHeight;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // 初始化裁剪参数
    _localCropX = widget.cropX;
    _localCropY = widget.cropY;
    _localCropWidth = widget.cropWidth;
    _localCropHeight = widget.cropHeight;

    // 记录初始值用于取消时恢复
    _initialCropX = widget.cropX;
    _initialCropY = widget.cropY;
    _initialCropWidth = widget.cropWidth;
    _initialCropHeight = widget.cropHeight;

    // 初始化图像尺寸
    _currentImageSize = widget.imageSize;
    _currentRenderSize = widget.renderSize;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// 适合窗口大小（重置到初始状态，图像通过Center和BoxFit.contain自动适配）
  void _fitToWindow() {
    // 重置变换控制器到初始状态（无变换）
    // 这样图像会回到初始的居中显示状态，通过CachedImage的fit模式自动适配
    _transformationController.value = Matrix4.identity();
  }

  /// 重置裁剪区域为整个图像
  void _resetCropToFullImage() {
    if (_currentImageSize == null) return;
    
    setState(() {
      _localCropX = 0;
      _localCropY = 0;
      _localCropWidth = _currentImageSize!.width;
      _localCropHeight = _currentImageSize!.height;
    });
  }

  /// 处理裁剪变化
  void _handleCropChanged(double x, double y, double width, double height,
      {bool isDragging = false}) {
    setState(() {
      _localCropX = x;
      _localCropY = y;
      _localCropWidth = width;
      _localCropHeight = height;
    });
  }

  /// 检查是否有变化
  bool _hasChanges() {
    const threshold = 0.01;
    return ((_localCropX - _initialCropX).abs() > threshold ||
        (_localCropY - _initialCropY).abs() > threshold ||
        (_localCropWidth - _initialCropWidth).abs() > threshold ||
        (_localCropHeight - _initialCropHeight).abs() > threshold);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.zoom_in, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                l10n.imagePreview,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            // 适合窗口按钮
            IconButton(
              icon: const Icon(Icons.fit_screen),
              tooltip: l10n.fitToWindow,
              onPressed: _fitToWindow,
            ),
            // 重置裁剪区域按钮
            IconButton(
              icon: const Icon(Icons.crop_free),
              tooltip: l10n.resetCropArea,
              onPressed: _resetCropToFullImage,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // 主要预览区域 - 占用大部分空间
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black87, // 与背景一致
                child: _buildZoomableImage(context),
              ),
            ),

            // 紧凑的底部控制栏 - 固定高度
            Container(
              height: 120, // 固定紧凑高度
              color: colorScheme.surfaceContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 裁剪信息显示 - 紧凑版本
                  if (_currentImageSize != null)
                    _buildCompactCropInfo(context),
                  
                  const SizedBox(height: 8),

                  // 操作按钮行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 取消按钮 - 紧凑版
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),

                      // 确认按钮 - 紧凑版
                      FilledButton(
                        onPressed: _hasChanges() ? () {
                          if (widget.onCropChanged != null) {
                            widget.onCropChanged!(
                              _localCropX,
                              _localCropY,
                              _localCropWidth,
                              _localCropHeight,
                            );
                          }
                          Navigator.of(context).pop(true);
                        } : null,
                        child: Text(l10n.confirm),
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

  /// 构建可缩放的图像
  Widget _buildZoomableImage(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported,
                size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              l10n.noImageSelected,
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,  // 可以缩小到10%
      maxScale: 10.0, // 可以放大到1000%
      boundaryMargin: const EdgeInsets.all(double.infinity), // 允许无限边界
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 图像显示
              Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateZ(widget.contentRotation * (math.pi / 180.0))
                    ..scale(
                      widget.flipHorizontal ? -1.0 : 1.0,
                      widget.flipVertical ? -1.0 : 1.0,
                    ),
                  child: _buildImageWithSizeListener(context),
                ),
              ),

              // 裁剪覆盖层
              if (_currentImageSize != null &&
                  _currentRenderSize != null &&
                  widget.onCropChanged != null)
                Positioned.fill(
                  child: InteractiveCropOverlay(
                    imageSize: _currentImageSize!,
                    renderSize: _currentRenderSize!,
                    cropX: _localCropX,
                    cropY: _localCropY,
                    cropWidth: _localCropWidth,
                    cropHeight: _localCropHeight,
                    contentRotation: widget.contentRotation,
                    flipHorizontal: widget.flipHorizontal,
                    flipVertical: widget.flipVertical,
                    onCropChanged: _handleCropChanged,
                    enabled: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 构建带尺寸监听的图像
  Widget _buildImageWithSizeListener(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 处理本地文件路径
    if (widget.imageUrl.startsWith('file://')) {
      try {
        String filePath = widget.imageUrl.substring(7);
        final file = File(filePath);

        if (!file.existsSync()) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.fileNotExist(filePath),
                  style: const TextStyle(color: Colors.red, fontSize: 16),
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
              fit: _getFitMode(widget.fitMode),
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        l10n.imageLoadError(error.toString()),
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
              onImageLoaded: (Size size) {
                final imageSize = size;
                final renderSize = _calculateRenderSize(
                  imageSize,
                  constraints.biggest,
                  widget.fitMode,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _currentImageSize = imageSize;
                      _currentRenderSize = renderSize;
                    });
                    widget.onImageSizeAvailable(imageSize, renderSize);
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
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n.imageProcessingPathError(e.toString()),
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else {
      // 处理网络图像
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Image.network(
            widget.imageUrl,
            fit: _getFitMode(widget.fitMode),
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
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
                        color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      l10n.imageLoadError(error.toString()),
                      style: const TextStyle(color: Colors.red, fontSize: 16),
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

  /// 构建紧凑版裁剪信息显示
  Widget _buildCompactCropInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 56, // 固定紧凑高度
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 裁剪图标和标题
          Icon(Icons.crop_free, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            l10n.cropping,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          
          // 裁剪数据 - 水平排列
          Expanded(
            child: Row(
              children: [
                _buildCompactCropValue('X', _localCropX.round()),
                const SizedBox(width: 12),
                _buildCompactCropValue('Y', _localCropY.round()),
                const SizedBox(width: 12),
                _buildCompactCropValue(l10n.width, _localCropWidth.round()),
                const SizedBox(width: 12),
                _buildCompactCropValue(l10n.height, _localCropHeight.round()),
              ],
            ),
          ),
          
          // 修改状态指示器
          if (_hasChanges())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.modified,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建紧凑版裁剪数值显示
  Widget _buildCompactCropValue(String label, int value) {
    return Text(
      '$label: ${value}px',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 计算渲染尺寸
  Size _calculateRenderSize(
      Size imageSize, Size containerSize, String fitMode) {
    final imageRatio = imageSize.width / imageSize.height;
    final containerRatio = containerSize.width / containerSize.height;

    Size result;
    switch (fitMode) {
      case 'contain':
        if (imageRatio > containerRatio) {
          result = Size(
            containerSize.width,
            containerSize.width / imageRatio,
          );
        } else {
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

  /// 获取适应模式
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
