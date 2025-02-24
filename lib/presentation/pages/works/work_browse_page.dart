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
import '../work_browser/components/sidebar_toggle.dart';


class WorkBrowsePage extends ConsumerStatefulWidget {
  const WorkBrowsePage({super.key});

  @override
  ConsumerState<WorkBrowsePage> createState() => _WorkBrowsePageState();
}

class _WorkBrowsePageState extends ConsumerState<WorkBrowsePage> {
  static const double sidebarWidth = 280.0;
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
      navigationInfo: const Text('作品浏览'),
      actions: [
        // Batch mode toggle
        IconButton(
          icon: Icon(_batchMode ? Icons.check_box : Icons.check_box_outline_blank),
          tooltip: _batchMode ? '退出选择' : '批量选择',
          onPressed: () {
            setState(() {
              _batchMode = !_batchMode;
              if (!_batchMode) {
                _selectedWorks.clear();
              }
            });
          },
        ),
        // Search action
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(context),
        ),
        // View mode toggle
        IconButton(
          icon: Icon(state.viewMode == ViewMode.grid 
              ? Icons.view_list 
              : Icons.grid_view),
          onPressed: () {
            ref.read(workBrowseProvider.notifier).toggleViewMode();
          },
        ),
        // Sort direction toggle
        IconButton(
          icon: Icon(state.sortOption.descending 
              ? Icons.arrow_downward 
              : Icons.arrow_upward),
          onPressed: () {
            ref.read(workBrowseProvider.notifier).toggleSortDirection();
          },
        ),
      ],
      toolbar: _buildToolbar(),      
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: state.isSidebarOpen ? sidebarWidth : 0,
            child: state.isSidebarOpen
                ? WorkFilterPanel(
                    filter: state.filter,
                    onFilterChanged: ref.read(workBrowseProvider.notifier).updateFilter,
                  )
                : null,
          ),
          SidebarToggle(
            isOpen: state.isSidebarOpen,
            onToggle: ref.read(workBrowseProvider.notifier).toggleSidebar,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: state.viewMode == ViewMode.grid
                      ? _buildGrid(state.works)
                      : _buildList(state.works),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleWorkSelected(BuildContext context, String workId) {
    // ...existing work selection handler...
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final works = state.works;
        return SizedBox(  // 添加固定高度约束
          height: constraints.maxHeight,
          child: state.viewMode == ViewMode.grid
              ? _buildGrid(works)
              : _buildList(works),
        );
      },
    );
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
    return Row(
      children: [
        if (!_batchMode)
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('导入作品'),
            onPressed: () => _showImportDialog(context),
          ),
        if (_batchMode) ...[
          FilledButton.tonalIcon(
            icon: const Icon(Icons.delete),
            label: Text('删除${_selectedWorks.length}项'),
            onPressed: _selectedWorks.isEmpty ? null : _deleteSelected,
          ),
          const SizedBox(width: AppSizes.m),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.close),
            label: const Text('退出选择'),
            onPressed: () => setState(() {
              _batchMode = false;
              _selectedWorks.clear();
            }),
          ),
        ],
        const Spacer(),
        if (_batchMode)
          Text(
            '已选择 ${_selectedWorks.length} 项',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildGrid(List<Work> works) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSizes.m,
        crossAxisSpacing: AppSizes.m,
        // 调整为更大的比例以适应内容
        childAspectRatio: 0.7,  // 修改这个值
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
        isSelected: _selectedWorks.contains(works[index].id),
        isSelectionMode: _batchMode,  // 添加这个参数
        onSelectionChanged: _batchMode ? (selected) {
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
      barrierDismissible: false,  // 防止点击外部关闭
      builder: (context) => WorkImportDialog(), // Remove const to allow state changes
    );

    if (result == true) {
      try {
        // Show loading indicator
        await ref.read(workBrowseProvider.notifier).loadWorks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('作品导入成功'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('刷新列表失败: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class WorkListItem extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelectionChanged;
  final bool isSelected;
  final bool isSelectionMode;  // 添加这个字段

  const WorkListItem({
    super.key,
    required this.work,
    this.onTap,
    this.onSelectionChanged,
    this.isSelected = false,
    this.isSelectionMode = false,  // 初始化
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isSelectionMode ? null : onTap,  // 现在可以使用了
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.m),
          child: SizedBox(  // Add fixed height container
            height: AppSizes.listItemHeight,  // Add this constant
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,  // Align to top
              children: [
                if (isSelectionMode)  // 现在可以使用了
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.m),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => onSelectionChanged?.call(value ?? false),
                    ),
                  ),
                _buildThumbnail(context), // 修改这里，添加 context 参数
                const SizedBox(width: AppSizes.m),
                Expanded(child: _buildContent(context)), // 修改这里，添加 context 参数
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {  // 更新方法签名
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
      mainAxisSize: MainAxisSize.min,  // Add this
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
        const SizedBox(height: AppSizes.s),  // Replace Spacer
        // Tags section
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
        const SizedBox(height: AppSizes.s),  // Add fixed spacing
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

class WorkGridItem extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const WorkGridItem({
    super.key,
    required this.work,
    this.onTap,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,  // 添加这行
          children: [
            AspectRatio(
              aspectRatio: 1,  // 1:1 ratio for thumbnail
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(context),
                  if (selectable || selected)
                    _buildSelectionOverlay(context),
                ],
              ),
            ),
            Expanded(  // 包装在 Expanded 中
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.name ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (work.author?.isNotEmpty ?? false) ...[
                      const SizedBox(height: AppSizes.xxs),
                      Text(
                        work.author!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),  // 添加这行
                    _buildMetadata(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTextStyle(
      style: textTheme.bodySmall!.copyWith(
        color: colorScheme.outline,
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_outlined,
            size: 16,
            color: colorScheme.outline,
          ),
          const SizedBox(width: AppSizes.xs),
          Text('${work.imageCount ?? 0}张'),
          const Spacer(),
          Text(DateFormatter.formatCompact(
            work.creationDate ?? work.createTime ?? DateTime.now(),
          )),
        ],
      ),
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
