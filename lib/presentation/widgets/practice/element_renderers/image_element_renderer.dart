import 'package:flutter/material.dart';

/// 图片元素渲染器
class ImageElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final bool isSelected;
  final double scale;

  const ImageElementRenderer({
    Key? key,
    required this.element,
    this.isSelected = false,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = element['content'] as Map<String, dynamic>;
    final String imageUrl = content['imageUrl'] as String? ?? '';
    final String fit = content['fit'] as String? ?? 'contain';

    BoxFit boxFit;
    switch (fit) {
      case 'cover':
        boxFit = BoxFit.cover;
        break;
      case 'fill':
        boxFit = BoxFit.fill;
        break;
      case 'fitWidth':
        boxFit = BoxFit.fitWidth;
        break;
      case 'fitHeight':
        boxFit = BoxFit.fitHeight;
        break;
      case 'none':
        boxFit = BoxFit.none;
        break;
      case 'scaleDown':
        boxFit = BoxFit.scaleDown;
        break;
      case 'contain':
      default:
        boxFit = BoxFit.contain;
    }

    Widget imageWidget;
    if (imageUrl.isEmpty) {
      imageWidget = _buildEmptyImage();
    } else {
      imageWidget = Image.network(
        imageUrl,
        fit: boxFit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(error.toString());
        },
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: isSelected
          ? BoxDecoration(
              border: Border.all(
                color: Colors.blue.withOpacity(0.5),
                width: 1.0,
              ),
            )
          : null,
      child: imageWidget,
    );
  }

  /// 构建空图片占位符
  Widget _buildEmptyImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 构建错误图片占位符
  Widget _buildErrorImage(String errorMessage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(
          color: Colors.red.shade300,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            const Text('图片加载失败', style: TextStyle(color: Colors.red)),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 10, color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
          const SizedBox(height: 8),
          const Text('加载中...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
