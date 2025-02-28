import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/value_objects/practice/practice_entity.dart';
import '../../../domain/value_objects/practice/practice_layer.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../routes/app_routes.dart';
import '../../providers/practice_detail_provider.dart';
import '../../widgets/common/detail_toolbar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/page_layout.dart';
import 'components/practice_page_viewer.dart';

class PracticeDetailPage extends ConsumerStatefulWidget {
  final String practiceId;

  const PracticeDetailPage({super.key, required this.practiceId});

  @override
  ConsumerState<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends ConsumerState<PracticeDetailPage> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practiceDetailProvider);

    return PageLayout(
      toolbar: _buildToolbar(state.practice),
      body: _buildBody(state),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPractice();
  }

  Widget _buildBody(PracticeDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载练习中...'),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPractice,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.practice == null) {
      return const Center(
        child: Text('练习不存在或已被删除'),
      );
    }

    return _buildPracticeContent(state.practice!);
  }

  Widget _buildPageSelector(PracticeEntity practice) {
    final pages = practice.pages;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text('第${index + 1}页'),
              selected: index == _currentPageIndex,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPracticeContent(PracticeEntity practice) {
    final pages = practice.pages;
    if (pages.isEmpty) {
      return const Center(
        child: Text('此练习没有页面'),
      );
    }

    return Column(
      children: [
        // 页面选择器（如果有多页）
        if (pages.length > 1) _buildPageSelector(practice),

        // 页面内容查看器
        Expanded(
          child: PracticePageViewer(
            page:
                pages[_currentPageIndex < pages.length ? _currentPageIndex : 0],
            readOnly: true,
            onLayerToggle: _handleLayerToggle,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeMetadata(PracticeEntity practice) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '练习信息',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '共 ${practice.pages.length} 页',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('创建时间: ${_formatDateTime(practice.createTime)}'),
                Text('更新时间: ${_formatDateTime(practice.updateTime)}'),
              ],
            ),
            if (practice.metadata != null && practice.metadata!.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  children: practice.metadata!.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(PracticeEntity? practice) {
    return DetailToolbar(
      title: practice?.title ?? '练习详情',
      leadingIcon: Icons.auto_stories,
      subtitle: practice != null
          ? '创建于 ${_formatDateShort(practice.createTime)}'
          : null,
      badge: practice != null && practice.pages.isNotEmpty
          ? DetailBadge(text: '${practice.pages.length}页')
          : null,
      actions: practice != null
          ? [
              DetailToolbarAction(
                icon: Icons.edit,
                tooltip: '编辑练习',
                onPressed: _navigateToEdit,
                primary: true,
              ),
              DetailToolbarAction(
                icon: Icons.add_photo_alternate_outlined,
                tooltip: '添加页面',
                onPressed: () {
                  // 添加页面功能
                },
              ),
              DetailToolbarAction(
                icon: Icons.delete,
                tooltip: '删除练习',
                onPressed: _confirmDelete,
                primary: false,
              ),
            ]
          : [],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除练习'),
        content: Text(
            '确定要删除练习"${ref.read(practiceDetailProvider).practice?.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePractice();
    }
  }

  Future<void> _deletePractice() async {
    try {
      final success = await ref
          .read(practiceDetailProvider.notifier)
          .deletePractice(widget.practiceId);

      if (success && mounted) {
        Navigator.of(context).pop(); // 返回上一页
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败')),
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete practice',
        tag: 'PracticeDetailPage',
        error: e,
        stackTrace: stack,
        data: {'id': widget.practiceId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}/${date.month}/${date.day}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';

    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleLayerToggle(PracticeLayer layer) {
    ref.read(practiceDetailProvider.notifier).updateLayer(layer);
  }

  Future<void> _loadPractice() async {
    await ref
        .read(practiceDetailProvider.notifier)
        .getPractice(widget.practiceId);
  }

  void _navigateToEdit() {
    Navigator.pushNamed(
      context,
      AppRoutes.practiceEdit,
      arguments: widget.practiceId,
    ).then((_) => _loadPractice()); // 编辑后刷新
  }
}
