import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'advanced_image_preview.dart';

/// 支持全屏图片预览的包装组件
class FullScreenImagePreview extends StatefulWidget {
  /// 图片路径列表
  final List<String> imagePaths;

  /// 初始选中的图片索引
  final int initialIndex;

  /// 图片索引变化回调
  final Function(int)? onIndexChanged;

  /// 是否显示底部缩略图
  final bool showThumbnails;

  /// 是否启用缩放
  final bool enableZoom;

  /// 容器装饰
  final BoxDecoration? previewDecoration;

  /// 内边距
  final EdgeInsets? padding;

  const FullScreenImagePreview({
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
  State<FullScreenImagePreview> createState() => _FullScreenImagePreviewState();
}

class _FullScreenImagePreviewState extends State<FullScreenImagePreview> {
  bool _isFullScreen = false;
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _focusNode = FocusNode();

  // 是否显示导航按钮
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    // 在全屏模式下创建Overlay
    if (_isFullScreen) {
      return Material(
        color: Colors.transparent,
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              _exitFullScreen();
            }
          },
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: GestureDetector(
              onTap: _toggleControls,
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: Colors.black,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 全屏图片预览
                    Positioned.fill(
                      child: AdvancedImagePreview(
                        imagePaths: widget.imagePaths,
                        initialIndex: _currentIndex,
                        onIndexChanged: _handleIndexChanged,
                        showThumbnails: widget.showThumbnails,
                        enableZoom: widget.enableZoom,
                        isFullScreen: true,
                        onFullScreenChanged: (isFullScreen) {
                          if (!isFullScreen) {
                            _exitFullScreen();
                          }
                        },
                        previewDecoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // 关闭按钮
                    Positioned(
                      top: 32,
                      right: 16,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          color: Colors.white,
                          onPressed: _exitFullScreen,
                          tooltip: '退出全屏',
                        ),
                      ),
                    ),

                    // 导航按钮 - 仅在_showControls为true时显示
                    if (_showControls) ...[
                      // 上一张按钮
                      if (_currentIndex > 0)
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Material(
                              color: Colors.black45,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.chevron_left),
                                color: Colors.white,
                                iconSize: 36,
                                onPressed: _previousImage,
                                tooltip:
                                    'Previous image', // Temporarily hardcoded
                              ),
                            ),
                          ),
                        ),

                      // 下一张按钮
                      if (_currentIndex < widget.imagePaths.length - 1)
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Material(
                              color: Colors.black45,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                color: Colors.white,
                                iconSize: 36,
                                onPressed: _nextImage,
                                tooltip:
                                    'Next image', // Temporary hardcoded string
                              ),
                            ),
                          ),
                        ),

                      // 图片计数器
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.imagePaths.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 非全屏模式
    return AdvancedImagePreview(
      imagePaths: widget.imagePaths,
      initialIndex: _currentIndex,
      onIndexChanged: _handleIndexChanged,
      showThumbnails: widget.showThumbnails,
      enableZoom: widget.enableZoom,
      isFullScreen: false,
      onFullScreenChanged: (isFullScreen) {
        if (isFullScreen) {
          _enterFullScreen();
        }
      },
      previewDecoration: widget.previewDecoration,
      padding: widget.padding,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // 3秒后自动隐藏导航控件
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });

    // 通知系统我们想要全屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    setState(() {
      _isFullScreen = false;
    });

    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _handleIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onIndexChanged?.call(index);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _exitFullScreen();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _nextImage() {
    if (_currentIndex < widget.imagePaths.length - 1) {
      setState(() {
        _currentIndex++;
      });
      widget.onIndexChanged?.call(_currentIndex);
      _resetControlsTimer();
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      widget.onIndexChanged?.call(_currentIndex);
      _resetControlsTimer();
    }
  }

  void _resetControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetControlsTimer();
    }
  }
}
