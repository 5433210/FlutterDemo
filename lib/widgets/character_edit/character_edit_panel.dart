import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/character/processing_options.dart';
import '../../domain/models/character/processing_result.dart';
import '../../presentation/providers/character/character_collection_provider.dart';
import '../../presentation/providers/character/character_edit_providers.dart'
    hide PathRenderData;
import '../../presentation/providers/character/character_save_notifier.dart';
import '../../presentation/providers/character/erase_providers.dart' as erase;
import '../../presentation/providers/character/selected_region_provider.dart';
import 'character_edit_canvas.dart';
import 'dialogs/save_confirmation_dialog.dart';
import 'dialogs/shortcuts_help_dialog.dart';
import 'keyboard/shortcut_handler.dart';

/// 字符编辑面板组件
///
/// 用于编辑作品图片中的字符区域。
///
/// [image] - 要编辑的图片
/// [workId] - 作品ID
/// [pageId] - 作品图片ID
/// [onEditComplete] - 编辑完成时的回调函数
class CharacterEditPanel extends ConsumerStatefulWidget {
  final ui.Image image;
  final String workId;
  final String pageId;
  final Function(Map<String, dynamic>) onEditComplete;

  const CharacterEditPanel({
    super.key,
    required this.image,
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
  void dispose() {
    try {
      // 在 super.dispose() 之前进行所有清理工作
      final notifier = ref.read(processedImageProvider.notifier);
      notifier.clear();
      _characterController.dispose();
    } catch (e) {
      debugPrint('Character edit panel dispose error: $e');
    } finally {
      super.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _buildBottomButtons(
      SaveState saveState, ProcessedImageData processedImage) {
    final bool isSaving = saveState.isSaving || processedImage.isProcessing;
    final String? errorMessage = saveState.error ?? processedImage.error;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_isEditing)
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                  child: Text(ShortcutTooltipBuilder.build(
                    '输入汉字',
                    EditorShortcuts.openInput,
                  )),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSaving ? null : () => _handleSave(),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ShortcutTooltipBuilder.build(
                        '保存',
                        EditorShortcuts.save,
                      )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _characterController,
              decoration: const InputDecoration(
                labelText: '请输入汉字',
                hintText: '单个汉字',
                border: OutlineInputBorder(),
              ),
              maxLength: 1,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
              });
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final eraseState = ref.watch(erase.eraseStateProvider);
    final pathRenderData = ref.watch(erase.pathRenderDataProvider);
    final saveState = ref.watch(characterSaveNotifierProvider);
    final processedImage = ref.watch(processedImageProvider);
    return Column(
      children: [
        if (_isEditing) _buildCharacterInput(),
        Expanded(
          child: Stack(
            children: [
              CharacterEditCanvas(
                key: _canvasKey,
                image: widget.image,
                showOutline: eraseState.showContour,
                invertMode: eraseState.isReversed,
                imageInvertMode: eraseState.imageInvertMode,
                brushSize: eraseState.brushSize,
                brushColor: eraseState.brushColor,
                onEraseStart: _handleEraseStart,
                onEraseUpdate: _handleEraseUpdate,
                onEraseEnd: _handleEraseEnd,
              ),
              if (processedImage.isProcessing)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        _buildToolbar(),
        _buildBottomButtons(
          saveState,
          processedImage,
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final eraseState = ref.watch(erase.eraseStateProvider);
    final brushColor = eraseState.brushColor;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Tooltip(
                message:
                    ShortcutTooltipBuilder.build('撤销', EditorShortcuts.undo),
                child: IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: eraseState.canUndo
                      ? () => ref.read(erase.eraseStateProvider.notifier).undo()
                      : null,
                ),
              ),
              Tooltip(
                message:
                    ShortcutTooltipBuilder.build('重做', EditorShortcuts.redo),
                child: IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: eraseState.canRedo
                      ? () => ref.read(erase.eraseStateProvider.notifier).redo()
                      : null,
                ),
              ),
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
              Tooltip(
                message: ShortcutTooltipBuilder.build(
                    '反转模式', EditorShortcuts.toggleInvert),
                child: IconButton(
                  icon: const Icon(Icons.invert_colors),
                  onPressed: () {
                    ref.read(erase.eraseStateProvider.notifier).toggleReverse();
                  },
                  color: eraseState.isReversed
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              Tooltip(
                message: ShortcutTooltipBuilder.build(
                    '图像反转', EditorShortcuts.toggleImageInvert),
                child: IconButton(
                  icon: const Icon(Icons.flip),
                  onPressed: () {
                    ref
                        .read(erase.eraseStateProvider.notifier)
                        .toggleImageInvert();
                  },
                  color: eraseState.imageInvertMode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              Tooltip(
                message: ShortcutTooltipBuilder.build(
                    '轮廓显示', EditorShortcuts.toggleContour),
                child: IconButton(
                  icon: const Icon(Icons.border_all),
                  onPressed: () {
                    ref.read(erase.eraseStateProvider.notifier).toggleContour();
                  },
                  color: eraseState.showContour
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              Tooltip(
                message: ShortcutTooltipBuilder.build(
                    '平移模式', EditorShortcuts.togglePanMode),
                child: IconButton(
                  icon: const Icon(Icons.pan_tool),
                  onPressed: () {
                    ref.read(erase.eraseStateProvider.notifier).togglePanMode();
                  },
                  color: eraseState.isPanMode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              const VerticalDivider(),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => showShortcutsHelp(context),
                tooltip: '快捷键帮助',
              ),
            ],
          ),
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('笔刷颜色: ', style: TextStyle(fontSize: 12)),
                  Container(
                    width: 12,
                    height: 12,
                    color: brushColor,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Text('${brushColor == Colors.black ? "黑色" : "白色"} | ',
                      style: const TextStyle(fontSize: 12)),
                  Text('反转模式: ${eraseState.isReversed ? "开" : "关"} | ',
                      style: const TextStyle(fontSize: 12)),
                  Text('图像反转: ${eraseState.imageInvertMode ? "开" : "关"}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
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
    // 更新处理状态
    if (!mounted) return;
    ref.read(processedImageProvider.notifier).setProcessing(true);

    try {
      // 获取处理后的图像（带重试机制）
      final processedImage = await _RetryStrategy.run(
        operation: () async {
          final canvasState = _canvasKey.currentState;
          if (canvasState == null) {
            throw _SaveError('画布状态获取失败');
          }

          final image = await canvasState.getProcessedImage();
          if (image == null) {
            throw _SaveError('获取处理结果失败');
          }
          return image;
        },
        operationName: '图像处理',
      );
      if (!mounted) return;
// 更新处理后的图像
      ref.read(processedImageProvider.notifier).setImage(processedImage);

      // 创建处理结果
      final pathRenderData = ref.read(erase.pathRenderDataProvider);
      final eraseState = ref.read(erase.eraseStateProvider);

      final processingOptions = ProcessingOptions(
        inverted: eraseState.isReversed,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: eraseState.showContour,
      );

      // 从selectedRegionProvider获取当前选区
      final selectedRegion = ref.read(selectedRegionProvider);
      if (selectedRegion == null) {
        throw _SaveError('未选择任何区域');
      }

      // 获取处理所需的画布状态
      final canvasState = _canvasKey.currentState;
      if (canvasState == null) {
        throw _SaveError('无法获取画布状态');
      }

      // 获取图像数据（带重试机制）
      final imageData = await _RetryStrategy.run(
        operation: () async {
          final data =
              await processedImage.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) {
            throw _SaveError('图像数据获取失败');
          }
          return data;
        },
        operationName: '图像数据转换',
      );

      final uint8List = imageData.buffer.asUint8List();

      // 更新选区信息
      final updatedRegion = selectedRegion.copyWith(
        pageId: widget.pageId,
        character: _characterController.text,
        options: processingOptions,
      );

      // 创建处理结果
      final processingResult = ProcessingResult(
        originalCrop: uint8List,
        binaryImage: uint8List,
        thumbnail: uint8List,
        boundingBox: selectedRegion.rect,
      );

      // 保存（带重试机制）
      await _RetryStrategy.run(
        operation: () async {
          if (!mounted) throw _SaveError('操作已取消');

          final saveNotifier = ref.read(characterSaveNotifierProvider.notifier);
          final result = await saveNotifier.save(
              updatedRegion, processingResult, widget.workId);

          if (!mounted) throw _SaveError('操作已取消');

          if (!result.isSuccess) {
            throw _SaveError(result.error?.toString() ?? '保存失败');
          }

          return result;
        },
        operationName: '保存字符',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: Colors.green,
          ),
        );
        // 更新选区状态
        final collectionNotifier =
            ref.read(characterCollectionProvider.notifier);
        collectionNotifier.selectRegion(updatedRegion.id);

        widget.onEditComplete({
          'paths': pathRenderData.completedPaths ?? [],
          'processingOptions': processingOptions,
          'character': _characterController.text,
        });
      }
    } catch (e) {
      if (!mounted) return;

      try {
        final errorMessage = e is _SaveError ? e.toString() : '保存失败：$e';
        ref.read(processedImageProvider.notifier).setError(errorMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _handleSave,
            ),
          ),
        );
      } catch (e) {
        // 忽略在显示错误消息时可能发生的异常
      }
    } finally {
      if (mounted) {
        ref.read(processedImageProvider.notifier).setProcessing(false);
      }
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
