import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/models/work/work_entity.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/work_detail_provider.dart';
import '../../providers/work_image_editor_provider.dart';
import '../../providers/works_providers.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/persistent_resizable_panel.dart';
import '../../widgets/common/persistent_sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import './m3_character_collection_page.dart';
import 'components/m3_unified_work_detail_panel.dart';
import 'components/m3_view_mode_image_preview.dart';
import 'components/m3_work_detail_navigation_bar.dart';
import 'components/work_images_management_view.dart';

/// Material 3 version of the work detail page
class M3WorkDetailPage extends ConsumerStatefulWidget {
  /// ID of the work to display
  final String workId;

  /// Optional initial page ID to select
  final String? initialPageId;

  const M3WorkDetailPage({
    super.key,
    required this.workId,
    this.initialPageId,
  });

  @override
  ConsumerState<M3WorkDetailPage> createState() => _M3WorkDetailPageState();
}

class _M3WorkDetailPageState extends ConsumerState<M3WorkDetailPage>
    with WidgetsBindingObserver {
  bool _isPanelOpen = true;
  bool _hasCheckedStateRestoration = false;
  double _panelWidth = 350; // 添加面板宽度状态

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workDetailProvider);

    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (keyEvent) => _handleKeyboardShortcuts(keyEvent, state),
        child: PageLayout(
          toolbar: state.isEditing
              ? _buildEditModeToolbar(context, state)
              : _buildViewModeToolbar(context, state),
          body: _buildBody(context, state),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_hasCheckedStateRestoration &&
        mounted) {
      // Add mounted check
      _checkForUnfinishedEditSession();
      _hasCheckedStateRestoration = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use addPostFrameCallback to ensure the widget is fully built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadWorkDetails();
      }
    });
  }

  Widget _buildBody(BuildContext context, WorkDetailState state) {
    final l10n = AppLocalizations.of(context);

    if (state.isLoading) {
      return Center(
        child: LoadingIndicator(message: l10n.loading),
      );
    }

    if (state.error != null) {
      AppLogger.error('Work detail error',
          tag: 'M3WorkDetailPage', error: state.error);
      return Center(
        child: ErrorDisplay(
          error: state.error!,
          onRetry: _loadWorkDetails,
        ),
      );
    }

    final work = state.isEditing ? state.editingWork : state.work;
    if (work == null) {
      return Center(
        child: Text(l10n.noWorks),
      );
    }

    return state.isEditing
        ? _buildEditModeContent(context, state, work)
        : _buildViewModeContent(context, work, state);
  }

  Widget _buildEditModeContent(
      BuildContext context, WorkDetailState state, WorkEntity work) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side image preview and management
        Expanded(
          child: WorkImagesManagementView(
            work: work,
          ),
        ),

        // Add panel toggle button
        PersistentSidebarToggle(
          sidebarId: 'work_detail_panel',
          defaultIsOpen: _isPanelOpen,
          onToggle: (isOpen) {
            setState(() {
              _isPanelOpen = isOpen;
            });
          },
          alignRight: true,
        ),

        // Right side panel - conditionally shown
        if (_isPanelOpen)
          PersistentResizablePanel(
            panelId: 'work_detail_right_panel',
            initialWidth: _panelWidth,
            minWidth: 280,
            maxWidth: 500,
            isLeftPanel: false,
            onWidthChanged: (width) {
              setState(() {
                _panelWidth = width;
              });
            },
            child: M3UnifiedWorkDetailPanel(
              key: ValueKey('form_${work.id}'),
              work: work,
              isEditing: true,
            ),
          ),
      ],
    );
  }

  Widget _buildEditModeToolbar(BuildContext context, WorkDetailState state) {
    return M3WorkDetailNavigationBar(
      title: state.editingWork?.title ?? '',
      isEditing: true,
      hasChanges: state.hasChanges,
      onBack: () => _handleBackButton(),
      onCancel: _handleCancelEdit,
      onSave: state.hasChanges ? _saveChanges : null,
    );
  }

  Widget _buildViewModeContent(
      BuildContext context, WorkEntity work, WorkDetailState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: M3ViewModeImagePreview(
            images: work.images,
            selectedIndex: state.selectedImageIndex,
            onImageSelect: (index) =>
                ref.read(workDetailProvider.notifier).selectImage(index),
          ),
        ),
        PersistentSidebarToggle(
          sidebarId: 'work_detail_panel_management',
          defaultIsOpen: _isPanelOpen,
          onToggle: (isOpen) {
            setState(() {
              _isPanelOpen = isOpen;
            });
          },
          alignRight: true,
        ),
        if (_isPanelOpen)
          PersistentResizablePanel(
            panelId: 'work_detail_management_panel',
            initialWidth: _panelWidth,
            minWidth: 280,
            maxWidth: 500,
            isLeftPanel: false,
            onWidthChanged: (width) {
              setState(() {
                _panelWidth = width;
              });
            },
            child: M3UnifiedWorkDetailPanel(
              work: work,
              isEditing: false,
              onToggleFavorite: () =>
                  ref.read(workDetailProvider.notifier).toggleFavorite(),
            ),
          ),
      ],
    );
  }

  Widget _buildViewModeToolbar(BuildContext context, WorkDetailState state) {
    final work = state.work;
    return M3WorkDetailNavigationBar(
      title: work?.title ?? '',
      isEditing: false,
      hasChanges: false,
      onBack: () {
        // Check if we can safely pop
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: false).maybePop();
        }
      },
      onEdit: _enterEditMode,
      onExtract: work != null && work.images.isNotEmpty
          ? () => _navigateToCharacterExtraction(work)
          : null,
      showExtractButton: work != null && work.images.isNotEmpty,
    );
  }

  void _checkForUnfinishedEditSession() {
    // Check if there's an unfinished edit session
    if (!mounted) return; // Add mounted check

    final state = ref.read(workDetailProvider);
    if (state.hasChanges && state.isEditing) {
      AppLogger.info(
        'Detected unfinished edit session',
        tag: 'M3WorkDetailPage',
        data: {'workId': widget.workId},
      );
      // Could show a dialog asking if user wants to restore
    }
  }

  void _enterEditMode() {
    final detailNotifier = ref.read(workDetailProvider.notifier);
    final work = ref.read(workDetailProvider).work;

    if (work != null) {
      // Log the work images to verify they exist
      AppLogger.debug(
        'Entering edit mode with work',
        tag: 'M3WorkDetailPage',
        data: {
          'workId': work.id,
          'imageCount': work.images.length,
          'firstImageId': work.images.isNotEmpty ? work.images[0].id : 'none',
        },
      );

      // First enter edit mode to ensure the editingWork is set
      detailNotifier.startEditing();

      // Ensure image editor state is properly initialized
      if (work.images.isNotEmpty) {
        // Reset the editor provider state
        ref.read(workImageInitializedProvider.notifier).state = false;
        ref.read(workImageEditorProvider.notifier).reset();

        // Initialize with a microtask to ensure it happens after the current frame
        Future.microtask(() {
          // Verify the providers still exist
          if (!ref.exists(workImageEditorProvider)) return;
          if (!context.mounted) return;

          // Initialize the image editor with work images
          final editorNotifier = ref.read(workImageEditorProvider.notifier);
          editorNotifier.initialize(work.images);

          // Set selected index after initialization
          final selectedIndex = ref.read(workDetailProvider).selectedImageIndex;
          editorNotifier.updateSelectedIndex(selectedIndex);
        });
      } else {
        AppLogger.warning(
          'Entering edit mode with no images',
          tag: 'M3WorkDetailPage',
          data: {'workId': work.id},
        );
      }
    }
  }

  Future<bool> _handleBackButton() async {
    final state = ref.read(workDetailProvider);
    final l10n = AppLocalizations.of(context);

    if (state.isEditing && state.hasChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.cancel),
          content: Text(l10n.unsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );

      if (result == true) {
        ref.read(workDetailProvider.notifier).cancelEditing();
        return true;
      }
      return false;
    } else if (state.isEditing) {
      ref.read(workDetailProvider.notifier).cancelEditing();
      return true;
    }

    return true;
  }

  void _handleCancelEdit() {
    _handleBackButton();
  }

  void _handleKeyboardShortcuts(KeyEvent keyEvent, WorkDetailState state) {
    if (keyEvent is! KeyDownEvent) return;

    // Handle Escape key to cancel edit mode or navigate back
    if (keyEvent.logicalKey == LogicalKeyboardKey.escape) {
      if (state.isEditing) {
        _handleBackButton();
      } else {
        Navigator.of(context, rootNavigator: false).maybePop();
      }
      return;
    }

    // Handle Ctrl+S to save changes
    if (keyEvent.logicalKey == LogicalKeyboardKey.keyS &&
        HardwareKeyboard.instance.isControlPressed &&
        state.isEditing &&
        state.hasChanges) {
      _saveChanges();
      return;
    }

    // Handle Ctrl+E to enter edit mode
    if (keyEvent.logicalKey == LogicalKeyboardKey.keyE &&
        HardwareKeyboard.instance.isControlPressed &&
        !state.isEditing) {
      _enterEditMode();
      return;
    }
  }

  Future<void> _loadWorkDetails() async {
    await ref.read(workDetailProvider.notifier).loadWorkDetails(widget.workId);

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    // Verify all work images exist
    final work = ref.read(workDetailProvider).work;
    if (work != null) {
      final storageService = ref.read(workStorageProvider);
      await storageService.verifyWorkImages(widget.workId);

      // Check mounted again after another async operation
      if (!mounted) return;

      if (work.images.isNotEmpty) {
        for (var image in work.images) {
          if (image.id == widget.initialPageId) {
            ref.read(workDetailProvider.notifier).selectImage(
                  work.images.indexOf(image),
                );
            break;
          }
        }
      }
    }

    _checkForUnfinishedEditSession();
  }

  void _navigateToCharacterExtraction(WorkEntity work) {
    final l10n = AppLocalizations.of(context);

    if (work.images.isNotEmpty) {
      try {
        final selectedIndex = ref.read(workDetailProvider).selectedImageIndex;
        final initialPageId = selectedIndex < work.images.length
            ? work.images[selectedIndex].id
            : work.images.first.id;

        // Verify image before navigation
        final storageService = ref.read(workStorageProvider);
        storageService
            .verifyWorkImageExists(
                storageService.getImportedPath(work.id, initialPageId))
            .then((exists) {
          if (!exists && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(l10n.imageLoadError(l10n.imageFileNotExists))),
            );
            return;
          }

          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => M3CharacterCollectionPage(
                  workId: work.id,
                  initialPageId: initialPageId,
                ),
              ),
            );
          }
        });
      } catch (e, stack) {
        AppLogger.error(
          'Error navigating to character extraction page',
          tag: 'M3WorkDetailPage',
          error: e,
          stackTrace: stack,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.extractionError}: ${e.toString()}')),
          );
        }
      }
    } else {
      // Handle case where there are no images
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noImages)),
      );
    }
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context);
    final editingWork = ref.read(workDetailProvider).editingWork;

    // Ensure complete copy of current edit state
    AppLogger.info('准备保存作品更改', tag: 'M3WorkDetailPage', data: {
      'workId': editingWork?.id,
      'title': editingWork?.title,
      'author': editingWork?.author,
      'style': editingWork?.style,
      'tool': editingWork?.tool,
      'remark': editingWork?.remark,
      'tagCount': editingWork?.tags.length,
      'tags': editingWork?.tags,
      'imageCount': editingWork?.images.length,
      'updateTime': editingWork?.updateTime.toString(),
    });

    try {
      // First save the images if they've been edited
      if (ref.exists(workImageEditorProvider)) {
        final imageEditorState = ref.read(workImageEditorProvider);
        final imageEditorNotifier = ref.read(workImageEditorProvider.notifier);

        AppLogger.info('图片编辑器状态检查', tag: 'M3WorkDetailPage', data: {
          'hasPendingAdditions': imageEditorState.hasPendingAdditions,
          'deletedImageIds': imageEditorState.deletedImageIds,
          'imageCount': imageEditorState.images.length,
          'currentOrder': imageEditorState.images
              .map((img) => '${img.id}(${img.index})')
              .take(5)
              .toList(),
        });

        // Always save - 不再检查是否有变化，确保顺序调整能被保存
        AppLogger.info('开始保存图片更改', tag: 'M3WorkDetailPage');
        await imageEditorNotifier.saveChanges();
        AppLogger.info('图片更改保存完成', tag: 'M3WorkDetailPage');
      }

      // Get saved images list
      final savedImages = ref.read(workImageEditorProvider).images;

      AppLogger.info('保存后的图片状态', tag: 'M3WorkDetailPage', data: {
        'savedImageCount': savedImages.length,
        'savedOrder': savedImages
            .map((img) => '${img.id}(${img.index})')
            .take(5)
            .toList(),
      });

      // Only process cover when there are images
      if (savedImages.isNotEmpty && editingWork != null) {
        final imageService = ref.read(workImageServiceProvider);
        final storageService = ref.read(workStorageProvider);

        // Check if cover matches current first image
        final coverPath =
            storageService.getWorkCoverImportedPath(editingWork.id);
        final coverExists =
            await storageService.verifyWorkImageExists(coverPath);

        // 只有在封面不存在时才重新生成，避免不必要的错误
        if (!coverExists) {
          AppLogger.info('封面不存在，尝试重新生成', tag: 'M3WorkDetailPage', data: {
            'firstImageId': savedImages[0].id,
            'coverPath': coverPath,
          });

          try {
            await imageService.updateCover(editingWork.id, savedImages[0].id);
            AppLogger.info('封面重新生成成功', tag: 'M3WorkDetailPage');
          } catch (e) {
            AppLogger.warning('封面重新生成失败，但不影响图片保存',
                tag: 'M3WorkDetailPage',
                error: e,
                data: {
                  'firstImageId': savedImages[0].id,
                  'reason': '可能是顺序调整时图片文件路径问题',
                });
            // 不要抛出异常，封面生成失败不应该影响图片顺序保存
          }
        } else {
          AppLogger.info('封面已存在，跳过更新', tag: 'M3WorkDetailPage', data: {
            'coverPath': coverPath,
          });
        }
      }

      // Then save work details
      AppLogger.info('开始保存作品详情', tag: 'M3WorkDetailPage');
      final success = await ref.read(workDetailProvider.notifier).saveChanges();

      // 验证保存结果 - 重新加载并检查
      if (success && editingWork != null) {
        await ref
            .read(workDetailProvider.notifier)
            .loadWorkDetails(editingWork.id);
        final reloadedWork = ref.read(workDetailProvider).work;

        AppLogger.info('保存验证 - 重新加载作品', tag: 'M3WorkDetailPage', data: {
          'workId': reloadedWork?.id,
          'reloadedImageCount': reloadedWork?.images.length,
          'reloadedOrder': reloadedWork?.images
              .map((img) => '${img.id}(${img.index})')
              .take(5)
              .toList(),
        });
      }

      // Log latest state after save
      final savedWork = ref.read(workDetailProvider).work;
      AppLogger.info('保存完成状态', tag: 'M3WorkDetailPage', data: {
        'workId': savedWork?.id,
        'title': savedWork?.title,
        'author': savedWork?.author,
        'style': savedWork?.style,
        'tool': savedWork?.tool,
        'remark': savedWork?.remark,
        'tagCount': savedWork?.tags.length,
        'tags': savedWork?.tags,
        'imageCount': savedWork?.images.length,
        'updateTime': savedWork?.updateTime.toString(),
        'saveSuccess': success,
      });

      // Notify works list to refresh
      ref.read(worksNeedsRefreshProvider.notifier).state =
          RefreshInfo.dataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.saveSuccess : l10n.saveFailure),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error saving work',
        tag: 'M3WorkDetailPage',
        error: e,
        stackTrace: stack,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.saveFailure}: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
