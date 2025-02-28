import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/work_detail_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/page_layout.dart';
import 'components/error_view.dart';
import 'components/work_detail_info_panel.dart';
import 'components/work_image_preview.dart';

class WorkDetailPage extends ConsumerStatefulWidget {
  final String workId;

  const WorkDetailPage({super.key, required this.workId});

  @override
  ConsumerState<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends ConsumerState<WorkDetailPage> {
  bool _isLoading = true;
  Work? _work;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      toolbar: _buildToolbar(),
      body: _buildBody(),
    );
  }

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to avoid modifying providers during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadWork();
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载作品中...'),
      );
    }

    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: () {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _loadWork();
          });
        },
      );
    }

    if (_work == null) {
      return const Center(
        child: Text('作品不存在或已被删除'),
      );
    }

    return _buildWorkContent(_work!);
  }

  Widget _buildToolbar() {
    final theme = Theme.of(context);

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
            '作品详情',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: AppSizes.spacingMedium),

          // 编辑按钮
          FilledButton.icon(
            onPressed: () {
              // 编辑功能
            },
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
            onPressed: () {
              // 提取字形功能
            },
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('提取字形'),
          ),

          const SizedBox(width: AppSizes.spacingSmall),

          // 删除按钮
          OutlinedButton.icon(
            onPressed: () {
              _confirmDelete();
            },
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
        ],
      ),
    );
  }

  Widget _buildWorkContent(Work work) {
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除作品'),
        content: Text('确定要删除作品"${_work?.name ?? ""}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteWork();
    }
  }

  Future<void> _deleteWork() async {
    try {
      setState(() {
        _isLoading = true;
      });

      //await ref.read(workDetailProvider.notifier).deleteWork(_work!.id!);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete work',
        tag: 'WorkDetailPage',
        error: e,
        stackTrace: stack,
        data: {'workId': _work?.id},
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '删除作品失败: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadWork() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the fetch method that doesn't update state directly
      final work =
          await ref.read(workDetailProvider.notifier).fetchWork(widget.workId);

      // Update our local state
      if (mounted) {
        setState(() {
          _work = work;
          _isLoading = false;
        });

        // Now update the provider after UI is ready
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ref.read(workDetailProvider.notifier).loadWork(widget.workId);
        });
      }
    } catch (e, stack) {
      AppLogger.error('加载作品详情失败',
          tag: 'WorkDetailPage',
          error: e,
          stackTrace: stack,
          data: {'workId': widget.workId});

      if (mounted) {
        setState(() {
          _error = '无法加载作品: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
}
