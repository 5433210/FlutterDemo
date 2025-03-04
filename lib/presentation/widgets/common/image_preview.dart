import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ImagePreview extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Function(int)? onIndexChanged;
  final bool showThumbnails;
  final bool enableZoom;
  final BoxDecoration? previewDecoration;
  final EdgeInsets? padding;

  const ImagePreview({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.showThumbnails = true,
    this.enableZoom = true,
    this.previewDecoration,
    this.padding,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        children: [
          // Main preview area
          Expanded(
            child: Container(
              decoration: widget.previewDecoration ??
                  BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
              child: widget.imagePaths.isNotEmpty
                  ? InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(20.0),
                      minScale: 0.1,
                      maxScale: 4.0,
                      constrained: widget.enableZoom,
                      child: Center(
                        child: Image.file(
                          File(widget.imagePaths[_currentIndex]),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 64, color: Colors.red),
                                  SizedBox(height: 16),
                                  Text('图片加载失败',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : const Center(child: Text('没有图片')),
            ),
          ),

          // Thumbnail list
          if (widget.showThumbnails && widget.imagePaths.length > 1) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: MouseRegion(
                cursor: _isDragging
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: Listener(
                  onPointerDown: (_) => setState(() => _isDragging = true),
                  onPointerUp: (_) => setState(() => _isDragging = false),
                  onPointerSignal: (signal) {
                    if (signal is PointerScrollEvent &&
                        _scrollController.hasClients) {
                      _scrollController.animateTo(
                        (_scrollController.offset + signal.scrollDelta.dy * 0.5)
                            .clamp(0.0,
                                _scrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.imagePaths.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                                if (widget.onIndexChanged != null) {
                                  widget.onIndexChanged!(index);
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: index == _currentIndex
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade300,
                                      width: index == _currentIndex ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Image.file(
                                    File(widget.imagePaths[index]),
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
}
