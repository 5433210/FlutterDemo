import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/models/work/work_entity.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/work_detail_provider.dart';
import '../../providers/works_providers.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/forms/work_detail_edit_form.dart' as forms;
import '../../widgets/page_layout.dart';
import '../../widgets/tag_editor.dart';
import './character_collection_page.dart';
import 'components/work_detail_info_panel.dart';
import 'components/work_image_preview.dart';
import 'components/work_images_management_view.dart';
import 'components/work_tabs.dart';

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

    final toolbar = state.isEditing
        ? _buildEditModeToolbar(context, state)
        : _buildViewModeToolbar(context, state);

    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (keyEvent) => _handleKeyboardShortcuts(keyEvent, state),
      child: PageLayout(
        toolbar: toolbar,
        body: _buildBody(context, state),
      ),
    );
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
        : _buildViewModeContent(context, work);
  }

  Widget _buildCharAnnotationPanel(WorkEntity work) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('集字信息', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已提取字形: ${work.collectedChars.length}个',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (work.collectedChars.isEmpty)
                  const Text('暂无提取的字形，可点击上方"提取字形"按钮进行提取')
                else
                  const Text('点击上方"提取字形"按钮查看详情'),
              ],
            ),
          ),
        ),
      ],
    );
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

        // 右侧面板 - 包含标签页和表单
        SizedBox(
          width: 350,
          child: Column(
            children: [
              WorkTabs(
                selectedIndex: ref.watch(workDetailTabIndexProvider),
                onTabSelected: (index) {
                  final currentTabIndex = ref.read(workDetailTabIndexProvider);
                  if (currentTabIndex == 0 && index != 0) {
                    _savePendingFormChanges();
                  }
                  ref.read(workDetailTabIndexProvider.notifier).state = index;
                },
              ),
              Expanded(
                child: IndexedStack(
                  index: ref.watch(workDetailTabIndexProvider),
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      child: forms.WorkDetailEditForm(
                        key: ValueKey('form_${work.id}'),
                        work: work,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      child: _buildTagsEditPanel(context, state, work),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      child: _buildCharAnnotationPanel(work),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditModeToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      child: Row(
        children: [
          Text(
            '编辑作品',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.work?.title != null) ...[
            const SizedBox(width: 8),
            Text(
              '- ${state.work!.title}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('保存'),
            onPressed: state.hasChanges && !state.isSaving
                ? () => _saveChanges()
                : null,
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            child: const Text('取消'),
            onPressed: () => _cancelEditing(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsEditPanel(
      BuildContext context, WorkDetailState state, WorkEntity work) {
    final theme = Theme.of(context);
    final notifier = ref.read(workDetailProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签管理', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        TagEditor(
          tags: work.tags,
          suggestedTags: const ['行书', '楷书', '隶书', '草书', '真迹', '拓片', '碑帖', '字帖'],
          onTagsChanged: (updatedTags) {
            notifier.updateWorkTags(updatedTags);
            AppLogger.debug(
              '标签已更新',
              tag: 'WorkDetailPage',
              data: {'tags': updatedTags},
            );
          },
          chipColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
        ),
      ],
    );
  }

  Widget _buildViewModeContent(BuildContext context, WorkEntity work) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: WorkImagePreview(
            work: work,
            isEditing: false,
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
            child: WorkDetailInfoPanel(work: work),
          ),
      ],
    );
  }

  Widget _buildViewModeToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);
    final work = state.work;

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            tooltip: '返回',
            onPressed: _handleBackButton,
          ),
          Text(
            '作品详情',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (work != null && work.title.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '- ${work.title}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(width: AppSizes.spacingMedium),
          FilledButton.icon(
            onPressed: work != null ? _enterEditMode : null,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('编辑'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          FilledButton.tonal(
            onPressed: work != null ? () => _navigateToExtract(work.id) : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                ref.read(workDetailProvider.notifier).cancelEditing();
              },
              child: const Text('放弃更改'),
            ),
          ],
        ),
      );
    } else {
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
    ref.read(workDetailProvider.notifier).enterEditMode();
    ref.read(workDetailTabIndexProvider.notifier).state = 0;
  }

  void _handleBackButton() {
    Navigator.of(context).pop(true);
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
    AppLogger.debug('开始保存作品', tag: 'WorkDetailPage', data: {
      'workId': editingWork?.id,
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
      final success = await ref.read(workDetailProvider.notifier).saveChanges();
      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        if (!context.mounted) return;

        ref.read(worksNeedsRefreshProvider.notifier).state =
            RefreshInfo.dataChanged();
        ref.read(workDetailProvider.notifier).completeEditing();
        ref.read(workDetailTabIndexProvider.notifier).state = 0;
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

  void _savePendingFormChanges() {
    final editingWork = ref.read(workDetailProvider).editingWork;
    if (editingWork != null) {
      ref.read(workDetailProvider.notifier).markAsChanged();
    }
  }
}
