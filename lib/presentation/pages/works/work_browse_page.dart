import 'dart:async';
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
import '../../../routes/app_routes.dart'; // 添加这个导入

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
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // 确保页面初始化时加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workBrowseProvider.notifier).loadWorks();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);

    return PageLayout(
      navigationInfo: const Text('作品浏览'),
      toolbar: _buildToolbar(),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: state.isSidebarOpen ? sidebarWidth : 0,
            child: state.isSidebarOpen
                ? SingleChildScrollView(
                    // 添加滚动视图包装
                    child: Padding(
                      // 添加内边距
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.m),
                      child: WorkFilterPanel(
                        filter: state.filter,
                        onFilterChanged:
                            ref.read(workBrowseProvider.notifier).updateFilter,
                      ),
                    ),
                  )
                : null,
          ),
          SidebarToggle(
            isOpen: state.isSidebarOpen,
            onToggle: ref.read(workBrowseProvider.notifier).toggleSidebar,
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.works.isEmpty
                        ? const Center(child: Text('暂无作品'))
                        : LayoutBuilder(
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
    Navigator.pushNamed(
      context,
      AppRoutes.workDetail,
      arguments: workId,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final works = state.works;
        return SizedBox(
          // 添加固定高度约束
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
    final theme = Theme.of(context);
    final state = ref.watch(workBrowseProvider);

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧按钮组
          Wrap(
            spacing: AppSizes.s,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('导入作品'),
                onPressed: () => _showImportDialog(context),
              ),
              OutlinedButton.icon(
                icon: Icon(_batchMode ? Icons.close : Icons.checklist),
                label: Text(_batchMode ? '完成' : '批量处理'),
                onPressed: () => setState(() => _batchMode = !_batchMode),
              ),
            ],
          ),

          const Spacer(),

          // 右侧控制组
          Row(
            children: [
              // 视图切换按钮
              IconButton(
                icon: Icon(
                  state.viewMode == ViewMode.grid
                      ? Icons.view_list
                      : Icons.grid_view,
                  color: theme.colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.s),
                  ),
                ),
                onPressed: () =>
                    ref.read(workBrowseProvider.notifier).toggleViewMode(),
                tooltip: state.viewMode == ViewMode.grid ? '列表视图' : '网格视图',
              ),
              const SizedBox(width: AppSizes.s),

              // 搜索框
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索作品...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s,
                      vertical: AppSizes.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.m),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(workBrowseProvider.notifier)
                                  .searchWorks('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      ref.read(workBrowseProvider.notifier).searchWorks(value);
                    });
                  },
                ),
              ),
            ],
          ),

          // 批量操作状态
          if (_batchMode) ...[
            const SizedBox(width: AppSizes.m),
            Text(
              '已选择 ${_selectedWorks.length} 项',
              style: theme.textTheme.bodyMedium,
            ),
            if (_selectedWorks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppSizes.s),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.delete),
                  label: Text('删除${_selectedWorks.length}项'),
                  onPressed: _deleteSelected,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<Work> works) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算合适的网格列数
        final width = constraints.maxWidth - (AppSizes.m * 2); // 减去内边距
        final itemWidth = 280.0; // 理想的单项宽度
        final columns = (width / itemWidth).floor();
        final crossAxisCount = columns < 2 ? 2 : columns; // 最少2列

        // 计算实际的宽高比
        final spacing = AppSizes.m;
        final availableWidth =
            (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        // 根据可用宽度计算合适的高度，确保内容不会溢出
        final aspectRatio = availableWidth / (availableWidth * 1.4); // 1.4是高宽比

        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.m),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: works.length,
          itemBuilder: (context, index) {
            final work = works[index];
            return WorkGridItem(
              work: work,
              onTap: () => _handleWorkSelected(context, work.id!),
              selectable: _batchMode,
              selected: _selectedWorks.contains(work.id),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWorks.add(work.id!);
                  } else {
                    _selectedWorks.remove(work.id!);
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<Work> works) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: works.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.s),
      itemBuilder: (context, index) {
        final work = works[index];
        return WorkListItem(
          work: work,
          isSelected: _selectedWorks.contains(work.id),
          isSelectionMode: _batchMode, // 添加这个参数
          onSelectionChanged: _batchMode
              ? (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWorks.add(work.id!);
                    } else {
                      _selectedWorks.remove(work.id!);
                    }
                  });
                }
              : null,
          onTap:
              _batchMode ? null : () => _handleWorkSelected(context, work.id!),
        );
      },
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
      barrierDismissible: false, // 防止点击外部关闭
      builder: (context) =>
          WorkImportDialog(), // Remove const to allow state changes
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
  final bool isSelectionMode; // 添加这个字段

  const WorkListItem({
    super.key,
    required this.work,
    this.onTap,
    this.onSelectionChanged,
    this.isSelected = false,
    this.isSelectionMode = false, // 初始化
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isSelectionMode ? null : onTap, // 现在可以使用了
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.m),
          child: SizedBox(
            // Add fixed height container
            height: AppSizes.listItemHeight, // Add this constant
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to top
              children: [
                if (isSelectionMode) // 现在可以使用了
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.m),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          onSelectionChanged?.call(value ?? false),
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

  Widget _buildThumbnail(BuildContext context) {
    // 更新方法签名
    return SizedBox(
      width: AppSizes.thumbnailSize,
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
    );
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min, // Add this
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
        const SizedBox(height: AppSizes.s), // Replace Spacer
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
        const SizedBox(height: AppSizes.s), // Add fixed spacing
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
                  work.creationDate ?? work.createTime ?? DateTime.now())),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片区域固定宽高比
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(context),
                  if (selectable || selected) _buildSelectionOverlay(context),
                ],
              ),
            ),
            // 内容区域自适应高度
            Padding(
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
                  const SizedBox(height: AppSizes.s),
                  _buildMetadata(context),
                ],
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
    if (work.id == null) return _buildPlaceholder(context);

    return FutureBuilder<String?>(
      future: PathHelper.getWorkThumbnailPath(work.id!),
      builder: (context, snapshot) {
        debugPrint('Thumbnail path for ${work.id}: ${snapshot.data}');

        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (ctx, error, stack) {
              debugPrint('Error loading thumbnail: $error');
              return _buildPlaceholder(context);
            },
          );
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
