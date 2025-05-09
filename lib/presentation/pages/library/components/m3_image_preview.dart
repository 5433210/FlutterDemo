import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../domain/entities/library_item.dart';

/// 图片预览组件
class M3ImagePreview extends StatefulWidget {
  /// 图库项目列表
  final List<LibraryItem> items;

  /// 初始索引
  final int initialIndex;

  /// 关闭回调
  final VoidCallback onClose;

  /// 构造函数
  const M3ImagePreview({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onClose,
  });

  @override
  State<M3ImagePreview> createState() => _M3ImagePreviewState();
}

class _M3ImagePreviewState extends State<M3ImagePreview> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片预览
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final item = widget.items[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: MemoryImage(item.thumbnail ?? Uint8List(0)),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: item.id),
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.error,
                      size: 48,
                    ),
                  );
                },
              );
            },
            itemCount: widget.items.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageController: pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),

          // 顶部工具栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 关闭按钮
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    onPressed: widget.onClose,
                  ),
                  // 标题
                  Text(
                    '${currentIndex + 1}/${widget.items.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  // 收藏按钮
                  IconButton(
                    icon: Icon(
                      widget.items[currentIndex].isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    color: widget.items[currentIndex].isFavorite
                        ? theme.colorScheme.error
                        : Colors.white,
                    onPressed: () {
                      // TODO: 实现收藏功能
                    },
                  ),
                ],
              ),
            ),
          ),

          // 底部工具栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件名
                  Text(
                    widget.items[currentIndex].name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 图片信息
                  Text(
                    '${widget.items[currentIndex].width}x${widget.items[currentIndex].height}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
