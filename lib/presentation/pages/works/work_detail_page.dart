import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/work/work_entity.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/work_detail_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import 'components/info_card.dart';
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

class _WorkDetailPageState extends ConsumerState<WorkDetailPage> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workDetailProvider);
    final work = state.work;

    return Scaffold(
      appBar: _buildAppBar(context, work),
      body: Stack(
        children: [
          if (state.isLoading)
            const LoadingView()
          else if (state.error != null)
            ErrorView(
              message: state.error!,
              onRetry: _loadWork,
            )
          else if (work == null)
            const ErrorView(
              message: '作品不存在',
            )
          else
            _buildContent(context, work),
          if (state.isSaving)
            Container(
              color: Colors.black26,
              child: const LoadingView(),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 延迟加载，避免在构建过程中修改状态
    Future.microtask(() {
      if (mounted) {
        _loadWork();
      }
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WorkEntity? work) {
    return AppBar(
      title: Text(work?.title ?? '作品详情'),
      actions: [
        if (work != null) ...[
          // 编辑模式切换
          IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });

              if (!_isEditMode) {
                // 退出编辑模式时保存
                _handleSave();
              }
            },
            tooltip: _isEditMode ? '完成' : '编辑',
          ),

          // 菜单按钮
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, work),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, WorkEntity work) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 图片预览/编辑区域
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: _isEditMode
                ? WorkImagesManagementView(work: work)
                : ViewModeImagePreview(
                    images: work.images,
                    selectedIndex: 0,
                    onImageSelect: (index) {
                      // TODO: 处理图片选择
                    },
                  ),
          ),

          const SizedBox(height: AppSizes.m),

          // 信息卡片
          InfoCard(
            work: work,
            isEditMode: _isEditMode,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(WorkEntity work) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后不可恢复，确定要删除吗？'),
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

    if (confirmed != true || !mounted) return;

    try {
      final success =
          await ref.read(workDetailProvider.notifier).deleteWork(work.id);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  Future<void> _handleMenuAction(String action, WorkEntity work) async {
    switch (action) {
      case 'delete':
        await _handleDelete(work);
        break;
    }
  }

  Future<void> _handleSave() async {
    try {
      await ref.read(workDetailProvider.notifier).saveWork();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  Future<void> _loadWork() async {
    if (!mounted) return;
    await ref.read(workDetailProvider.notifier).loadWork(widget.workId);
  }
}
