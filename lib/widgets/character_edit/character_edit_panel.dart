import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../application/services/image/character_image_processor.dart';
import '../../domain/models/character/character_region.dart';
import '../../domain/models/character/processing_options.dart';
import '../../domain/models/character/processing_result.dart';
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

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  final GlobalKey<CharacterEditCanvasState> _canvasKey = GlobalKey();
  final TextEditingController _characterController = TextEditingController();
  bool _isEditing = false;

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
        _OpenInputIntent:
            CallbackAction(onInvoke: (_) => setState(() => _isEditing = true)),
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
        EditorShortcuts.save: _SaveIntent(),
        EditorShortcuts.undo: _UndoIntent(),
        EditorShortcuts.redo: _RedoIntent(),
        EditorShortcuts.openInput: _OpenInputIntent(),
        EditorShortcuts.toggleInvert: _ToggleInvertIntent(),
        EditorShortcuts.toggleImageInvert: _ToggleImageInvertIntent(),
        EditorShortcuts.toggleContour: _ToggleContourIntent(),
        EditorShortcuts.togglePanMode: _TogglePanModeIntent(),
        for (var i = 0; i < EditorShortcuts.brushSizePresets.length; i++)
          EditorShortcuts.brushSizePresets[i]:
              _SetBrushSizeIntent(EditorShortcuts.brushSizes[i]),
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

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: Focus(
          autofocus: true,
          child: _buildContent(),
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
      _loadedImage?.dispose();
      _characterController.dispose();
      // Consider clearing providers related to THIS panel instance if needed
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
    _initiateImageLoading();
    // Clear erase state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(erase.eraseStateProvider.notifier).clear();
    });
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
                  onPressed:
                      isSaving ? null : () => setState(() => _isEditing = true),
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
                onPressed: () => setState(() => _isEditing = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _characterController,
            autofocus: true,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(
              hintText: '请输入',
              counterText: '',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => setState(() => _isEditing = false),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final saveState = ref.watch(characterSaveNotifierProvider);
    final eraseState = ref.watch(erase.eraseStateProvider);
    final processedImageNotifier = ref.watch(processedImageProvider.notifier);

    return FutureBuilder<ui.Image?>(
      future: _imageLoadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          processedImageNotifier
              .setError('图像加载失败: ${snapshot.error ?? "未知错误"}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  '无法加载或处理字符图像',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error ?? "未知错误"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
            const SizedBox(height: 4),
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
      print('CharacterEditPanel - 没有选中的区域，不显示缩略图');
      return const SizedBox.shrink();
    }

    // 检查region的characterId是否存在，如果不存在说明是新建选区，不显示缩略图
    if (region.characterId == null) {
      print('CharacterEditPanel - 区域未关联字符，不显示缩略图');
      return const SizedBox.shrink();
    }

    return FutureBuilder<String?>(
      future: _getThumbnailPath(),
      builder: (context, snapshot) {
        print('CharacterEditPanel - 构建缩略图预览');

        if (snapshot.hasError) {
          print('CharacterEditPanel - 获取缩略图路径失败: ${snapshot.error}');
          return _buildErrorWidget('加载缩略图失败');
        }

        if (!snapshot.hasData) {
          print('CharacterEditPanel - 等待缩略图路径...');
          return _buildLoadingWidget();
        }

        final thumbnailPath = snapshot.data!;
        print('CharacterEditPanel - 获取到缩略图路径: $thumbnailPath');

        return FutureBuilder<bool>(
          future: File(thumbnailPath).exists(),
          builder: (context, existsSnapshot) {
            if (existsSnapshot.hasError) {
              print(
                  'CharacterEditPanel - 检查缩略图文件存在失败: ${existsSnapshot.error}');
              return _buildErrorWidget('检查文件失败');
            }

            if (!existsSnapshot.hasData) {
              print('CharacterEditPanel - 检查缩略图文件是否存在...');
              return _buildLoadingWidget();
            }

            final exists = existsSnapshot.data!;
            print(
                'CharacterEditPanel - 缩略图文件${exists ? "存在" : "不存在"}: $thumbnailPath');

            if (!exists) {
              print('CharacterEditPanel - 缩略图文件不存在');
              return _buildErrorWidget('缩略图不存在');
            }

            return FutureBuilder<int>(
              future: File(thumbnailPath).length(),
              builder: (context, sizeSnapshot) {
                if (sizeSnapshot.hasError) {
                  print(
                      'CharacterEditPanel - 获取缩略图文件大小失败: ${sizeSnapshot.error}');
                  return _buildErrorWidget('获取文件大小失败');
                }

                if (!sizeSnapshot.hasData) {
                  print('CharacterEditPanel - 获取缩略图文件大小...');
                  return _buildLoadingWidget();
                }

                final fileSize = sizeSnapshot.data!;
                print('CharacterEditPanel - 缩略图文件大小: $fileSize 字节');

                if (fileSize == 0) {
                  print('CharacterEditPanel - 缩略图文件大小为0');
                  return _buildErrorWidget('缩略图文件为空');
                }

                // Add cache busting parameter to force image refresh
                return Image.file(
                  File(thumbnailPath),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  // Add the timestamp as a cache-busting key
                  key: ValueKey(
                      'thumbnail_${region.id}_$_thumbnailRefreshTimestamp'),
                  // Disable caching to ensure we always load the latest version
                  cacheWidth: null,
                  cacheHeight: null,
                  errorBuilder: (context, error, stackTrace) {
                    print('CharacterEditPanel - 加载缩略图失败: $error');
                    print('$stackTrace');
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
              child: IconButton(
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
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(isFirst ? 4 : 0),
                      right: Radius.circular(isLast ? 4 : 0),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 创建缩略图的辅助方法
  Future<Uint8List?> _createThumbnail(Uint8List imageData) async {
    try {
      // 解码图像
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 计算合适的缩略图大小
      final double ratio = 100 / math.max(image.width, image.height);
      final int targetWidth = (image.width * ratio).round();
      final int targetHeight = (image.height * ratio).round();

      // 使用图像包重新调整大小
      final img.Image? decodedImage = img.decodeImage(imageData);
      if (decodedImage == null) return null;

      final img.Image thumbnail = img.copyResize(
        decodedImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      AppLogger.error('创建缩略图失败', error: e);
      return null;
    }
  }

  // 获取缩略图路径
  Future<String?> _getThumbnailPath() async {
    try {
      print('获取缩略图路径');

      // 获取characterId，如果为空则使用region的id
      final String characterId =
          widget.selectedRegion.characterId ?? widget.selectedRegion.id;
      print('使用的characterId: $characterId');

      final path = await ref
          .read(characterCollectionProvider.notifier)
          .getThumbnailPath(characterId);
      print('获取到缩略图路径: $path');

      if (path == null) {
        print('缩略图路径为空');
        return null;
      }

      final file = File(path);
      final exists = await file.exists();
      if (!exists) {
        print('缩略图文件不存在');
        return null;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        print('缩略图文件大小为0');
        return null;
      }

      return path;
    } catch (e) {
      print('获取缩略图路径失败: $e');
      AppLogger.error('获取缩略图路径失败', error: e, data: {
        'characterId': widget.selectedRegion.characterId,
        'regionId': widget.selectedRegion.id,
      });
      return null;
    }
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

  Future<void> _handleSave() async {
    // 输入验证
    final validation =
        _CharacterInputValidator.validateCharacter(_characterController.text);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error!)),
      );
      setState(() {
        _isEditing = true;
      });
      return;
    }

    // 显示确认对话框
    final confirmed = await showSaveConfirmationDialog(
      context,
      character: _characterController.text,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      // 获取处理后的图像（带重试机制）
      final processedImage = await _RetryStrategy.run(
        operation: () async {
          final canvasState = _canvasKey.currentState;
          if (canvasState == null) {
            throw _SaveError('无法获取画布状态');
          }
          return await canvasState.getProcessedImage();
        },
        operationName: '图像处理',
      );
      if (!mounted) return;

      // 确保画布状态有效并且图像已处理
      if (processedImage == null) {
        throw _SaveError('处理后的图像为空');
      }

      // 获取图像数据（带重试机制）
      final imageData = await _RetryStrategy.run(
        operation: () async {
          return await processedImage.toByteData(
              format: ui.ImageByteFormat.png);
        },
        operationName: '图像数据转换',
      );

      if (imageData == null) {
        throw _SaveError('图像数据转换失败');
      }

      final uint8List = imageData.buffer.asUint8List();

      AppLogger.debug('保存图像数据', data: {
        'imageDataLength': uint8List.length,
        'imageWidth': processedImage.width,
        'imageHeight': processedImage.height,
      });

      // 创建处理结果
      final pathRenderData = ref.read(erase.pathRenderDataProvider);
      final eraseState = ref.read(erase.eraseStateProvider);

      final processingOptions = ProcessingOptions(
        inverted: eraseState.isReversed,
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
        throw _SaveError('未选择任何区域');
      }

      // 更新选区信息
      final updatedRegion = selectedRegion.copyWith(
        pageId: widget.pageId,
        character: _characterController.text,
        options: processingOptions,
        isModified: true,
      );

      // 创建缩略图
      final thumbnail = await _createThumbnail(uint8List);

      // 创建处理结果对象，包含所有必要的图像数据
      final processingResult = ProcessingResult(
        originalCrop: uint8List,
        binaryImage: uint8List,
        thumbnail: thumbnail ?? uint8List,
        boundingBox: selectedRegion.rect,
      );

      // 验证处理结果是否有效
      if (!processingResult.isValid) {
        AppLogger.error('处理结果无效', data: {
          'originalCropLength': processingResult.originalCrop.length,
          'binaryImageLength': processingResult.binaryImage.length,
          'thumbnailLength': processingResult.thumbnail.length,
          'hasBoundingBox': processingResult.boundingBox != null,
        });
        throw _SaveError('处理结果无效，无法保存');
      }

      // 保存（带重试机制）
      final collectionNotifier = ref.read(characterCollectionProvider.notifier);

      // Update the region first
      collectionNotifier.updateSelectedRegion(updatedRegion);

      // Now save the current region with the processed image data
      await collectionNotifier.saveCurrentRegion(
        imageData: processingResult,
      );

      // Notify about character saved event
      ref
          .read(characterRefreshNotifierProvider.notifier)
          .notifyEvent(RefreshEventType.characterSaved);

      if (mounted) {
        // Force thumbnail to update right after saving
        setState(() {
          _thumbnailRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存成功: ${_characterController.text}'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if this was a new character or an edit of an existing one
        final isNewCharacter = widget.selectedRegion.characterId == null;

        widget.onEditComplete({
          'character': _characterController.text,
          'characterId': updatedRegion.characterId,
          'isNewCharacter': isNewCharacter, // Add this flag
        });
      }
    } catch (e) {
      if (!mounted) return;

      try {
        final errorMessage = e is _SaveError ? e.toString() : '保存失败：$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        // 双重异常捕获
        debugPrint('显示错误信息时发生异常: $e');
      }
    }
  }

  void _initiateImageLoading() {
    if (widget.imageData != null) {
      setState(() {
        // Cancel previous future?
        _loadedImage = null; // Clear current image while loading
        _imageLoadingFuture = _loadAndProcessImage(
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

  Future<ui.Image?> _loadAndProcessImage(
    CharacterRegion region,
    Uint8List imageData,
    ProcessingOptions processingOptions,
  ) async {
    try {
      final imageProcessor = ref.read(characterImageProcessorProvider);
      final preview = await imageProcessor.previewProcessing(
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

class _OpenInputIntent extends Intent {}

class _RedoIntent extends Intent {}

// 重试机制
class _RetryStrategy {
  static const int maxAttempts = 3;
  static const Duration delayBetweenAttempts = Duration(seconds: 1);

  static Future<T> run<T>({
    required Future<T> Function() operation,
    String? operationName,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) {
          throw _SaveError(
            '${operationName ?? '操作'}失败，已重试$maxAttempts次',
            e is Exception ? e : Exception(e.toString()),
          );
        }
        await Future.delayed(delayBetweenAttempts);
      }
    }
  }
}

class _SaveError implements Exception {
  final String message;
  final Exception? cause;

  _SaveError(this.message, [this.cause]);

  @override
  String toString() => cause != null ? '$message: $cause' : message;
}

// Intent类定义
class _SaveIntent extends Intent {}

class _SetBrushSizeIntent extends Intent {
  final double size;
  const _SetBrushSizeIntent(this.size);
}

class _ToggleContourIntent extends Intent {}

class _ToggleImageInvertIntent extends Intent {}

class _ToggleInvertIntent extends Intent {}

class _TogglePanModeIntent extends Intent {}

class _ToolbarButton {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final SingleActivator shortcut;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    required this.shortcut,
  });
}

class _UndoIntent extends Intent {}

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
