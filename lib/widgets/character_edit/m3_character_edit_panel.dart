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
import '../../l10n/app_localizations.dart';
import '../../presentation/providers/character/character_collection_provider.dart';
import '../../presentation/providers/character/character_edit_providers.dart';
import '../../presentation/providers/character/character_refresh_notifier.dart';
import '../../presentation/providers/character/character_save_notifier.dart';
import '../../presentation/providers/character/erase_providers.dart' as erase;
import '../../presentation/providers/character/selected_region_provider.dart';
import '../../presentation/widgets/image/cached_image.dart';
import 'character_edit_canvas.dart';
import 'dialogs/m3_save_confirmation_dialog.dart';
import 'keyboard/shortcut_handler.dart';

/// M3 Character Edit Panel
///
/// A Material 3 implementation of the character edit panel for editing characters in a work image.
///
/// [selectedRegion] - The selected character region
/// [imageData] - The image data
/// [processingOptions] - The processing options
/// [workId] - The work ID
/// [pageId] - The work page ID
/// [onEditComplete] - Callback function when editing is complete
class M3CharacterEditPanel extends ConsumerStatefulWidget {
  final CharacterRegion selectedRegion;
  final Uint8List? imageData;
  final ProcessingOptions processingOptions;
  final String workId;
  final String pageId;
  final Function(Map<String, dynamic>) onEditComplete;

  const M3CharacterEditPanel({
    super.key,
    required this.selectedRegion,
    required this.imageData,
    required this.processingOptions,
    required this.workId,
    required this.pageId,
    required this.onEditComplete,
  });

  @override
  ConsumerState<M3CharacterEditPanel> createState() =>
      _M3CharacterEditPanelState();
}

/// Character edit panel input validator
class _CharacterInputValidator {
  static _ValidationResult validateCharacter(
      String? input, AppLocalizations l10n) {
    if (input == null || input.isEmpty) {
      return _ValidationResult.failure(l10n.characterEditPleaseEnterCharacter);
    }

    if (input.length > 1) {
      return _ValidationResult.failure(l10n.characterEditOnlyOneCharacter);
    }

    // Validate if it's a Chinese character
    final RegExp hanziRegExp = RegExp(r'[\u4e00-\u9fa5]');
    if (!hanziRegExp.hasMatch(input)) {
      return _ValidationResult.failure(l10n.characterEditValidChineseCharacter);
    }

    return _ValidationResult.success;
  }
}

class _M3CharacterEditPanelState extends ConsumerState<M3CharacterEditPanel> {
  final GlobalKey<CharacterEditCanvasState> _canvasKey = GlobalKey();
  final TextEditingController _characterController = TextEditingController();
  Timer? _progressTimer;
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _mainPanelFocusNode = FocusNode();
  bool _isEditing = false;
  bool _isNewSelection = false;

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
          // Ensure focus on input field
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
        // Pan mode toggle removed
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
        // Pan mode shortcut removed
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen(characterRefreshNotifierProvider, (previous, current) {
      if (previous != current) {
        final refreshEvent =
            ref.read(characterRefreshNotifierProvider.notifier).lastEventType;
        if (refreshEvent == RefreshEventType.characterSaved) {
          // Force refresh of the thumbnail by updating the timestamp
          setState(() {
            _thumbnailRefreshTimestamp = DateTime.now().millisecondsSinceEpoch;
          });
          AppLogger.debug('Triggering thumbnail refresh',
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
            focusNode: _mainPanelFocusNode,
            autofocus: true,
            onKeyEvent: (FocusNode node, KeyEvent event) {
              AppLogger.debug('Received keyboard event', data: {
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
            child: _buildContent(l10n),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(M3CharacterEditPanel oldWidget) {
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
      _mainPanelFocusNode.dispose();
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
      //Set invert mode based on actual conditions
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

  Widget _buildBottomButtons(SaveState saveState, AppLocalizations l10n) {
    final bool isSaving = saveState.isSaving;
    final String? errorMessage = saveState.error;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: colorScheme.error,
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
                FilledButton.tonalIcon(
                  onPressed: isSaving
                      ? null
                      : () {
                          setState(() => _isEditing = true);
                          // Ensure focus on input field
                          Future.delayed(const Duration(milliseconds: 50), () {
                            _inputFocusNode.requestFocus();
                          });
                        },
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(ShortcutTooltipBuilder.build(
                    l10n.characterEditInputCharacter,
                    EditorShortcuts.openInput,
                  )),
                ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: isSaving ? null : () => _handleSave(),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(ShortcutTooltipBuilder.build(
                  l10n.save,
                  EditorShortcuts.save,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInput(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.edit, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                l10n.characterEditInputCharacter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close,
                    size: 16, color: colorScheme.onSurfaceVariant),
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
            style: TextStyle(fontSize: 24, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: l10n.characterEditInputHint,
              counterText: '',
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) => _restoreMainPanelFocus(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _restoreMainPanelFocus(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(60, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _restoreMainPanelFocus(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(60, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final saveState = ref.watch(characterSaveNotifierProvider);
    final eraseState = ref.watch(erase.eraseStateProvider);
    final processedImageNotifier = ref.watch(processedImageProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FutureBuilder<ui.Image?>(
          future: _imageLoadingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(l10n);
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              processedImageNotifier.setError(
                  '${l10n.characterEditImageLoadError}: ${snapshot.error ?? l10n.characterEditUnknownError}');
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: colorScheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      l10n.characterEditImageLoadFailed,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error ?? l10n.characterEditUnknownError}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
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
                // Top toolbar
                _buildToolbar(l10n),

                // Main content area
                Expanded(
                  child: Stack(
                    children: [
                      // Canvas
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

                      // Thumbnail preview
                      if (region != null)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: _buildThumbnailPreview(l10n),
                        ),

                      // Character input floating window
                      if (_isEditing)
                        Positioned(
                          left: 16,
                          top: 16,
                          child: _buildCharacterInput(l10n),
                        ),
                    ],
                  ),
                ),

                // Bottom buttons
                _buildBottomButtons(saveState, l10n),
              ],
            );
          },
        ),

        // Saving overlay
        if (saveState.isSaving)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                elevation: 4,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getSaveStatusText(saveState.progress, l10n),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                      ),
                      if (saveState.progress != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: saveState.progress!,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
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
                                    color: colorScheme.onSurfaceVariant,
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
          ),
      ],
    );
  }

  Widget _buildErrorWidget(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 4),
            Text(
              message,
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build loading state
  Widget _buildLoadingState(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.characterEditLoadingImage,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildThumbnailPreview(AppLocalizations l10n) {
    // Check if region exists, if not don't show thumbnail
    final region = ref.watch(selectedRegionProvider);
    if (region == null) {
      AppLogger.debug(
          'CharacterEditPanel - No selected region, not showing thumbnail');
      return const SizedBox.shrink();
    }

    // Check if region's characterId exists, if not it's a new selection, don't show thumbnail
    if (region.characterId == null) {
      AppLogger.debug(
          'CharacterEditPanel - Region not associated with character, not showing thumbnail');
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
        AppLogger.debug('CharacterEditPanel - Building thumbnail preview',
            data: {
              'hasError': snapshot.hasError,
              'hasData': snapshot.hasData,
              'connectionState': snapshot.connectionState.toString(),
            });

        if (snapshot.hasError) {
          AppLogger.error('CharacterEditPanel - Failed to get thumbnail path',
              error: snapshot.error);
          return _buildErrorWidget(l10n.characterEditThumbnailLoadFailed);
        }

        if (!snapshot.hasData) {
          AppLogger.debug('CharacterEditPanel - Waiting for thumbnail path...');
          return _buildLoadingWidget();
        }

        final thumbnailPath = snapshot.data!;
        AppLogger.debug('CharacterEditPanel - Got thumbnail path',
            data: {'path': thumbnailPath});

        return FutureBuilder<bool>(
          future: File(thumbnailPath).exists(),
          builder: (context, existsSnapshot) {
            if (existsSnapshot.hasError) {
              AppLogger.error(
                  'CharacterEditPanel - Failed to check if thumbnail file exists',
                  error: existsSnapshot.error);
              return _buildErrorWidget(l10n.characterEditThumbnailCheckFailed);
            }

            if (!existsSnapshot.hasData) {
              AppLogger.debug(
                  'CharacterEditPanel - Checking if thumbnail file exists...');
              return _buildLoadingWidget();
            }

            final exists = existsSnapshot.data!;
            AppLogger.debug('CharacterEditPanel - Thumbnail file exists',
                data: {'exists': exists});

            if (!exists) {
              AppLogger.error(
                  'CharacterEditPanel - Thumbnail file does not exist',
                  data: {'path': thumbnailPath});
              return _buildErrorWidget(l10n.characterEditThumbnailNotFound);
            }

            return FutureBuilder<int>(
              future: File(thumbnailPath).length(),
              builder: (context, sizeSnapshot) {
                if (sizeSnapshot.hasError) {
                  AppLogger.error(
                      'CharacterEditPanel - Failed to get thumbnail file size',
                      error: sizeSnapshot.error);
                  return _buildErrorWidget(
                      l10n.characterEditThumbnailSizeError);
                }

                if (!sizeSnapshot.hasData) {
                  AppLogger.debug(
                      'CharacterEditPanel - Getting thumbnail file size...');
                  return _buildLoadingWidget();
                }

                final fileSize = sizeSnapshot.data!;
                AppLogger.debug('CharacterEditPanel - Thumbnail file size',
                    data: {'fileSize': fileSize});

                if (fileSize == 0) {
                  AppLogger.error(
                      'CharacterEditPanel - Thumbnail file size is 0',
                      data: {'path': thumbnailPath});
                  return _buildErrorWidget(l10n.characterEditThumbnailEmpty);
                }

                final colorScheme = Theme.of(context).colorScheme;
                // Add cache busting parameter to force image refresh
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedImage(
                    path: thumbnailPath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    // Add the timestamp as a cache-busting key
                    key: ValueKey(cacheKey),
                    errorBuilder: (context, error, stackTrace) {
                      AppLogger.error(
                          'CharacterEditPanel - Failed to load thumbnail',
                          error: error,
                          stackTrace: stackTrace,
                          data: {'path': thumbnailPath});
                      return _buildErrorWidget(
                          l10n.characterEditThumbnailLoadError);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildToolbar(AppLocalizations l10n) {
    final eraseState = ref.watch(erase.eraseStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        mainAxisSize: MainAxisSize.max, // Ensure the row takes the full width
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Undo/redo button group
          _buildToolbarButtonGroup([
            _ToolbarButton(
              icon: Icons.undo,
              tooltip: l10n.characterEditUndo,
              onPressed: eraseState.canUndo
                  ? () => ref.read(erase.eraseStateProvider.notifier).undo()
                  : null,
              shortcut: EditorShortcuts.undo,
            ),
            _ToolbarButton(
              icon: Icons.redo,
              tooltip: l10n.characterEditRedo,
              onPressed: eraseState.canRedo
                  ? () => ref.read(erase.eraseStateProvider.notifier).redo()
                  : null,
              shortcut: EditorShortcuts.redo,
            ),
          ]),

          const SizedBox(width: 16), // Brush size control
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.brush,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: eraseState.brushSize,
                    min: 1.0,
                    max: 50.0,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.surfaceContainerHighest,
                    thumbColor: colorScheme.primary,
                    onChanged: (value) {
                      ref
                          .read(erase.eraseStateProvider.notifier)
                          .setBrushSize(value);
                    },
                  ),
                ),
                Container(
                  width: 28, // Fixed width for the text display
                  alignment: Alignment.center,
                  child: Text(
                    eraseState.brushSize.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Tool button group
          _buildToolbarButtonGroup([
            _ToolbarButton(
              icon: Icons.invert_colors,
              tooltip: l10n.characterEditInvertMode,
              onPressed: () {
                ref.read(erase.eraseStateProvider.notifier).toggleReverse();
              },
              isActive: eraseState.isReversed,
              shortcut: EditorShortcuts.toggleInvert,
            ),
            _ToolbarButton(
              icon: Icons.flip,
              tooltip: l10n.characterEditImageInvert,
              onPressed: () {
                ref.read(erase.eraseStateProvider.notifier).toggleImageInvert();
              },
              isActive: eraseState.imageInvertMode,
              shortcut: EditorShortcuts.toggleImageInvert,
            ),
            _ToolbarButton(
              icon: Icons.border_all,
              tooltip: l10n.characterEditShowContour,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons.map((button) {
          final isFirst = buttons.indexOf(button) == 0;
          final isLast = buttons.indexOf(button) == buttons.length - 1;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
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
                          ? colorScheme.primary
                          : button.onPressed == null
                              ? colorScheme.onSurfaceVariant
                                  .withAlpha(97) // ~38% opacity
                              : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: button.onPressed,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          button.isActive ? colorScheme.primaryContainer : null,
                      foregroundColor: button.isActive
                          ? colorScheme.onPrimaryContainer
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(isFirst ? 8 : 2),
                          right: Radius.circular(isLast ? 8 : 2),
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

  // Extract points from Path and convert to serializable format
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

        // Sample points on the path
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

        // Ensure the last point is included
        if (metric.length > 0) {
          final lastTangent = metric.getTangentForOffset(metric.length);
          if (lastTangent != null) {
            serializablePoints.add(
                {'dx': lastTangent.position.dx, 'dy': lastTangent.position.dy});
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to extract points from path', error: e);
    }
    return serializablePoints;
  }

  String _getSaveStatusText(double? progress, AppLocalizations l10n) {
    if (progress == null) return l10n.characterEditPreparingSave;

    if (progress <= 0.2) return l10n.characterEditInitializing;
    if (progress <= 0.4) return l10n.characterEditProcessingEraseData;
    if (progress <= 0.6) return l10n.characterEditSavingToStorage;
    if (progress <= 0.8) return l10n.characterEditProcessingImage;
    if (progress < 1.0) return l10n.characterEditCompletingSave;
    return l10n.characterEditSaveComplete;
  }

  // Get thumbnail path
  Future<String?> _getThumbnailPath() async {
    try {
      AppLogger.debug('Getting thumbnail path', data: {
        'regionId': widget.selectedRegion.id,
        'characterId': widget.selectedRegion.characterId,
      });

      // Get characterId, if empty use region id
      final String characterId =
          widget.selectedRegion.characterId ?? widget.selectedRegion.id;

      // For debugging - also log the workId and pageId
      AppLogger.debug('Thumbnail context info', data: {
        'workId': widget.workId,
        'pageId': widget.pageId,
        'characterId': characterId,
      });

      final path = await ref
          .read(characterCollectionProvider.notifier)
          .getThumbnailPath(characterId);

      if (path == null) {
        AppLogger.error('Thumbnail path is null',
            data: {'characterId': characterId});
        return null;
      }

      final file = File(path);
      final exists = await file.exists();
      if (!exists) {
        AppLogger.error('Thumbnail file does not exist', data: {'path': path});
        return null;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.error('Thumbnail file size is 0', data: {'path': path});
        return null;
      }

      return path;
    } catch (e, stack) {
      AppLogger.error('Failed to get thumbnail path',
          error: e,
          stackTrace: stack,
          data: {
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
    AppLogger.debug('Adjusting brush size', data: {
      'operation': increase ? 'increase' : 'decrease',
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
          AppLogger.debug('Alt key state changed', data: {'isDown': isDown});
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
    final l10n = AppLocalizations.of(context);

    // Validate input
    final validation = _CharacterInputValidator.validateCharacter(
        _characterController.text, l10n);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error!)),
      );
      setState(() => _isEditing = true);
      return;
    }

    // Initialize save state
    final saveNotifier = ref.read(characterSaveNotifierProvider.notifier);
    final collectionNotifier = ref.read(characterCollectionProvider.notifier);

    try {
      // Show confirmation dialog
      final confirmed = await showM3SaveConfirmationDialog(
        context,
        character: _characterController.text,
      );

      // Handle dialog result
      if (confirmed != true) {
        AppLogger.debug('User canceled save operation');
        _progressTimer?.cancel();
        saveNotifier.finishSaving();
        return;
      }

      // Start save process immediately, ensure progress is shown after dialog dismissal
      if (!mounted) {
        AppLogger.debug('Component unmounted, canceling save');
        _progressTimer?.cancel();
        saveNotifier.finishSaving();
        return;
      }

      // Immediately update UI state, ensure progress is shown after dialog closes
      AppLogger.debug('Starting save operation');
      saveNotifier.startSaving();

      // Use microtask to ensure state is updated before visual rendering
      await Future.microtask(() {});
      if (!mounted) return;

      // Immediately show clearer progress
      saveNotifier.updateProgress(0.15);

      // Get current state data, collect all necessary data before passing to compute
      final pathRenderData = ref.read(erase.pathRenderDataProvider);
      final eraseState = ref.read(erase.eraseStateProvider);
      final completedPaths = pathRenderData.completedPaths;

      // Create processing result object
      final List<Map<String, dynamic>> eraseData = [];

      // Ensure data passed to compute is serializable
      if (completedPaths.isNotEmpty) {
        try {
          // Use compute to process path data in a separate thread, avoid UI blocking
          // Ensure only basic data types are passed to compute function
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
                'brushColor': path.brushColor.toARGB32(),
              };
            }).toList(),
          );

          // Update UI progress before computation completes
          saveNotifier.updateProgress(0.2);

          // Wait for path data processing to complete
          eraseData.addAll(await pathDataFuture);
        } catch (e) {
          AppLogger.error('Path data processing failed: $e');
          // Even if path processing fails, continue trying to save character without erase data
        }
      }

      // Verify erase data is properly structured
      if (eraseData.isNotEmpty) {
        // Log detailed information about first path for debugging
        final firstPath = eraseData.first;
        final points = firstPath['points'] as List<Map<String, double>>;

        AppLogger.debug('Validating erase path data', data: {
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

      // Get current selection from selectedRegionProvider
      final selectedRegion = ref.read(selectedRegionProvider);
      if (selectedRegion == null) {
        throw _SaveError(l10n.characterEditNoRegionSelected);
      }

      // Update region information, save erase path data
      final updatedRegion = selectedRegion.copyWith(
        pageId: widget.pageId,
        character: _characterController.text,
        options: processingOptions,
        isModified: false,
        eraseData: eraseData.isNotEmpty ? eraseData : null,
        erasePoints: null, // Clear old format data
      );

      // Start save process directly
      try {
        // Quick response progress update logic
        var progress = 0.25; // Higher initial progress, better visual feedback
        const updateInterval =
            Duration(milliseconds: 24); // Higher frequency updates

        _progressTimer = Timer.periodic(
          updateInterval,
          (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }

            // Dynamically adjust progress increment
            double increment;
            if (progress < 0.3) {
              increment = 0.03; // Faster growth at start
            } else if (progress < 0.7) {
              increment = 0.01; // Steady growth in middle
            } else {
              increment = 0.005; // Slow down near completion
            }

            if (progress < 0.95) {
              progress += increment;
              saveNotifier.updateProgress(progress);
            }
          },
        );

        // Optimize save process, reduce perceived delay
        try {
          // Immediately update UI feedback
          saveNotifier.updateProgress(0.3);

          // Synchronously update selection (this operation is fast)
          collectionNotifier.updateSelectedRegion(updatedRegion);
          saveNotifier.updateProgress(0.4);

          // Execute time-consuming save operation
          await Future.any([
            Future.sync(() async {
              await collectionNotifier.saveCurrentRegion(processingOptions);
              saveNotifier.updateProgress(0.98);
            }),
            Future.delayed(const Duration(seconds: 30))
                .then((_) => throw _SaveError(l10n.characterEditSaveTimeout)),
          ]);
        } on _SaveError {
          AppLogger.error('Save timeout');
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
      AppLogger.error('Failed to save character', error: e);
      // Cancel progress timer
      _progressTimer?.cancel();
      // Notify UI of save failure
      saveNotifier.setError(e.toString());
      // Return to edit mode
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

  // Ensure main panel focus is triggered after closing or submitting input
  void _restoreMainPanelFocus() {
    // Save the current input value before closing
    final currentText = _characterController.text;

    setState(() => _isEditing = false);
    // Delay execution to ensure state is updated before handling focus
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
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.characterEditCharacterUpdated),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              width: 200,
              action: SnackBarAction(
                label: l10n.characterEditUndo,
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

        // Use separate delay to ensure UI rendering is complete
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _mainPanelFocusNode.requestFocus();
            AppLogger.debug(
                'Refocusing to main panel, activating keyboard shortcuts');

            // Force global keyboard event handler activation state
            ServicesBinding.instance.keyboard
                .removeHandler(_handleKeyboardEvent);
            ServicesBinding.instance.keyboard.addHandler(_handleKeyboardEvent);
          }
        });
      }
    });
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

  const _SaveError(this.message);

  @override
  String toString() => message;
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

class _UndoIntent extends Intent {
  const _UndoIntent();
}

// Validator
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
