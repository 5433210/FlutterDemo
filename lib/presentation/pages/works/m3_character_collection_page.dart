import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../utils/cross_navigation_helper.dart';
import '../../widgets/character_collection/m3_delete_confirmation_dialog.dart';
import '../../widgets/character_collection/m3_image_preview_panel.dart';
import '../../widgets/character_collection/m3_navigation_bar.dart';
import '../../widgets/character_collection/m3_right_panel.dart';
import '../../widgets/common/persistent_resizable_panel.dart';

// Keyboard shortcuts definition
class CollectionShortcuts {
  // Tool selection shortcuts
  static const panTool =
      SingleActivator(LogicalKeyboardKey.keyV, control: true);
  static const selectTool =
      SingleActivator(LogicalKeyboardKey.keyB, control: true);

  // Edit operations
  static const delete = SingleActivator(LogicalKeyboardKey.keyD, control: true);

  // Navigation
  static const nextPage = SingleActivator(LogicalKeyboardKey.arrowRight);
  static const prevPage = SingleActivator(LogicalKeyboardKey.arrowLeft);

  // Others
  static const escape = SingleActivator(LogicalKeyboardKey.escape);
  static const enter = SingleActivator(LogicalKeyboardKey.enter);
  static const save = SingleActivator(LogicalKeyboardKey.keyS, control: true);
}

class M3CharacterCollectionPage extends ConsumerStatefulWidget {
  final String workId;
  final String initialPageId;
  final String? initialCharacterId;

  const M3CharacterCollectionPage({
    super.key,
    required this.workId,
    required this.initialPageId,
    this.initialCharacterId,
  });

  @override
  ConsumerState<M3CharacterCollectionPage> createState() =>
      _M3CharacterCollectionPageState();
}

// Loading overlay component
class M3LoadingOverlay extends StatelessWidget {
  const M3LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.scrim.withAlpha(128),
      child: Center(
        child: Card(
          elevation: 4,
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(width: 16),
                Text(
                  l10n.characterCollectionProcessing,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _M3CharacterCollectionPageState
    extends ConsumerState<M3CharacterCollectionPage> {
  bool _isImageValid = false;
  String? _imageError;
  double _panelWidth = 400; // Track the right panel width

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(characterCollectionProvider);
    final imageState = ref.watch(workImageProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          // Tool selection shortcuts
          CollectionShortcuts.panTool: _PanToolIntent(),
          CollectionShortcuts.selectTool: _SelectToolIntent(),

          // Edit operations
          CollectionShortcuts.delete: _DeleteIntent(),

          // Navigation
          CollectionShortcuts.nextPage: _NextPageIntent(),
          CollectionShortcuts.prevPage: _PreviousPageIntent(),

          // Others
          CollectionShortcuts.escape: _EscapeIntent(),
          CollectionShortcuts.save: _SaveIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _PanToolIntent: CallbackAction<_PanToolIntent>(
              onInvoke: (intent) => _changeTool(Tool.pan),
            ),
            _SelectToolIntent: CallbackAction<_SelectToolIntent>(
              onInvoke: (intent) => _changeTool(Tool.select),
            ),
            _DeleteIntent: CallbackAction<_DeleteIntent>(
              onInvoke: (intent) => _deleteSelectedRegions(),
            ),
            _NextPageIntent: CallbackAction<_NextPageIntent>(
              onInvoke: (intent) => _navigateToNextPage(),
            ),
            _PreviousPageIntent: CallbackAction<_PreviousPageIntent>(
              onInvoke: (intent) => _navigateToPreviousPage(),
            ),
            _EscapeIntent: CallbackAction<_EscapeIntent>(
              onInvoke: (intent) => _clearSelections(),
            ),
            _SaveIntent: CallbackAction<_SaveIntent>(
              onInvoke: (intent) => _saveSelectedRegions(),
            ),
          },
          child: Scaffold(
            body: Column(
              children: [
                // Navigation bar
                M3NavigationBar(
                  workId: widget.workId,
                  onBack: () => _onBackPressed(),
                ),

                // Main content
                Expanded(
                  child: Stack(
                    children: [
                      if (_isImageValid)
                        Row(
                          children: [
                            // Left image preview area
                            const Expanded(
                              flex: 6,
                              child: M3ImagePreviewPanel(),
                            ), // Right panel with ResizablePanel
                            PersistentResizablePanel(
                              panelId: 'character_collection_right_panel',
                              initialWidth: _panelWidth,
                              minWidth: 350,
                              maxWidth: 1000,
                              isLeftPanel: false,
                              onWidthChanged: (width) {
                                setState(() {
                                  _panelWidth = width;
                                });
                              },
                              child: M3RightPanel(workId: widget.workId),
                            ),
                          ],
                        )
                      else
                        _buildImageErrorState(),

                      // Use Stack to display loading overlay and error messages
                      if (collectionState.loading ||
                          collectionState.processing ||
                          imageState.loading)
                        const Positioned.fill(child: M3LoadingOverlay()),

                      // Error message
                      if (collectionState.error != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 20,
                          child: _buildErrorMessage(collectionState.error!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Load initial data when the page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear previous selection data
      ref.read(characterCollectionProvider.notifier).clearSelectedRegions();
      ref.read(selectedRegionProvider.notifier).clearRegion();

      _loadInitialData();
    });
  }

  // Build error message display
  Widget _buildErrorMessage(String error) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l10n.characterCollectionError(error),
          style: TextStyle(color: colorScheme.onError),
        ),
      ),
    );
  }

  // Display image loading error state
  Widget _buildImageErrorState() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withAlpha(50)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image,
                size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              l10n.characterCollectionImageLoadError,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _imageError ?? l10n.characterCollectionImageInvalid,
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(204)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.characterCollectionRetry),
              onPressed: _loadInitialData,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.characterCollectionReturnToDetails),
            ),
          ],
        ),
      ),
    );
  }

  // Implement tool switching method
  void _changeTool(Tool tool) {
    ref.read(toolModeProvider.notifier).setMode(tool);
    AppLogger.debug('Switching tool mode', data: {'tool': tool.toString()});
  }

  // Check for unsaved changes, show confirmation dialog
  Future<bool> _checkUnsavedChanges() async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(characterCollectionProvider);
    final notifier = ref.read(characterCollectionProvider.notifier);

    AppLogger.debug('Checking unsaved changes state', data: {
      'hasUnsavedChanges': state.hasUnsavedChanges,
      'regionCount': state.regions.length,
      'currentId': state.currentId,
      'isAdjusting': state.isAdjusting,
      'hasUnsavedRegions': state.regions.any((r) => r.isModified),
    });

    if (state.hasUnsavedChanges) {
      // Show confirmation dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.characterCollectionUnsavedChanges),
          content: Text(l10n.characterCollectionUnsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                // User confirms leaving, clear all modification markers
                notifier.markAllAsSaved();
                AppLogger.debug('Force marking all regions as saved');

                Navigator.of(context).pop(true); // Confirm leaving
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.characterCollectionLeave),
            ),
          ],
        ),
      );

      return result ?? false;
    }

    // No unsaved changes, can leave directly
    return true;
  }

  // Clear all selections
  void _clearSelections() {
    ref.read(characterCollectionProvider.notifier).clearSelectedRegions();
  }

  // Delete selected regions
  Future<void> _deleteSelectedRegions() async {
    final selectedIds = ref
        .read(characterCollectionProvider)
        .regions
        .where((e) => e.isSelected)
        .map((e) => e.id)
        .toList();

    // Check if there are selected regions
    if (selectedIds.isEmpty) {
      return;
    }

    // Use M3DeleteConfirmationDialog to show confirmation dialog (supports Enter to confirm and Esc to cancel)
    bool shouldDelete = await M3DeleteConfirmationDialog.show(
      context,
      count: selectedIds.length,
      isBatch: selectedIds.length > 1,
    );

    if (shouldDelete) {
      // Execute delete operation, also deleting image files in the file system
      ref
          .read(characterCollectionProvider.notifier)
          .deleteBatchRegions(selectedIds);
    }
  }

  // Load character data
  Future<void> _loadCharacterData() async {
    try {
      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            widget.workId,
            pageId: widget.initialPageId,
          );
      if (widget.initialCharacterId != null) {
        // 先选中区域
        ref.read(characterCollectionProvider.notifier).selectRegion(
              widget.initialCharacterId!,
            );

        // 然后设置为adjusting状态
        ref.read(characterCollectionProvider.notifier).setAdjusting(true);

        AppLogger.debug('从字符管理页进入集字功能页，设置区域为adjusting状态', data: {
          'characterId': widget.initialCharacterId,
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load character data',
          tag: 'M3CharacterCollectionPage',
          error: e,
          data: {'workId': widget.workId, 'pageId': widget.initialPageId});
    }
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    setState(() {
      _isImageValid = false;
      _imageError = null;
    });

    try {
      await _loadWorkImage();

      if (_isImageValid) {
        await _loadCharacterData();
      }
    } catch (e) {
      AppLogger.error('Failed to load initial data',
          tag: 'M3CharacterCollectionPage',
          error: e,
          data: {'workId': widget.workId, 'pageId': widget.initialPageId});
    }
  }

  // Load work image
  Future<void> _loadWorkImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final imageProvider = ref.read(workImageProvider.notifier);
      final imageService = ref.read(workImageServiceProvider);

      // First try to get image data
      final imageBytes = await imageService.getWorkPageImage(
          widget.workId, widget.initialPageId);

      if (imageBytes == null || imageBytes.isEmpty) {
        setState(() {
          _isImageValid = false;
          _imageError = l10n.characterCollectionImageLoadError;
        });
        return;
      }

      // Validate image data
      try {
        // Validate image data before loading
        bool isValid = await _validateImageData(imageBytes);

        if (!isValid) {
          setState(() {
            _isImageValid = false;
            _imageError = l10n.characterCollectionImageInvalid;
          });
          return;
        }

        // If image is valid, load it into state
        await imageProvider.loadWorkImage(
          widget.workId,
          widget.initialPageId,
        );

        // Update character extraction state
        ref
            .read(characterCollectionProvider.notifier)
            .setCurrentPageImage(imageBytes);

        setState(() {
          _isImageValid = true;
          _imageError = null;
        });
      } catch (e) {
        AppLogger.error('Image validation failed',
            tag: 'M3CharacterCollectionPage',
            error: e,
            data: {
              'workId': widget.workId,
              'pageId': widget.initialPageId,
              'imageLength': imageBytes.length
            });

        setState(() {
          _isImageValid = false;
          _imageError = 'Image data validation failed: ${e.toString()}';
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load work image',
          tag: 'M3CharacterCollectionPage',
          error: e,
          data: {'workId': widget.workId, 'pageId': widget.initialPageId});

      setState(() {
        _isImageValid = false;
        _imageError = 'Failed to load image: ${e.toString()}';
      });
    }
  }

  // Navigate to next page
  void _navigateToNextPage() async {
    final imageState = ref.read(workImageProvider);

    if (imageState.hasNext) {
      // First execute page switch
      await ref.read(workImageProvider.notifier).nextPage();

      // Get updated state after switching
      final updatedState = ref.read(workImageProvider);

      // Load selection data for the new page
      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            updatedState.workId,
            pageId: updatedState.currentPageId,
          );

      // Clear selections
      ref.read(characterCollectionProvider.notifier).clearSelectedRegions();
    }
  }

  // Navigate to previous page
  void _navigateToPreviousPage() async {
    final imageState = ref.read(workImageProvider);

    if (imageState.hasPrevious) {
      // First execute page switch
      await ref.read(workImageProvider.notifier).previousPage();

      // Get updated state after switching
      final updatedState = ref.read(workImageProvider);

      // Load selection data for the new page
      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            updatedState.workId,
            pageId: updatedState.currentPageId,
          );

      // Clear selections
      ref.read(characterCollectionProvider.notifier).clearSelectedRegions();
    }
  }

  // Handle back button press
  void _onBackPressed() {
    _checkUnsavedChanges().then((canPop) {
      if (canPop && mounted) {
        CrossNavigationHelper.handleBackNavigation(context, ref);
      }
    });
  }

  // Check for unsaved changes
  Future<bool> _onWillPop() async {
    return await _checkUnsavedChanges();
  }

  // Save all modified regions
  Future<void> _saveSelectedRegions() async {}

  // Validate image data
  Future<bool> _validateImageData(Uint8List imageData) async {
    if (imageData.length < 100) {
      // Image too small, might be invalid data
      return false;
    }

    try {
      // Check if image header matches common image formats
      final header = imageData.sublist(0, math.min(12, imageData.length));

      // Check PNG header
      if (header.length >= 8 &&
          header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47) {
        return true;
      }

      // Check JPEG header
      if (header.length >= 3 &&
          header[0] == 0xFF &&
          header[1] == 0xD8 &&
          header[2] == 0xFF) {
        return true;
      }

      // Can add other image format checks here

      // If doesn't match any known format, try using image service to validate
      final imageProcessor = ref.read(imageProcessorProvider);
      return imageProcessor.validateImageData(imageData);
    } catch (e) {
      AppLogger.error('Error validating image data',
          tag: 'M3CharacterCollectionPage', error: e);
      return false;
    }
  }
}

class _NextPageIntent extends Intent {
  const _NextPageIntent();
}

// Add Intent types
class _PanToolIntent extends Intent {
  const _PanToolIntent();
}

class _PreviousPageIntent extends Intent {
  const _PreviousPageIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _SelectToolIntent extends Intent {
  const _SelectToolIntent();
}
