import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../application/providers/work_browse_provider.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/path_helper.dart';
import '../../dialogs/work_import/work_import_dialog.dart';
import '../../viewmodels/states/work_browse_state.dart';
import '../../widgets/page_layout.dart';
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

    return PageLayout(
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
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.gridCrossAxisCount,
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,
        mainAxisExtent: AppSizes.gridItemTotalHeight,
      ),
      itemCount: works.length,
      itemBuilder: (context, index) => WorkGridItem(
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
        onTap: _batchMode ? null : () => Navigator.pushNamed(
          context,
          '/work_detail',
          arguments: works[index].id,
        ),
        onDelete: _batchMode ? null : () async {
          await ref.read(workBrowseProvider.notifier)
              .deleteWork(works[index].id!);
        },
      ),
    );
  }

  Widget _buildList(List<Work> works) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: works.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.s),
      itemBuilder: (context, index) => WorkListItem(
        work: works[index],
        selected: _selectedWorks.contains(works[index].id),
        onSelected: _batchMode ? (selected) {
          setState(() {
            if (selected) {
              _selectedWorks.add(works[index].id!);
            } else {
              _selectedWorks.remove(works[index].id!);
            }
          });
        } : null,
        onTap: _batchMode ? null : () => Navigator.pushNamed(
          context,
          '/work_detail',
          arguments: works[index].id,
        ),
        onEdit: _batchMode ? null : () {
          // Handle edit action
        },
        onDelete: _batchMode ? null : () async {
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
      ref.invalidate(workBrowseProvider);
    }
  }
}

class WorkListItem extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const WorkListItem({
    super.key,
    required this.work,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected != null ? () => onSelected!(!selected) : onTap,
        child: SizedBox(
          height: AppSizes.listItemHeight,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _buildThumbnail(context),
                    if (onSelected != null || selected)
                      _buildSelectionOverlay(context),
                  ],
                ),
                const SizedBox(width: AppSizes.m),
                Expanded(child: _buildContent(context)),
                if (onSelected == null && (onEdit != null || onDelete != null))
                  _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailSection(BuildContext context) {
    return Stack(
      children: [
        _buildThumbnail(context),
        if (onSelected != null)
          _buildSelectionOverlay(context),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return SizedBox(
      width: AppSizes.thumbnailSize,
      height: AppSizes.thumbnailSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.xs),
        child: FutureBuilder<String>(
          future: PathHelper.getWorkThumbnailPath(work.id!),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final file = File(snapshot.data!);
              if (file.existsSync()) {
                return Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                );
              }
            }
            return _buildPlaceholder(context);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section with fixed height
        SizedBox(
          height: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                work.name ?? '',
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (work.author?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSizes.xxs),
                Text(
                  work.author!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Tags section with single line
        SizedBox(
          height: 24,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (work.style?.isNotEmpty ?? false)
                _buildTag(context, work.style!),
              if (work.tool?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.xs),
                  child: _buildTag(context, work.tool!),
                ),
              if (work.imageCount != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.xs),
                  child: _buildTag(context, '${work.imageCount}张'),
                ),
            ],
          ),
        ),

        const Spacer(),

        // Metadata section
        DefaultTextStyle(
          style: textTheme.bodySmall!.copyWith(
            color: colorScheme.outline,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: colorScheme.outline,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(DateFormatter.formatCompact(
                work.creationDate ?? work.createTime ?? DateTime.now()
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.xs),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: selected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xs),
            child: Checkbox(
              value: selected,
              onChanged: (value) => onSelected?.call(value ?? false),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkGridItem extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const WorkGridItem({
    super.key,
    required this.work,
    this.onTap,
    this.onDelete,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selectable ? () => onSelected?.call(!selected) : onTap,
        child: SizedBox(
          width: AppSizes.gridItemWidth,
          height: AppSizes.gridItemTotalHeight,
          child: Column(
            children: [
              SizedBox(
                height: AppSizes.gridItemImageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbnail(context),
                    if (selectable || selected)
                      _buildSelectionOverlay(context),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.m),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          work.name ?? '',
          style: textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (work.author?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSizes.xxs),
          Text(
            work.author!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const Spacer(),
        // Bottom metadata
        Row(
          children: [
            Icon(
              Icons.photo_outlined,
              size: 16,
              color: colorScheme.outline,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              '${work.imageCount ?? 0}张',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const Spacer(),
            Text(
              DateFormatter.formatCompact(
                work.creationDate ?? work.createTime ?? DateTime.now(),
              ),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return FutureBuilder<String>(
      future: PathHelper.getWorkThumbnailPath(work.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            );
          }
        }
        return _buildPlaceholder(context);
      },
    );
  }

  Widget _buildSelectionOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: Checkbox(
            value: selected,
            onChanged: (value) => onSelected?.call(value ?? false),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
