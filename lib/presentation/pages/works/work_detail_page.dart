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
import 'components/work_tabs.dart';

class CharacterDetailPage extends StatelessWidget {
  final String charId;
  final VoidCallback onBack;

  const CharacterDetailPage(
      {super.key, required this.charId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('字帖详情', style: TextStyle(fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('字帖 $charId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  // 添加 WidgetsBindingObserver mixin 以正确处理生命周期方法

  bool _isPanelOpen = true;
  bool _hasCheckedStateRestoration = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workDetailProvider);

    // 根据编辑状态选择显示的工具栏
    final toolbar = state.isEditing
        ? _buildEditModeToolbar(context, state)
        : _buildViewModeToolbar(context, state);

    // 添加键盘快捷键支持
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (keyEvent) => _handleKeyboardShortcuts(keyEvent, state),
      child: PageLayout(
        toolbar: toolbar,
        body: _buildBody(context, state),
      ),
    );
  }

  // 实现 WidgetsBindingObserver 的 didPopRoute 方法
  @override
  Future<bool> didPopRoute() async {
    return await _handleBackNavigation() || await super.didPopRoute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除观察者
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加观察者
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkDetails();
    });
  }

  // 修复此方法，将其作为 State 对象的方法而非 Widget 的方法
  Future<bool> onWillPop() async {
    return _handleBackNavigation();
  }

  Widget _buildBody(BuildContext context, WorkDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载作品详情中...'),
      );
    }

    if (state.error != null) {
      return Center(
        child: ErrorDisplay(
          error: state.error!,
          onRetry: _loadWorkDetails,
        ),
      );
    }

    // 根据编辑状态选择要显示的实际内容
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

  // 字形标注面板
  Widget _buildCharAnnotationPanel(WorkEntity work) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('集字信息', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // 显示已提取字形的统计
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

  /// 字形标注标签页
  Widget _buildCharAnnotationTab(WorkEntity work) {
    // 这里实现字形标注标签页
    return Center(child: Text('字形标注（编辑模式）- ${work.collectedChars.length} 个字形'));
  }

  /// 构建编辑模式的内容
  Widget _buildEditModeContent(
      BuildContext context, WorkDetailState state, WorkEntity work) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧图片预览 - 占据较大空间
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            child: WorkImagePreview(
              work: work,
              isEditing: true,
            ),
          ),
        ),

        // 右侧面板 - 包含标签页和表单
        SizedBox(
          width: 350, // 保持固定宽度
          child: Column(
            children: [
              // 标签选择器 - 移到右侧面板顶部
              WorkTabs(
                selectedIndex: ref.watch(workDetailTabIndexProvider),
                onTabSelected: (index) {
                  // 在切换前确保当前表单状态已保存
                  final currentTabIndex = ref.read(workDetailTabIndexProvider);
                  if (currentTabIndex == 0 && index != 0) {
                    // 如果当前在基本信息页，将要切换出去，确保表单提交
                    _savePendingFormChanges();
                  }

                  ref.read(workDetailTabIndexProvider.notifier).state = index;
                },
              ),

              // 内容区域 - 根据选中的标签显示不同内容
              Expanded(
                child: IndexedStack(
                  index: ref.watch(workDetailTabIndexProvider),
                  children: [
                    // 基本信息编辑表单
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      // 添加唯一 key，确保表单实例在编辑过程中保持不变
                      child: forms.WorkDetailEditForm(
                        key: ValueKey('form_${work.id}'),
                        work: work,
                      ),
                    ),

                    // 标签编辑面板
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      child: _buildTagsEditPanel(context, state, work),
                    ),

                    // 字形标注面板
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

  /// 构建编辑模式的工具栏 - 移除撤销/重做按钮，简化UI
  Widget _buildEditModeToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      child: Row(
        children: [
          // 标题部分
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

          // 保存按钮 - 任何更改都可以保存
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('保存'),
            onPressed: state.hasChanges && !state.isSaving
                ? () => _saveChanges()
                : null,
          ),

          const SizedBox(width: 8),

          // 取消按钮
          OutlinedButton(
            child: const Text('取消'),
            onPressed: () => _cancelEditing(),
          ),
        ],
      ),
    );
  }

  /// 图片管理标签页
  Widget _buildImageManagementTab(WorkEntity work) {
    // 这里实现图片管理标签页，支持图片编辑功能
    // 在正式实现中，会有更完整的图片管理组件
    return Center(child: Text('图片管理（编辑模式）- ${work.images.length} 张图片'));
  }

  // 实现标签管理面板
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
            // 直接更新标签，不使用命令模式
            notifier.updateWorkTags(updatedTags);

            // 添加日志，帮助调试标签更新
            AppLogger.debug(
              '标签已更新',
              tag: 'WorkDetailPage',
              data: {'tags': updatedTags},
            );
          },
          chipColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 16),
        const Text(
          '提示: 标签可用于快速筛选和归类作品',
          style: TextStyle(
              fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  /// 构建查看模式的内容
  Widget _buildViewModeContent(BuildContext context, WorkEntity work) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧图片预览区域
        Expanded(
          flex: 7,
          child: WorkImagePreview(
            work: work,
            isEditing: false, // 标记为非编辑模式
          ),
        ),

        // 使用通用侧边栏切换按钮，设置alignRight=true
        SidebarToggle(
          isOpen: _isPanelOpen,
          onToggle: () {
            setState(() {
              _isPanelOpen = !_isPanelOpen;
            });
          },
          alignRight: true, // 设置为右对齐模式
        ),

        // 右侧信息面板 - 根据状态显示或隐藏
        if (_isPanelOpen)
          SizedBox(
            width: 350, // 固定宽度
            child: WorkDetailInfoPanel(work: work),
          ),
      ],
    );
  }

  /// 构建查看模式的工具栏
  Widget _buildViewModeToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);
    final work = state.work;

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      child: Row(
        children: [
          // 左侧返回按钮 - 修改为使用自定义处理
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            tooltip: '返回',
            onPressed: _handleBackButton, // 更改为自定义处理方法
          ),

          // 标题
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

          // 编辑按钮
          FilledButton.icon(
            onPressed: work != null ? _enterEditMode : null,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('编辑'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),

          const SizedBox(width: AppSizes.spacingSmall),

          // 提取字形按钮
          FilledButton.tonal(
            onPressed: work != null ? () => _navigateToExtract(work.id) : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('提取字形'),
          ),

          const SizedBox(width: AppSizes.spacingSmall),

          // 删除按钮
          OutlinedButton.icon(
            onPressed: work != null ? () => _confirmDelete(context) : null,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
            label: Text(
              '删除',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
            ),
          ),

          // 右侧空间占位
          const Spacer(),

          // 右侧选项：导出、分享
          IconButton(
            onPressed: work != null ? () => _exportWork(work) : null,
            icon:
                Icon(Icons.download_outlined, color: theme.colorScheme.primary),
            tooltip: '导出',
          ),

          IconButton(
            onPressed: work != null ? () => _shareWork(work) : null,
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享',
          ),
        ],
      ),
    );
  }

  /// 取消编辑模式
  void _cancelEditing() {
    final hasChanges = ref.read(workDetailProvider).hasChanges;

    if (hasChanges) {
      // 如果有更改，显示确认对话框
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
      // 如果没有更改，直接退出编辑模式
      ref.read(workDetailProvider.notifier).cancelEditing();
    }
  }

  /// 检查是否有未完成的编辑会话
  Future<void> _checkForUnfinishedEditSession() async {
    // 避免重复检查
    if (_hasCheckedStateRestoration) return;
    _hasCheckedStateRestoration = true;

    // 检查是否有未完成的编辑状态
    final stateRestorationService = ref.read(stateRestorationServiceProvider);
    final hasUnfinishedSession =
        await stateRestorationService.hasUnfinishedEditSession(widget.workId);

    if (hasUnfinishedSession && mounted) {
      // 显示恢复对话框
      final shouldRestore = await showDialog<bool>(
            context: context,
            barrierDismissible: false, // 用户必须做出选择
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
        // 恢复编辑状态
        await ref
            .read(workDetailProvider.notifier)
            .tryRestoreEditState(widget.workId);

        // 如果恢复成功，显示提示
        if (ref.read(workDetailProvider).isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已恢复上次的编辑状态'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        // 清除保存的编辑状态
        stateRestorationService.clearWorkEditState(
          // 调用清除编辑状态方法
          widget.workId,
        );
      }
    }
  }

  /// 确认删除对话框
  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个作品吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ref.read(workDetailProvider.notifier).deleteWork();
      if (result && mounted) {
        ref.read(worksNeedsRefreshProvider.notifier).state = const RefreshInfo(
          reason: '作品数据删除立即刷新',
          force: true, // 数据变更应立即刷新
        );
        Navigator.of(context).pop(); // 简化返回逻辑
      }
    }
  }

  /// 进入编辑模式
  void _enterEditMode() {
    ref.read(workDetailProvider.notifier).enterEditMode();

    // 在进入编辑模式时，重置标签页到基本信息页（索引0）
    ref.read(workDetailTabIndexProvider.notifier).state = 0;
  }

  /// 导出作品
  void _exportWork(WorkEntity work) {
    // 导出作品的实现
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在导出作品: ${work.title}')),
    );
  }

  // 处理返回按钮，确保返回时刷新作品列表
  void _handleBackButton() {
    Navigator.of(context).pop(true); // 返回true表示数据可能已更改
  }

  /// 处理未保存更改警告并处理返回导航
  Future<bool> _handleBackNavigation() async {
    final state = ref.read(workDetailProvider);
    if (state.isEditing && state.hasChanges) {
      // 如果在编辑模式且有未保存的更改，显示警告对话框
      final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('放弃更改?'),
              content: const Text('你有未保存的更改。如果你离开，这些更改将会丢失。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('放弃更改'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldProceed) {
        // 用户确认放弃更改
        await ref.read(workDetailProvider.notifier).cancelEditing();
        return true;
      } else {
        // 用户取消操作
        return false;
      }
    }
    // 没有未保存的更改，可以直接返回
    return true;
  }

  /// 处理键盘快捷键
  void _handleKeyboardShortcuts(KeyEvent event, WorkDetailState state) {
    // 实现键盘快捷键处理
    // 例如: Ctrl+Z 撤销，Ctrl+Y 重做等
    if (state.isEditing) {
      // 检测常见的快捷键组合
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

  /// 处理保存操作
  void _handleSave(WorkDetailState state) {
    if (!state.hasChanges || state.isSaving) return;

    _saveChanges();
  }

  /// 加载作品详情
  Future<void> _loadWorkDetails() async {
    final notifier = ref.read(workDetailProvider.notifier);
    await notifier.loadWorkDetails(widget.workId);

    // 加载完成后检查未完成的编辑状态
    _checkForUnfinishedEditSession();
  }

  /// 导航到字形提取页面
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

  /// 保存更改
  Future<void> _saveChanges() async {
    // 创建一个标志，用于处理异步操作期间的组件卸载情况
    bool isDialogActive = true;

    // 记录保存前的标签数据，以便调试
    final editingWork = ref.read(workDetailProvider).editingWork;
    final tags = editingWork?.tags;

    AppLogger.debug('开始保存作品', tag: 'WorkDetailPage', data: {
      'workId': editingWork?.id,
      'tagCount': tags?.length ?? 0,
      'tags': tags, // 直接输出标签列表，方便调试
    });

    // 显示保存进度对话框
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // 防止后退键关闭对话框
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
      // 设置超时保护
      // final completer = Completer<bool>();
      // final timer = Timer(const Duration(seconds: 10), () {
      //   if (!completer.isCompleted) {
      //     completer.completeError(TimeoutException('保存操作超时，请重试'));
      //   }
      // });

      // 执行保存操作
      ref.read(workDetailProvider.notifier).saveChanges().then((result) {
        // if (!completer.isCompleted) completer.complete(result);
      }).catchError((error) {
        // if (!completer.isCompleted) completer.completeError(error);
      });

      // 等待结果
      // final result = await completer.future;
      // timer.cancel();

      // 记录保存结果，包括标签处理情况
      AppLogger.debug('保存操作完成', tag: 'WorkDetailPage', data: {
        // 'result': result,
        'tagCount': tags?.length ?? 0,
      });

      // 关闭对话框前先检查context是否仍然有效
      if (context.mounted && isDialogActive) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogActive = false;

        if (true) {
          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存成功'),
              duration: Duration(seconds: 1),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 300));

          if (context.mounted) {
            ref.read(workDetailProvider.notifier).completeEditing();

            // 使用合适的刷新信息通知
            ref.read(worksNeedsRefreshProvider.notifier).state =
                RefreshInfo.dataChanged();

            Navigator.of(context).pop(); // 返回
          }
        } else {
          // 显示失败消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请重试')),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error(
        '保存出错',
        tag: 'WorkDetailPage',
        error: e,
        stackTrace: stack,
        data: {'tagCount': tags?.length ?? 0},
      );

      if (mounted && isDialogActive) {
        Navigator.of(context).pop(); // 关闭进度对话框
        isDialogActive = false;

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存出错: ${e.toString()}')),
        );
      }
    }
  }

  // 添加辅助方法保存表单待处理的更改
  void _savePendingFormChanges() {
    // 直接从表单控制器获取当前值并应用
    final editingWork = ref.read(workDetailProvider).editingWork;
    if (editingWork != null) {
      // 通知 provider 有变更需要保存
      ref.read(workDetailProvider.notifier).markAsChanged();
    }
  }

  /// 分享作品
  void _shareWork(WorkEntity work) {
    // 分享作品的实现
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在分享作品: ${work.title}')),
    );
  }

  /// 显示操作反馈，增加错误处理逻辑
  void _showOperationFeedback(String message) {
    try {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // 如果 context 不再有效或其他原因导致显示失败，记录但不抛出异常
      AppLogger.warning(
        '无法显示操作反馈',
        tag: 'WorkDetailPage',
        error: e,
        data: {'message': message},
      );
    }
  }
}
