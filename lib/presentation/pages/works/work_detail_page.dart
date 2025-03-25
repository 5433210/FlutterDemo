import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/models/work/work_entity.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/work_detail_provider.dart';
import '../../providers/work_image_editor_provider.dart';
import '../../providers/works_providers.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import './character_collection_page.dart';
import 'components/unified_work_detail_panel.dart';
import 'components/view_mode_image_preview.dart';
import 'components/work_images_management_view.dart';

class WorkDetailPage extends ConsumerStatefulWidget {
  final String workId;

  const WorkDetailPage({
    super.key,
    required this.workId,
  });

  @override
  ConsumerState<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends ConsumerState<WorkDetailPage>
    with WidgetsBindingObserver {
  bool _isPanelOpen = true;
  bool _hasCheckedStateRestoration = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workDetailProvider);

    return WillPopScope(
      onWillPop: () async {
        if (state.isEditing) {
          return _handleBackButton();
        }
        return true;
      },
      child: KeyboardListener(
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
  Future<bool> didPopRoute() async {
    return _handleBackButton();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkDetails();
    });
  }

  Widget _buildBody(BuildContext context, WorkDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载作品详情中...'),
      );
    }

    if (state.error != null) {
      AppLogger.error('Work detail error',
          tag: 'WorkDetailPage', error: state.error);
      return Center(
        child: ErrorDisplay(
          error: state.error!,
          onRetry: _loadWorkDetails,
        ),
      );
    }

    final work = state.isEditing ? state.editingWork : state.work;
    if (work == null) {
      return const Center(
        child: Text('作品不存在或已被删除'),
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
        // 左侧图片预览和管理
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            child: WorkImagesManagementView(
              work: work,
            ),
          ),
        ),

        // 添加面板切换按钮
        SidebarToggle(
          isOpen: _isPanelOpen,
          onToggle: () {
            setState(() {
              _isPanelOpen = !_isPanelOpen;
            });
          },
          alignRight: true,
        ),

        // 右侧面板 - 添加条件显示
        if (_isPanelOpen)
          SizedBox(
            width: 350,
            child: UnifiedWorkDetailPanel(
              key: ValueKey('form_${work.id}'),
              work: work,
              isEditing: true,
            ),
          ),
      ],
    );
  }

  Widget _buildEditModeToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);

    return Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      child: Row(
        children: [
          // 返回按钮 - 修改为返回到查看模式
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            tooltip: '返回',
            onPressed: () => _cancelEditing(), // 直接调用取消编辑功能
            visualDensity: VisualDensity.compact,
          ),

          // 标题部分 - 改为"作品编辑"
          Expanded(
            child: Row(
              children: [
                Text(
                  '作品编辑',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (state.work?.title != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '- ${state.work!.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 保持按钮靠右摆放，使用更紧凑的设计
          FilledButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('保存'),
            onPressed: state.hasChanges && !state.isSaving
                ? () => _saveChanges()
                : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _cancelEditing(),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeContent(
      BuildContext context, WorkEntity work, WorkDetailState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // 添加与工具栏高度一致的留白区域，确保与编辑模式平滑切换
              const SizedBox(height: AppSizes.spacingMedium),
              Expanded(
                child: ViewModeImagePreview(
                  images: work.images,
                  selectedIndex: state.selectedImageIndex,
                  onImageSelect: (index) =>
                      ref.read(workDetailProvider.notifier).selectImage(index),
                ),
              ),
            ],
          ),
        ),
        SidebarToggle(
          isOpen: _isPanelOpen,
          onToggle: () {
            setState(() {
              _isPanelOpen = !_isPanelOpen;
            });
          },
          alignRight: true,
        ),
        if (_isPanelOpen)
          SizedBox(
            width: 350,
            child: UnifiedWorkDetailPanel(
              work: work,
              isEditing: false,
            ),
          ),
      ],
    );
  }

  Widget _buildViewModeToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);
    final work = state.work;

    return Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      child: Row(
        children: [
          // 保持左侧的返回按钮不变
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            tooltip: '返回',
            onPressed: () => _handleBackButton(),
            visualDensity: VisualDensity.compact,
          ),

          // 标题部分
          Expanded(
            child: Row(
              children: [
                Text(
                  '作品详情',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (work != null && work.title.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '- ${work.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 按钮靠右摆放，与编辑模式保持一致的样式
          FilledButton.icon(
            onPressed: work != null ? _enterEditMode : null,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('编辑'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: work != null ? () => _navigateToExtract(work.id) : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('提取字形'),
          ),
        ],
      ),
    );
  }

  void _cancelEditing() {
    final hasChanges = ref.read(workDetailProvider).hasChanges;
    if (hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('放弃更改？'),
          content: const Text('你有未保存的更改，确定要放弃吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset the image editor state first
                ref.read(workImageEditorProvider.notifier).reset();
                ref.read(workDetailProvider.notifier).cancelEditing();
              },
              child: const Text('放弃更改'),
            ),
          ],
        ),
      );
    } else {
      // Reset the image editor state first
      ref.read(workImageEditorProvider.notifier).reset();
      ref.read(workDetailProvider.notifier).cancelEditing();
    }
  }

  Future<void> _checkForUnfinishedEditSession() async {
    if (_hasCheckedStateRestoration) return;
    _hasCheckedStateRestoration = true;

    final stateRestorationService = ref.read(stateRestorationServiceProvider);
    final hasUnfinishedSession =
        await stateRestorationService.hasUnfinishedEditSession(widget.workId);

    if (hasUnfinishedSession && mounted) {
      final shouldRestore = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('恢复未完成的编辑'),
              content: const Text('检测到上次有未保存的编辑内容。是否恢复?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('放弃'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('恢复'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldRestore && mounted) {
        await ref
            .read(workDetailProvider.notifier)
            .tryRestoreEditState(widget.workId);

        if (ref.read(workDetailProvider).isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已恢复上次的编辑状态')),
          );
        }
      }
    }
  }

  void _enterEditMode() {
    final detailNotifier = ref.read(workDetailProvider.notifier);
    final work = ref.read(workDetailProvider).work;

    if (work != null) {
      // Log the work images to verify they exist
      AppLogger.debug(
        'Entering edit mode with work',
        tag: 'WorkDetailPage',
        data: {
          'workId': work.id,
          'imageCount': work.images.length,
          'firstImageId': work.images.isNotEmpty ? work.images[0].id : 'none',
        },
      );

      // First enter edit mode to ensure the editingWork is set
      detailNotifier.enterEditMode();

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
          tag: 'WorkDetailPage',
          data: {'workId': work.id},
        );
      }
    }
  }

  Future<bool> _handleBackButton() async {
    final state = ref.read(workDetailProvider);
    final hasChanges = state.hasChanges;

    // 如果在编辑模式，先检查是否有更改
    if (state.isEditing) {
      if (hasChanges) {
        final shouldSave = await showDialog<bool?>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('保存更改？'),
            content: const Text('你有未保存的更改，是否保存？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('放弃更改'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('保存'),
              ),
            ],
          ),
        );

        if (shouldSave == null) {
          return false; // 用户点击了取消，不执行任何操作
        }

        if (shouldSave) {
          try {
            await _saveChanges();
            // 不退出页面，仅退出编辑模式
            ref.read(workDetailProvider.notifier).completeEditing();
            return false;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('保存失败: $e')),
              );
            }
            return false;
          }
        }

        // 用户选择放弃更改，取消编辑模式
        ref.read(workDetailProvider.notifier).cancelEditing();
        return false; // 不退出页面
      } else {
        // 没有更改，直接退出编辑模式
        ref.read(workDetailProvider.notifier).cancelEditing();
        return false; // 不退出页面
      }
    }

    // 在查看模式下，正常退出页面
    if (mounted) {
      Navigator.of(context).pop();
    }
    return true;
  }

  void _handleKeyboardShortcuts(KeyEvent event, WorkDetailState state) {
    if (state.isEditing) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isCtrlPressed) {
        if (event.logicalKey.keyLabel == 's' ||
            event.logicalKey.keyLabel == 'S') {
          _handleSave(state);
        }
      }
    }
  }

  void _handleSave(WorkDetailState state) {
    if (!state.hasChanges || state.isSaving) return;
    _saveChanges();
  }

  Future<void> _loadWorkDetails() async {
    await ref.read(workDetailProvider.notifier).loadWorkDetails(widget.workId);

    // Verify all work images exist
    final work = ref.read(workDetailProvider).work;
    if (work != null) {
      final storageService = ref.read(workStorageProvider);
      await storageService.verifyWorkImages(widget.workId);
    }

    _checkForUnfinishedEditSession();
  }

  void _navigateToExtract(String workId) {
    final work = ref.read(workDetailProvider).work;
    if (work != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CharacterCollectionPage(
            imageId: workId,
            workTitle: work.title,
            images: work.images
                .where((img) => img.path != null)
                .map((img) => img.path.replaceAll('\\', '/'))
                .toList(),
          ),
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    final editingWork = ref.read(workDetailProvider).editingWork;

    // 确保当前编辑状态的完整副本
    AppLogger.debug('保存前的完整作品状态', tag: 'WorkDetailPage', data: {
      'workId': editingWork?.id,
      'title': editingWork?.title,
      'author': editingWork?.author,
      'style': editingWork?.style.value,
      'tool': editingWork?.tool.value,
      'creationDate': editingWork?.creationDate.toString(),
      'remark': editingWork?.remark,
      'tagCount': editingWork?.tags.length,
      'tags': editingWork?.tags,
      'imageCount': editingWork?.images.length,
      'updateTime': editingWork?.updateTime.toString(),
    });

    AppLogger.debug('开始保存作品', tag: 'WorkDetailPage', data: {
      'workId': editingWork?.id,
      'hasImages': editingWork?.images.isNotEmpty ?? false,
      'firstImageId': editingWork?.images.isNotEmpty ?? false
          ? editingWork!.images[0].id
          : 'none',
      'title': editingWork?.title,
      'author': editingWork?.author,
      'tagCount': editingWork?.tags.length,
    });

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在保存...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Log the state of the editor before saving
      final editorState = ref.read(workImageEditorProvider);
      AppLogger.debug('作品编辑器状态', tag: 'WorkDetailPage', data: {
        'imagesCount': editorState.images.length,
        'hasPendingAdditions': editorState.hasPendingAdditions,
        'deletedImageCount': editorState.deletedImageIds.length,
      });

      // Save images first - this should handle cover generation internally
      final workImageEditorNotifier =
          ref.read(workImageEditorProvider.notifier);
      await workImageEditorNotifier.saveChanges();

      // 获取保存后的图片列表
      final savedImages = ref.read(workImageEditorProvider).images;

      // 仅在有图片时处理封面
      if (savedImages.isNotEmpty && editingWork != null) {
        final imageService = ref.read(workImageServiceProvider);
        final storageService = ref.read(workStorageProvider);

        // 检查封面是否与当前首图匹配
        final coverPath =
            storageService.getWorkCoverImportedPath(editingWork.id);
        final coverExists =
            await storageService.verifyWorkImageExists(coverPath);

        if (!coverExists) {
          AppLogger.info('保存后封面不存在，重新生成',
              tag: 'WorkDetailPage', data: {'firstImageId': savedImages[0].id});

          await imageService.updateCover(editingWork.id, savedImages[0].id);
        } else {
          AppLogger.debug('保存后封面已存在', tag: 'WorkDetailPage');
        }
      }

      // 保存作品详情之前再次确认编辑状态完整
      final currentEditingWork = ref.read(workDetailProvider).editingWork;
      AppLogger.debug('保存前最终检查', tag: 'WorkDetailPage', data: {
        'workId': currentEditingWork?.id,
        'title': currentEditingWork?.title,
        'tagCount': currentEditingWork?.tags.length,
        'tags': currentEditingWork?.tags,
      });

      // 然后保存作品详情
      final success = await ref.read(workDetailProvider.notifier).saveChanges();

      // 保存后立即记录最新状态
      final savedWork = ref.read(workDetailProvider).work;
      AppLogger.debug('保存后的完整作品状态', tag: 'WorkDetailPage', data: {
        'workId': savedWork?.id,
        'title': savedWork?.title,
        'author': savedWork?.author,
        'style': savedWork?.style.value,
        'tool': savedWork?.tool.value,
        'creationDate': savedWork?.creationDate.toString(),
        'remark': savedWork?.remark,
        'tagCount': savedWork?.tags.length,
        'tags': savedWork?.tags,
        'imageCount': savedWork?.images.length,
        'updateTime': savedWork?.updateTime.toString(),
        'saveSuccess': success,
      });

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        if (!context.mounted) return;

        // 标记作品列表需要刷新
        ref.read(worksNeedsRefreshProvider.notifier).state =
            RefreshInfo.dataChanged();

        // 修改这里 - 不要重新加载作品详情，会覆盖已保存的更改
        // await _loadWorkDetails();

        // 直接结束编辑模式，保留当前编辑的状态
        ref.read(workDetailProvider.notifier).completeEditing();

        // 强制刷新面板组件
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        '保存出错',
        tag: 'WorkDetailPage',
        error: e,
        stackTrace: stack,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存出错: $e')),
        );
      }
    }
  }
}
