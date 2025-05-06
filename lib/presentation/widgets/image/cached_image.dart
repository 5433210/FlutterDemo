import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/cache/services/image_cache_service.dart';
import '../../../infrastructure/providers/cache_providers.dart';

/// A simple cached image widget for loading file-based images with memory caching
class CachedImage extends ConsumerStatefulWidget {
  /// The file path to the image
  final String path;

  /// How the image should be inscribed into the box
  final BoxFit? fit;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Builder for displaying errors
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// Callback when image is loaded, provides the image size
  final Function(Size)? onImageLoaded;

  /// Simple constructor
  const CachedImage({
    super.key,
    required this.path,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.onImageLoaded,
  });

  @override
  ConsumerState<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends ConsumerState<CachedImage> {
  ImageProvider? _imageProvider;
  Object? _error;
  StackTrace? _stackTrace;
  late ImageCacheService _cacheService;

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!, _stackTrace);
    }

    if (_imageProvider == null) {
      return const SizedBox.shrink();
    }

    return Image(
      image: _imageProvider!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.errorBuilder,
    );
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadImage();
    }
  }

  @override
  void initState() {
    super.initState();
    _cacheService = ref.read(imageCacheServiceProvider);
    _loadImage();
  }

  // 异步缓存图像数据
  Future<void> _cacheImageData(File file) async {
    try {
      // 生成缓存键
      final cacheKey = 'file:${widget.path}';

      // 检查缓存中是否已存在
      final cachedData = await _cacheService.getBinaryImage(cacheKey);
      if (cachedData != null) {
        // 缓存中已存在，无需再次缓存
        return;
      }

      // 读取文件数据并缓存
      final fileData = await file.readAsBytes();
      await _cacheService.cacheBinaryImage(cacheKey, fileData);
    } catch (e) {
      // 缓存失败不影响显示，只记录日志
      debugPrint('缓存图像数据失败: $e');
    }
  }

  void _loadImage() {
    try {
      final file = File(widget.path);
      if (!file.existsSync()) {
        setState(() {
          _error = Exception('File does not exist');
          _imageProvider = null;
        });
        return;
      }

      // 创建文件图像提供者
      final fileImage = FileImage(file);

      // 设置图像提供者
      _imageProvider = fileImage;
      _error = null;
      _stackTrace = null;

      // 强制重建
      setState(() {});

      // 如果有onImageLoaded回调，获取图像尺寸并调用回调
      if (widget.onImageLoaded != null) {
        // 使用ImageStreamListener获取图像尺寸
        final imageStream = fileImage.resolve(const ImageConfiguration());
        imageStream.addListener(ImageStreamListener(
          (ImageInfo info, bool _) {
            final size = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            widget.onImageLoaded!(size);
          },
        ));
      }

      // 异步缓存图像数据
      _cacheImageData(file);
    } catch (e, stackTrace) {
      setState(() {
        _error = e;
        _stackTrace = stackTrace;
        _imageProvider = null;
      });
    }
  }
}
