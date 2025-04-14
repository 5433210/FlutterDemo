import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../application/services/image/character_image_processor.dart';
import '../../domain/models/character/character_region.dart';
import '../../domain/models/character/processing_options.dart';
import '../../infrastructure/logging/logger.dart';
import '../../presentation/providers/character/character_collection_provider.dart';
import '../../presentation/providers/character/character_edit_providers.dart';
import '../../presentation/providers/character/character_refresh_notifier.dart';
import '../../presentation/providers/character/character_save_notifier.dart';
import '../../presentation/providers/character/erase_providers.dart' as erase;
import '../../presentation/providers/character/selected_region_provider.dart';
import 'character_edit_canvas.dart';
import 'dialogs/save_confirmation_dialog.dart';
import 'keyboard/shortcut_handler.dart';

/// 字符编辑面板组件
///
/// 用于编辑作品图片中的字符区域。
///
/// [selectedRegion] - 选中的字符区域
/// [imageData] - 图像数据
/// [processingOptions] - 处理选项
/// [workId] - 作品ID
/// [pageId] - 作品图片ID
/// [onEditComplete] - 编辑完成时的回调函数
class CharacterEditPanel extends ConsumerStatefulWidget {
  final CharacterRegion selectedRegion;
  final Uint8List? imageData;
  final ProcessingOptions processingOptions;
  final String workId;
  final String pageId;
  final Function(Map<String, dynamic>) onEditComplete;

  const CharacterEditPanel({
    super.key,
    required this.selectedRegion,
    required this.imageData,
    required this.processingOptions,
    required this.workId,
    required this.pageId,
    required this.onEditComplete,
  });

  @override
  ConsumerState<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _ChangeBrushSizeIntent extends Intent {
  final bool increase;
  const _ChangeBrushSizeIntent(this.increase);
}

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  final GlobalKey<CharacterEditCanvasState> _canvasKey = GlobalKey();
  final TextEditingController _characterController = TextEditingController();
  Timer? _progressTimer;
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _mainPanelFocusNode = FocusNode(); // 添加主面板的焦点节点
  bool _isEditing = false;
  bool _isNewSelection = false; // 标记是否为新创建的选区

  // State for internal image loading
  Future<ui.Image?>? _imageLoadingFuture;
  ui.Image? _loadedImage;

  // Add a timestamp for cache busting
  int _thumbnailRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;

  Map<Type, Action<Intent>> get _actions => {
        _SaveIntent: CallbackAction(onInvoke: (_) => _handleSave()),
        _UndoIntent: CallbackAction(
            onInvoke: (_) =>
                ref.read(erase.eraseStateProvider.notifier).undo()),
        _RedoIntent: CallbackAction(
            onInvoke: (_) =>
                ref.read(erase.eraseStateProvider.notifier).redo()),
        _OpenInputIntent: CallbackAction(onInvoke: (_) {
          setState(() => _isEditing = true);
          // 确保聚焦到输入框
          Future.delayed(const Duration(milliseconds: 50), () {
            _inputFocusNode.requestFocus();
          });
          return null;
        }),
        _ToggleInvertIntent: CallbackAction(
            onInvoke: (_) =>
                ref.read(erase.eraseStateProvider.notifier).toggleReverse()),
        _ToggleImageInvertIntent: CallbackAction(
            onInvoke: (_) => ref
                .read(erase.eraseStateProvider.notifier)
                .toggleImageInvert()),
        _ToggleContourIntent: CallbackAction(
            onInvoke: (_) =>
                ref.read(erase.eraseStateProvider.notifier).toggleContour()),
        _TogglePanModeIntent: CallbackAction(
            onInvoke: (_) =>
                ref.read(erase.eraseStateProvider.notifier).togglePanMode()),
        _SetBrushSizeIntent: CallbackAction(
          onInvoke: (intent) => ref
              .read(erase.eraseStateProvider.notifier)
              .setBrushSize((intent as _SetBrushSizeIntent).size),
        ),
      };

  Map<SingleActivator, Intent> get _shortcuts => {
        EditorShortcuts.save: const _SaveIntent(),
        EditorShortcuts.undo: const _UndoIntent(),
        EditorShortcuts.redo: const _RedoIntent(),
        EditorShortcuts.openInput: const _OpenInputIntent(),
        EditorShortcuts.toggleInvert: const _ToggleInvertIntent(),
        EditorShortcuts.toggleImageInvert: const _ToggleImageInvertIntent(),
        EditorShortcuts.toggleContour: const _ToggleContourIntent(),
        EditorShortcuts.togglePanMode: const _TogglePanModeIntent(),
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(characterRefreshNotifierProvider, (previous, current) {
      if (previous != current) {
        final refreshEvent =
            ref.read(characterRefreshNotifierProvider.notifier).lastEventType;
        if (refreshEvent == RefreshEventType.characterSaved) {
          // Force refresh of the thumbnail by updating the timestamp
          setState(() {
            _thumbnailRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
          });
          AppLogger.debug('触发缩略图刷新',
              data: {'timestamp': _thumbnailRefreshTimestamp});
        }
      }
    });

    return FocusScope(
      autofocus: true,
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: _actions,
          child: Focus(
            focusNode: _mainPanelFocusNode, // 使用我们定义的主面板焦点节点
            autofocus: true,
            // Add key event handler to catch all key events and log them for debugging
            onKeyEvent: (FocusNode node, KeyEvent event) {
              AppLogger.debug('接收到键盘事件', data: {
                'type': event.runtimeType.toString(),
                'logicalKey': event.logicalKey.keyLabel,
                'physicalKey': event.physicalKey.usbHidUsage.toString(),
                'character': event.character,
                'isControlPressed': HardwareKeyboard.instance.isControlPressed,
                'isShiftPressed': HardwareKeyboard.instance.isShiftPressed,
                'isAltPressed': HardwareKeyboard.instance.isAltPressed,
              });
              return KeyEventResult.ignored; // Let the event propagate
            },
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CharacterEditPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update character input if region character changes externally
    if (widget.selectedRegion.character != _characterController.text) {
      _characterController.text = widget.selectedRegion.character;
    }

    // Force thumbnail refresh when region ID changes (page change or new selection)
    if (widget.selectedRegion.id != oldWidget.selectedRegion.id ||
        widget.selectedRegion.characterId !=
            oldWidget.selectedRegion.characterId) {
      setState(() {
        _thumbnailRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
      });
      AppLogger.debug('Region changed - refreshing thumbnail', data: {
        'oldRegionId': oldWidget.selectedRegion.id,
        'newRegionId': widget.selectedRegion.id,
        'timestamp': _thumbnailRefreshTimestamp,
      });
    }

    // Reload image if selected region or image data changes
    if (widget.selectedRegion.id != oldWidget.selectedRegion.id ||
        widget.imageData != oldWidget.imageData ||
        widget.processingOptions != oldWidget.processingOptions) {
      _initiateImageLoading();
      // Clear erase state when region changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(erase.eraseStateProvider.notifier).clear();
      });
    }
  }

  @override
  void dispose() {
    try {
      // Remove keyboard handler
      ServicesBinding.instance.keyboard.removeHandler(_handleKeyboardEvent);

      _loadedImage?.dispose();
      _characterController.dispose();
      _inputFocusNode.dispose();
      _mainPanelFocusNode.dispose(); // 确保释放主面板焦点节点资源
    } catch (e) {
      AppLogger.error('Character edit panel dispose error: $e');
    } finally {
      super.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _characterController.text = widget.selectedRegion.character;

    // Check if this is a new selection (empty character and no characterId)
    _isNewSelection = widget.selectedRegion.character.isEmpty &&
        widget.selectedRegion.characterId == null;

    _initiateImageLoading();

    // Set up keyboard listener for save shortcut
    ServicesBinding.instance.keyboard.addHandler(_handleKeyboardEvent);

    // Clear erase state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(erase.eraseStateProvider.notifier).clear();
      //根据实际情况设置反转模式
      if ((widget.selectedRegion.options.inverted &&
              !ref.read(erase.eraseStateProvider).imageInvertMode) ||
          (!widget.selectedRegion.options.inverted &&
              ref.read(erase.eraseStateProvider).imageInvertMode)) {
        ref.read(erase.eraseStateProvider.notifier).toggleImageInvert();
      }

      // Automatically open character input for new selections
      if (_isNewSelection) {
        setState(() => _isEditing = true);
        // Use a short delay to ensure rendering is complete before focusing
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _inputFocusNode.requestFocus();
          }
        });
      }

      // Listen for all refresh events including erase data reload
      ref.listenManual(characterRefreshNotifierProvider, (previous, current) {
        if (previous != current) {
          final refreshEvent =
              ref.read(characterRefreshNotifierProvider.notifier).lastEventType;

          if (refreshEvent == RefreshEventType.eraseDataReloaded) {
            // Force state refresh when erase data is reloaded
            if (mounted) {
              setState(() {
                // Just trigger rebuild
                _thumbnailRefreshTimestamp =
                    DateTime.now().millisecondsSinceEpoch;
              });
            }
          }
        }
      });
    });
  }

  Future<ui.Image?> loadAndProcessImage(
    CharacterRegion region,
    Uint8List imageData,
    ProcessingOptions processingOptions,
  ) async {
    try {
      final imageProcessor = ref.read(characterImageProcessorProvider);
      final preview = await imageProcessor.processForPreview(
        imageData,
        region.rect,
        processingOptions,
        null,
        rotation: region.rotation,
      );

      final bytes = Uint8List.fromList(img.encodePng(preview.processedImage));
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      _loadedImage?.dispose(); // Dispose previous loaded image
      _loadedImage = await completer.future;
      return _loadedImage;
    } catch (e, stack) {
      AppLogger.error('Error loading/processing character image in panel',
          error: e, stackTrace: stack);
      return null;
    }
  }

  Widget _buildBottomButtons(SaveState saveState) {
    final bool isSaving = saveState.isSaving;
    final String? errorMessage = saveState.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_isEditing)
                TextButton.icon(
                  onPressed: isSaving
                      ? null
                      : () {
                          setState(() => _isEditing = true);
                          // 确保聚焦到输入框
                          Future.delayed(const Duration(milliseconds: 50), () {
                            _inputFocusNode.requestFocus();
                          });
                        },
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(ShortcutTooltipBuilder.build(
                    '输入汉字',
                    EditorShortcuts.openInput,
                  )),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isSaving ? null : () => _handleSave(),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(ShortcutTooltipBuilder.build(
                  '保存',
                  EditorShortcuts.save,
                )),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInput() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                '输入汉字',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: _restoreMainPanelFocus,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _characterController,
            focusNode: _inputFocusNode,
            autofocus: true,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(
              hintText: '请输入',
              counterText: '',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _restoreMainPanelFocus(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _restoreMainPanelFocus(),
                child: const Text('取消'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _restoreMainPanelFocus(),
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final saveState = ref.watch(characterSaveNotifierProvider);
    final eraseState = ref.watch(erase.eraseStateProvider);
    final processedImageNotifier = ref.watch(processedImageProvider.notifier);

    return Stack(
      children: [
        FutureBuilder<ui.Image?>(
          future: _imageLoadingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              processedImageNotifier
                  .setError('图像加载失败: ${snapshot.error ?? "未知错误"}');
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '无法加载或处理字符图像',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error ?? "未知错误"}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final loadedImageForCanvas = snapshot.data!;
            final region = ref.watch(selectedRegionProvider);

            return Column(
              children: [
                // 顶部工具栏
                _buildToolbar(),

                // 主要内容区域
                Expanded(
                  child: Stack(
                    children: [
                      // 画布
                      CharacterEditCanvas(
                        region: region,
                        key: _canvasKey,
                        image: loadedImageForCanvas,
                        showOutline: eraseState.showContour,
                        invertMode: eraseState.isReversed,
                        imageInvertMode: eraseState.imageInvertMode,
                        brushSize: eraseState.brushSize,
                        brushColor: eraseState.brushColor,
                        onEraseStart: _handleEraseStart,
                        onEraseUpdate: _handleEraseUpdate,
                        onEraseEnd: _handleEraseEnd,
                      ),

                      // 缩略图预览
                      if (region != null)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: _buildThumbnailPreview(),
                        ),

                      // 字符输入悬浮窗
                      if (_isEditing)
                        Positioned(
                          left: 16,
                          top: 16,
                          child: _buildCharacterInput(),
                        ),
                    ],
                  ),
                ),

                // 底部按钮
                _buildBottomButtons(saveState),
              ],
            );
          },
        ),

        // 保存时的加载遮罩
        if (saveState.isSaving)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _getSaveStatusText(saveState.progress),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (saveState.progress != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: saveState.progress!,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(saveState.progress! * 100).toInt()}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 16),
          Text('正在加载字符图像...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildThumbnailPreview() {
    // 检查region是否存在，如果不存在则不显示缩略图
    final region = ref.watch(selectedRegionProvider);
    if (region == null) {
      AppLogger.debug('CharacterEditPanel - 没有选中的区域，不显示缩略图');
      return const SizedBox.shrink();
    }

    // 检查region的characterId是否存在，如果不存在说明是新建选区，不显示缩略图
    if (region.characterId == null) {
      AppLogger.debug('CharacterEditPanel - 区域未关联字符，不显示缩略图');
      return const SizedBox.shrink();
    }

    // Add the region ID as part of the cache key to ensure different characters have different thumbnails
    final cacheKey =
        'thumbnail_${region.id}_${region.characterId}_$_thumbnailRefreshTimestamp';
    AppLogger.debug('Building thumbnail with cache key',
        data: {'cacheKey': cacheKey});

    return FutureBuilder<String?>(
      key: ValueKey(cacheKey), // Force widget rebuild when key changes
      future: _getThumbnailPath(),
      builder: (context, snapshot) {
        AppLogger.debug('CharacterEditPanel - 构建缩略图预览', data: {
          'hasError': snapshot.hasError,
          'hasData': snapshot.hasData,
          'connectionState': snapshot.connectionState.toString(),
        });

        if (snapshot.hasError) {
          AppLogger.error('CharacterEditPanel - 获取缩略图路径失败',
              error: snapshot.error);
          return _buildErrorWidget('加载缩略图失败');
        }

        if (!snapshot.hasData) {
          AppLogger.debug('CharacterEditPanel - 等待缩略图路径...');
          return _buildLoadingWidget();
        }

        final thumbnailPath = snapshot.data!;
        AppLogger.debug('CharacterEditPanel - 获取到缩略图路径',
            data: {'path': thumbnailPath});

        return FutureBuilder<bool>(
          future: File(thumbnailPath).exists(),
          builder: (context, existsSnapshot) {
            if (existsSnapshot.hasError) {
              AppLogger.error('CharacterEditPanel - 检查缩略图文件存在失败',
                  error: existsSnapshot.error);
              return _buildErrorWidget('检查文件失败');
            }

            if (!existsSnapshot.hasData) {
              AppLogger.debug('CharacterEditPanel - 检查缩略图文件是否存在...');
              return _buildLoadingWidget();
            }

            final exists = existsSnapshot.data!;
            AppLogger.debug('CharacterEditPanel - 缩略图文件存在',
                data: {'exists': exists});

            if (!exists) {
              AppLogger.error('CharacterEditPanel - 缩略图文件不存在',
                  data: {'path': thumbnailPath});
              return _buildErrorWidget('缩略图不存在');
            }

            return FutureBuilder<int>(
              future: File(thumbnailPath).length(),
              builder: (context, sizeSnapshot) {
                if (sizeSnapshot.hasError) {
                  AppLogger.error('CharacterEditPanel - 获取缩略图文件大小失败',
                      error: sizeSnapshot.error);
                  return _buildErrorWidget('获取文件大小失败');
                }

                if (!sizeSnapshot.hasData) {
                  AppLogger.debug('CharacterEditPanel - 获取缩略图文件大小...');
                  return _buildLoadingWidget();
                }

                final fileSize = sizeSnapshot.data!;
                AppLogger.debug('CharacterEditPanel - 缩略图文件大小',
                    data: {'fileSize': fileSize});

                if (fileSize == 0) {
                  AppLogger.error('CharacterEditPanel - 缩略图文件大小为0',
                      data: {'path': thumbnailPath});
                  return _buildErrorWidget('缩略图文件为空');
                }

                // Add cache busting parameter to force image refresh
                return Image.file(
                  File(thumbnailPath),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  // Add the timestamp as a cache-busting key
                  key: ValueKey(cacheKey),
                  // Disable caching to ensure we always load the latest version
                  cacheWidth: null,
                  cacheHeight: null,
                  errorBuilder: (context, error, stackTrace) {
                    AppLogger.error('CharacterEditPanel - 加载缩略图失败',
                        error: error,
                        stackTrace: stackTrace,
                        data: {'path': thumbnailPath});
                    return _buildErrorWidget('加载图片失败');
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildToolbar() {
    final eraseState = ref.watch(erase.eraseStateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // 撤销/重做按钮组
          _buildToolbarButtonGroup([
            _ToolbarButton(
              icon: Icons.undo,
              tooltip: '撤销',
              onPressed: eraseState.canUndo
                  ? () => ref.read(erase.eraseStateProvider.notifier).undo()
                  : null,
              shortcut: EditorShortcuts.undo,
            ),
            _ToolbarButton(
              icon: Icons.redo,
              tooltip: '重做',
              onPressed: eraseState.canRedo
                  ? () => ref.read(erase.eraseStateProvider.notifier).redo()
                  : null,
              shortcut: EditorShortcuts.redo,
            ),
          ]),

          const SizedBox(width: 16),

          // 笔刷大小控制
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.brush, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: eraseState.brushSize,
                    min: 1.0,
                    max: 50.0,
                    onChanged: (value) {
                      ref
                          .read(erase.eraseStateProvider.notifier)
                          .setBrushSize(value);
                    },
                  ),
                ),
                Text(
                  eraseState.brushSize.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 工具按钮组
          _buildToolbarButtonGroup([
            _ToolbarButton(
              icon: Icons.pan_tool,
              tooltip: '平移图像(长按alt键)',
              onPressed: () {
                ref.read(erase.eraseStateProvider.notifier).togglePanMode();
              },
              isActive: eraseState.isPanMode,
              shortcut: EditorShortcuts.togglePanMode,
            ),
            _ToolbarButton(
              icon: Icons.invert_colors,
              tooltip: '反转模式',
              onPressed: () {
                ref.read(erase.eraseStateProvider.notifier).toggleReverse();
              },
              isActive: eraseState.isReversed,
              shortcut: EditorShortcuts.toggleInvert,
            ),
            _ToolbarButton(
              icon: Icons.flip,
              tooltip: '图像反转',
              onPressed: () {
                ref.read(erase.eraseStateProvider.notifier).toggleImageInvert();
              },
              isActive: eraseState.imageInvertMode,
              shortcut: EditorShortcuts.toggleImageInvert,
            ),
            _ToolbarButton(
              icon: Icons.border_all,
              tooltip: '轮廓显示',
              onPressed: () {
                ref.read(erase.eraseStateProvider.notifier).toggleContour();
              },
              isActive: eraseState.showContour,
              shortcut: EditorShortcuts.toggleContour,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildToolbarButtonGroup(List<_ToolbarButton> buttons) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons.map((button) {
          final isFirst = buttons.indexOf(button) == 0;
          final isLast = buttons.indexOf(button) == buttons.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: Border(
                left: isFirst
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Tooltip(
              message:
                  ShortcutTooltipBuilder.build(button.tooltip, button.shortcut),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      button.icon,
                      size: 20,
                      color: button.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade700,
                    ),
                    onPressed: button.onPressed,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      backgroundColor: button.isActive
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(isFirst ? 4 : 0),
                          right: Radius.circular(isLast ? 4 : 0),
                        ),
                      ),
                    ),
                  ),
                  if (button.badgeText != null)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          button.badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 从Path提取Offset点集合并转换为可序列化格式
  List<Map<String, double>> _extractPointsFromPath(Path path) {
    List<Map<String, double>> serializablePoints = [];
    try {
      for (final metric in path.computeMetrics()) {
        if (metric.length == 0) {
          final pathBounds = path.getBounds();
          serializablePoints
              .add({'dx': pathBounds.center.dx, 'dy': pathBounds.center.dy});
          continue;
        }

        // 采样路径上的点
        final stepLength = math.max(1.0, metric.length / 100);
        for (double distance = 0;
            distance <= metric.length;
            distance += stepLength) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            serializablePoints
                .add({'dx': tangent.position.dx, 'dy': tangent.position.dy});
          }
        }

        // 确保包含最后一个点
        if (metric.length > 0) {
          final lastTangent = metric.getTangentForOffset(metric.length);
          if (lastTangent != null) {
            serializablePoints.add(
                {'dx': lastTangent.position.dx, 'dy': lastTangent.position.dy});
          }
        }
      }
    } catch (e) {
      AppLogger.error('从路径提取点集合失败', error: e);
    }
    return serializablePoints;
  }

  String _getSaveStatusText(double? progress) {
    if (progress == null) return '准备保存...';

    if (progress <= 0.2) return '初始化...';
    if (progress <= 0.4) return '处理擦除数据...';
    if (progress <= 0.6) return '保存到存储...';
    if (progress <= 0.8) return '处理图像...';
    if (progress < 1.0) return '完成保存...';
    return '保存完成';
  }

  // 获取缩略图路径
  Future<String?> _getThumbnailPath() async {
    try {
      AppLogger.debug('获取缩略图路径', data: {
        'regionId': widget.selectedRegion.id,
        'characterId': widget.selectedRegion.characterId,
      });

      // 获取characterId，如果为空则使用region的id
      final String characterId =
          widget.selectedRegion.characterId ?? widget.selectedRegion.id;

      // For debugging - also log the workId and pageId
      AppLogger.debug('缩略图上下文信息', data: {
        'workId': widget.workId,
        'pageId': widget.pageId,
        'characterId': characterId,
      });

      final path = await ref
          .read(characterCollectionProvider.notifier)
          .getThumbnailPath(characterId);

      if (path == null) {
        AppLogger.error('缩略图路径为空', data: {'characterId': characterId});
        return null;
      }

      final file = File(path);
      final exists = await file.exists();
      if (!exists) {
        AppLogger.error('缩略图文件不存在', data: {'path': path});
        return null;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.error('缩略图文件大小为0', data: {'path': path});
        return null;
      }

      return path;
    } catch (e, stack) {
      AppLogger.error('获取缩略图路径失败', error: e, stackTrace: stack, data: {
        'characterId': widget.selectedRegion.characterId,
        'regionId': widget.selectedRegion.id,
      });
      return null;
    }
  }

  // Helper method to adjust brush size
  void _handleChangeBrushSize(bool increase) {
    final eraseState = ref.read(erase.eraseStateProvider);
    final eraseNotifier = ref.read(erase.eraseStateProvider.notifier);

    double newSize = eraseState.brushSize;
    if (increase) {
      newSize += EditorShortcuts.brushSizeStep;
      if (newSize > EditorShortcuts.maxBrushSize) {
        newSize = EditorShortcuts.maxBrushSize;
      }
    } else {
      newSize -= EditorShortcuts.brushSizeStep;
      if (newSize < EditorShortcuts.minBrushSize) {
        newSize = EditorShortcuts.minBrushSize;
      }
    }

    eraseNotifier.setBrushSize(newSize);
    AppLogger.debug('调整笔刷大小', data: {
      'operation': increase ? '增加' : '减少',
      'oldSize': eraseState.brushSize,
      'newSize': newSize,
    });
  }

  void _handleEraseEnd() {
    ref.read(erase.eraseStateProvider.notifier).completePath();
  }

  void _handleEraseStart(Offset position) {
    ref.read(erase.eraseStateProvider.notifier).startPath(position);
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    ref.read(erase.eraseStateProvider.notifier).updatePath(position);
  }

  // Global keyboard event handler for all shortcuts
  bool _handleKeyboardEvent(KeyEvent event) {
    if (!mounted) return false;

    // Handle Alt key for panning
    if (event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      bool isDown = event is KeyDownEvent;
      bool isUp = event is KeyUpEvent;

      if (isDown || isUp) {
        // Pass the Alt key status to the canvas
        if (_canvasKey.currentState != null) {
          // This will be handled by the canvas's key event handler
          AppLogger.debug('Alt 键状态变更', data: {'isDown': isDown});
        }
      }

      // Don't consume the event, let it reach the canvas
      return false;
    }

    // Handle brush size adjustment with Ctrl+ and Ctrl-
    if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.equal ||
          (event.logicalKey == LogicalKeyboardKey.add)) {
        // Ctrl+ to increase brush size
        _handleChangeBrushSize(true);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.minus ||
          event.logicalKey == LogicalKeyboardKey.underscore) {
        // Ctrl- to decrease brush size
        _handleChangeBrushSize(false);
        return true;
      }
    }

    return false; // Let other handlers process this event
  }

  Future<void> _handleSave() async {
    // 验证输入
    final validation =
        _CharacterInputValidator.validateCharacter(_characterController.text);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error!)),
      );
      setState(() => _isEditing = true);
      return;
    }

    // 预先初始化保存状态
    final saveNotifier = ref.read(characterSaveNotifierProvider.notifier);
    final collectionNotifier = ref.read(characterCollectionProvider.notifier);

    try {
      // 显示确认对话框
      final confirmed = await showSaveConfirmationDialog(
        context,
        character: _characterController.text,
      );

      // 处理对话框结果
      if (confirmed != true) {
        AppLogger.debug('用户取消保存操作');
        _progressTimer?.cancel();
        saveNotifier.finishSaving();
        return;
      }

      // 立即开始保存流程，确保对话框消失后马上显示进度
      if (!mounted) {
        AppLogger.debug('组件已卸载，取消保存');
        _progressTimer?.cancel();
        saveNotifier.finishSaving();
        return;
      }

      // 立即更新UI状态，确保对话框关闭后立即显示进度
      AppLogger.debug('开始执行保存操作');
      saveNotifier.startSaving();

      // 使用 microtask 确保在视觉渲染前更新状态
      await Future.microtask(() {});
      if (!mounted) return;

      // 立即显示更清晰的进度
      saveNotifier.updateProgress(0.15);

      // 获取当前状态数据，在传给compute之前先收集所有必要数据
      final pathRenderData = ref.read(erase.pathRenderDataProvider);
      final eraseState = ref.read(erase.eraseStateProvider);
      final completedPaths = pathRenderData.completedPaths;

      // Create processing result object
      final List<Map<String, dynamic>> eraseData = [];

      // 确保传给compute的数据是可序列化的
      if (completedPaths.isNotEmpty) {
        try {
          // 使用计算工作独立线程处理路径数据，避免UI阻塞
          // 确保只传递基本数据类型到compute函数
          final pathDataFuture =
              compute<List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
            (pathsData) {
              return pathsData;
            },
            completedPaths.map((path) {
              final points = _extractPointsFromPath(path.path);
              return {
                'points': points,
                'brushSize': path.brushSize,
                'brushColor': path.brushColor.value,
              };
            }).toList(),
          );

          // 在计算完成前先更新UI进度
          saveNotifier.updateProgress(0.2);

          // 等待路径数据处理完成
          eraseData.addAll(await pathDataFuture);
        } catch (e) {
          AppLogger.error('路径数据处理失败: $e');
          // 即使处理路径失败，也继续尝试保存没有擦除数据的字符
        }
      }

      // Verify erase data is properly structured
      if (eraseData.isNotEmpty) {
        // Log detailed information about first path for debugging
        final firstPath = eraseData.first;
        final points = firstPath['points'] as List<Map<String, double>>;

        AppLogger.debug('验证擦除路径数据', data: {
          'erasePaths': eraseData.length,
          'firstPathBrushSize': firstPath['brushSize'],
          'firstPathBrushColor':
              (firstPath['brushColor'] as int).toRadixString(16),
          'firstPathPointCount': points.length,
          'firstPathSamplePoints': points
              .take(3)
              .map((p) =>
                  '(${p['dx']?.toStringAsFixed(1)},${p['dy']?.toStringAsFixed(1)})')
              .toList(),
        });
      }

      final processingOptions = ProcessingOptions(
        inverted: eraseState.imageInvertMode,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: eraseState.showContour,
        brushSize: eraseState.brushSize,
        contrast: widget.processingOptions.contrast,
        brightness: widget.processingOptions.brightness,
      );

      // 从selectedRegionProvider获取当前选区
      final selectedRegion = ref.read(selectedRegionProvider);
      if (selectedRegion == null) {
        throw const _SaveError('未选择任何区域');
      }

      // 更新选区信息，保存擦除路径数据
      final updatedRegion = selectedRegion.copyWith(
        pageId: widget.pageId,
        character: _characterController.text,
        options: processingOptions,
        isModified: false,
        eraseData: eraseData.isNotEmpty ? eraseData : null,
        erasePoints: null, // Clear old format data
      );

      // 直接开始保存流程
      Timer? progressTimer;

      try {
        // 快速响应的进度更新逻辑
        var progress = 0.25; // 更高的初始进度，更好的视觉反馈
        const updateInterval = Duration(milliseconds: 24); // 更高频率的更新

        _progressTimer = Timer.periodic(
          updateInterval,
          (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }

            // 动态调整进度增量
            double increment;
            if (progress < 0.3) {
              increment = 0.03; // 开始时更快增长
            } else if (progress < 0.7) {
              increment = 0.01; // 中间段平稳增长
            } else {
              increment = 0.005; // 接近完成时放缓
            }

            if (progress < 0.95) {
              progress += increment;
              saveNotifier.updateProgress(progress);
            }
          },
        );

        // 优化保存流程，减少感知延迟
        try {
          // 立即更新UI反馈
          saveNotifier.updateProgress(0.3);

          // 同步更新选区（这个操作很快）
          collectionNotifier.updateSelectedRegion(updatedRegion);
          saveNotifier.updateProgress(0.4);

          // 执行耗时的保存操作
          await Future.any([
            Future.sync(() async {
              await collectionNotifier.saveCurrentRegion(processingOptions);
              saveNotifier.updateProgress(0.98);
            }),
            Future.delayed(const Duration(seconds: 30))
                .then((_) => throw const _SaveError('保存操作超时')),
          ]);
        } on _SaveError {
          AppLogger.error('保存超时');
          rethrow;
        }
        saveNotifier.updateProgress(0.98);
        saveNotifier.finishSaving();
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.characterSaved);
      } catch (e) {
        final notifier = ref.read(characterSaveNotifierProvider.notifier);
        notifier.setError(e.toString());
        rethrow;
      }
    } catch (e) {
      AppLogger.error('保存字符失败', error: e);
      // 取消进度条更新计时器
      _progressTimer?.cancel();
      // 通知UI保存失败
      saveNotifier.setError(e.toString());
      // 返回编辑模式
      setState(() => _isEditing = true);
    } finally {
      _progressTimer?.cancel();
    }
  }

  void _initiateImageLoading() {
    if (widget.imageData != null) {
      setState(() {
        _loadedImage = null; // Clear current image while loading
        _imageLoadingFuture = loadAndProcessImage(
          widget.selectedRegion,
          widget.imageData!,
          widget.processingOptions,
        );
      });
    } else {
      setState(() {
        _imageLoadingFuture = Future.value(null); // Set future to null result
        _loadedImage = null;
      });
    }
  }

  // 确保在关闭或提交输入后触发主面板焦点
  void _restoreMainPanelFocus() {
    // Save the current input value before closing
    final currentText = _characterController.text;

    setState(() => _isEditing = false);
    // 延迟执行以确保状态更新后再处理焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Update the region with the new text if it changed
        final selectedRegion = ref.read(selectedRegionProvider);
        if (selectedRegion != null &&
            currentText.isNotEmpty &&
            selectedRegion.character != currentText) {
          // Update the region with the new text
          final updatedRegion = selectedRegion.copyWith(
            character: currentText,
            isModified: true,
          );
          ref
              .read(characterCollectionProvider.notifier)
              .updateSelectedRegion(updatedRegion);

          // Provide immediate visual feedback when character is changed
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('字符已更新为: $currentText'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              width: 200,
              action: SnackBarAction(
                label: '撤销',
                onPressed: () {
                  if (mounted) {
                    _characterController.text = selectedRegion.character;
                    ref
                        .read(characterCollectionProvider.notifier)
                        .updateSelectedRegion(selectedRegion);
                  }
                },
              ),
            ),
          );
        }

        // 使用单独的加延迟以确保UI渲染完成
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _mainPanelFocusNode.requestFocus();
            AppLogger.debug('重新聚焦到主面板，激活键盘快捷键');

            // 强制全局键盘事件处理的激活状态
            ServicesBinding.instance.keyboard
                .removeHandler(_handleKeyboardEvent);
            ServicesBinding.instance.keyboard.addHandler(_handleKeyboardEvent);
          }
        });
      }
    });
  }
}

/// 字符编辑面板的输入验证器
class _CharacterInputValidator {
  static _ValidationResult validateCharacter(String? input) {
    if (input == null || input.isEmpty) {
      return _ValidationResult.failure('请输入汉字');
    }

    if (input.length > 1) {
      return _ValidationResult.failure('只能输入一个汉字');
    }

    // 验证是否为汉字
    final RegExp hanziRegExp = RegExp(r'[\u4e00-\u9fa5]');
    if (!hanziRegExp.hasMatch(input)) {
      return _ValidationResult.failure('请输入有效的汉字');
    }

    return _ValidationResult.success;
  }
}

class _OpenInputIntent extends Intent {
  const _OpenInputIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SaveError implements Exception {
  final String message;
  final Exception? cause;

  const _SaveError(this.message, [this.cause]);

  @override
  String toString() => cause != null ? '$message: $cause' : message;
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _SetBrushSizeIntent extends Intent {
  final double size;
  const _SetBrushSizeIntent(this.size);
}

class _ToggleContourIntent extends Intent {
  const _ToggleContourIntent();
}

class _ToggleImageInvertIntent extends Intent {
  const _ToggleImageInvertIntent();
}

class _ToggleInvertIntent extends Intent {
  const _ToggleInvertIntent();
}

class _TogglePanModeIntent extends Intent {
  const _TogglePanModeIntent();
}

class _ToolbarButton {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final SingleActivator shortcut;
  final String? badgeText;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    required this.shortcut,
    this.badgeText,
  });
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

// 验证器
class _ValidationResult {
  static const _ValidationResult success = _ValidationResult(isValid: true);
  final bool isValid;

  final String? error;

  const _ValidationResult({
    required this.isValid,
    this.error,
  });

  static _ValidationResult failure(String error) => _ValidationResult(
        isValid: false,
        error: error,
      );
}
