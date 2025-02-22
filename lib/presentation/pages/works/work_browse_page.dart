import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../application/providers/work_browse_provider.dart';
import '../../dialogs/work_import_dialog.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/responsive_builder.dart';
import '../../theme/app_sizes.dart';
import '../../widgets/works/work_filter_panel.dart';

class WorkBrowsePage extends ConsumerStatefulWidget {
  const WorkBrowsePage({super.key});

  @override
  ConsumerState<WorkBrowsePage> createState() => _WorkBrowsePageState();
}

class _WorkBrowsePageState extends ConsumerState<WorkBrowsePage> {
  bool _batchMode = false;
  final Set<String> _selectedWorks = {};
  String _searchQuery = ''; // 添加搜索查询状态

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workBrowseProvider.notifier).loadWorks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);

    return MainLayout(
      navigationInfo: const Text('书法作品'),
      actions: [
        // 搜索按钮
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜索',
          onPressed: () {
            _showSearchDialog(context); // 显示搜索对话框
          },
        ),
        IconButton(
          icon: Icon(state.viewMode == ViewMode.grid
              ? Icons.grid_view
              : Icons.view_list),
          tooltip: state.viewMode == ViewMode.grid ? '网格视图' : '列表视图',
          onPressed: () {
            ref.read(workBrowseProvider.notifier).updateViewMode(
                state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid);
          },
        ),
        // Batch mode toggle button
        IconButton(
          icon: Icon(_batchMode ? Icons.close : Icons.select_all),
          tooltip: _batchMode ? '退出批量选择' : '批量选择',
          onPressed: () {
            setState(() {
              _batchMode = !_batchMode;
              _selectedWorks.clear();
            });
          },
        ),
      ],
      sidebar: WorkFilterPanel(
        filter: state.filter,
        onFilterChanged: (filter) {
          ref.read(workBrowseProvider.notifier).updateFilter(filter);
        },
      ),
      toolbar: _buildToolbar(),
      body: _buildMainContent(state),
      footer: _buildStatusBar(state),
    );
  }

  // 添加搜索对话框
  Future<void> _showSearchDialog(BuildContext context) async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索作品'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入作品名称或作者',
          ),
          onChanged: (text) {
            _searchQuery = text;
          },
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('搜索'),
            onPressed: () => Navigator.of(context).pop(_searchQuery),
          ),
        ],
      ),
    );

    if (query != null) {
      setState(() {
        _searchQuery = query;
      });
      ref.read(workBrowseProvider.notifier).searchWorks(query); // 调用搜索方法
    }
  }

  Widget _buildMainContent(WorkBrowseState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSizes.m),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.s),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.m),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              onPressed: () {
                ref.read(workBrowseProvider.notifier).loadWorks();
              },
            ),
          ],
        ),
      );
    }

    if (state.works.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: AppSizes.m),
            Text(
              '暂无作品',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.s),
            Text(
              '点击"导入作品"按钮添加新作品',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return state.viewMode == ViewMode.grid
        ? _buildGrid(state.works)
        : _buildList(state.works);
  }

  Widget _buildStatusBar(WorkBrowseState state) {
    if (state.works.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.m,
        vertical: AppSizes.xs,
      ),
      child: Row(
        children: [
          Text(
            '共 ${state.works.length} 个作品',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.m,
        vertical: AppSizes.s,
      ),
      child: Row(
        children: [
          if (!_batchMode)
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('导入作品'),
              onPressed: () => _showImportDialog(context),
            ),
          if (_batchMode)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.delete),
              label: Text('删除${_selectedWorks.length}项'),
              onPressed: _deleteSelected,
            ),
          const Spacer(),
          if (_batchMode)
            Text(
              '已选择 ${_selectedWorks.length} 项',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Work> works) {
    return ResponsiveBuilder(
      builder: (context, breakpoint) {
        final crossAxisCount = switch (breakpoint) {
          ResponsiveBreakpoint.lg => 4,
          ResponsiveBreakpoint.md => 3,
          ResponsiveBreakpoint.sm => 2,
          ResponsiveBreakpoint.xs => 1,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.m),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSizes.m,
            crossAxisSpacing: AppSizes.m,
            // 移除固定宽高比，使用自动高度
            mainAxisExtent: 240, // 设置主轴（垂直方向）的估计高度
          ),
          itemCount: works.length,
          itemBuilder: (context, index) => _WorkCard(
            work: works[index],
            selected: _selectedWorks.contains(works[index].id),
            selectable: _batchMode,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedWorks.add(works[index].id!);
                } else {
                  _selectedWorks.remove(works[index].id!);
                }
              });
            },
            onDelete: () async {
              await ref.read(workBrowseProvider.notifier)
                  .deleteWork(works[index].id!);
            },
          ),
        );
      },
    );
  }

  Widget _buildList(List<Work> works) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: works.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.s),
      itemBuilder: (context, index) => _WorkCard(
        work: works[index],
        selected: _selectedWorks.contains(works[index].id),
        selectable: _batchMode,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedWorks.add(works[index].id!);
            } else {
              _selectedWorks.remove(works[index].id!);
            }
          });
        },
        onDelete: () async {
          await ref.read(workBrowseProvider.notifier)
              .deleteWork(works[index].id!);
        },
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedWorks.length} 个作品吗？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            child: const Text('删除'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final workId in _selectedWorks) {
        await ref.read(workBrowseProvider.notifier).deleteWork(workId);
      }
      setState(() {
        _selectedWorks.clear();
        _batchMode = false;
      });
    }
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WorkImportDialog(),
    );

    if (result == true) {
      // Refresh work list after successful import
      ref.read(workBrowseProvider.notifier).loadWorks();
    }
  }
}

class _WorkCard extends ConsumerWidget {
  final Work work;
  final VoidCallback onDelete;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const _WorkCard({
    required this.work,
    required this.onDelete,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selectable
            ? null
            : () => Navigator.pushNamed(
                  context,
                  '/work_detail',
                  arguments: work.id,
                ),
        // 移除固定高度，使用内容自适应
        child: Column(
          mainAxisSize: MainAxisSize.min, // 确保高度自适应内容
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图片
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(ref),
                  if (selectable)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Checkbox(
                        value: selected,
                        onChanged: (value) => onSelected?.call(value ?? false),
                      ),
                    ),
                ],
              ),
            ),
            // 信息区域使用 ConstrainedBox 限制最大高度
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 80,
                maxHeight: 120,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildInfoSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(workBrowseProvider.notifier).getWorkThumbnail(work.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(isLoading: true);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading image: $error');
              return _buildPlaceholder();
            },
          );
        }

        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 使用最小所需空间
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          work.name ?? '未命名',
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // 作者（如果存在）
        if (work.author?.isNotEmpty ?? false) ...[
          Text(
            work.author!,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        // 底部信息行
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // 确保底部对齐
            children: [
              if (work.style?.isNotEmpty ?? false)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      work.style!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${work.imageCount}图',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
