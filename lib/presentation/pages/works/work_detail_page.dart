import 'package:demo/domain/value_objects/work/work_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_sizes.dart';
import '../../dialogs/delete_dialog.dart';
import '../../providers/work_detail_provider.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/page_layout.dart';
import 'components/work_detail_info_panel.dart';
import 'components/work_image_preview.dart';

class WorkDetailPage extends ConsumerStatefulWidget {
  final String workId;

  const WorkDetailPage({
    super.key,
    required this.workId,
  });

  @override
  ConsumerState<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends ConsumerState<WorkDetailPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workDetailProvider);

    return PageLayout(
      toolbar: _buildToolbar(context, state),
      body: _buildBody(context, state),
    );
  }

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在构建完成后再加载数据
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
      return Center(
        child: ErrorDisplay(
          error: state.error!,
          onRetry: _loadWorkDetails,
        ),
      );
    }

    final work = state.work;
    if (work == null) {
      return const Center(
        child: Text('作品不存在或已被删除'),
      );
    }

    return _buildWorkContent(work);
  }

  Widget _buildToolbar(BuildContext context, WorkDetailState state) {
    final theme = Theme.of(context);
    final work = state.work;

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧返回按钮
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            tooltip: '返回',
            onPressed: () => Navigator.of(context).pop(),
          ),

          // 标题
          Text(
            work?.name ?? '作品详情',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: AppSizes.spacingMedium),

          // 编辑按钮
          FilledButton.icon(
            onPressed: work != null ? () => _navigateToEdit(work.id!) : null,
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
            onPressed: work != null ? () => _navigateToExtract(work.id!) : null,
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

  Widget _buildWorkContent(WorkEntity work) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧图片预览区域 (70%)
        Expanded(
          flex: 7,
          child: WorkImagePreview(work: work),
        ),

        // 右侧信息面板 (30%)
        Expanded(
          flex: 3,
          child: WorkDetailInfoPanel(work: work),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final work = ref.read(workDetailProvider).work;
    if (work == null) return;

    final confirmed = await DeleteDialog.show(
      context,
      title: '删除作品',
      message: '确定要删除作品 "${work.name}" 吗？此操作不可撤销。',
      deleteButtonLabel: '删除',
      cancelButtonLabel: '取消',
    );

    if (confirmed == true && mounted) {
      try {
        final success =
            await ref.read(workDetailProvider.notifier).deleteWork();

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('作品已删除')),
          );
          Navigator.of(context).pop(); // 返回上一页
        }
      } catch (e, stack) {
        AppLogger.error(
          'Delete work failed in UI',
          tag: 'WorkDetailPage',
          error: e,
          stackTrace: stack,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _exportWork(WorkEntity work) {
    // 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能即将上线')),
    );
  }

  Future<void> _loadWorkDetails() async {
    await ref.read(workDetailProvider.notifier).loadWorkDetails(widget.workId);
  }

  void _navigateToEdit(String workId) {
    Navigator.pushNamed(
      context,
      AppRoutes.workEdit,
      arguments: workId,
    ).then((_) => _loadWorkDetails()); // 编辑后刷新
  }

  void _navigateToExtract(String workId) {
    Navigator.pushNamed(
      context,
      AppRoutes.workExtract,
      arguments: workId,
    ).then((_) => _loadWorkDetails()); // 提取后刷新
  }

  void _shareWork(WorkEntity work) {
    // 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能即将上线')),
    );
  }
}
