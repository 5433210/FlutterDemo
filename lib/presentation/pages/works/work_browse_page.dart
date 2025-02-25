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
  final Set<String> _selectedWorks = {};
  bool _batchMode = false;
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      toolbar: WorkToolbar(
        batchMode: state.batchMode, // 从状态获取
        selectedCount: state.selectedWorks.length,
        onBatchModeChanged: (_) => 
            ref.read(workBrowseProvider.notifier).toggleBatchMode(),
        onDeleteSelected: () =>
            ref.read(workBrowseProvider.notifier).deleteSelected(),
      ),
      body: WorkContent(
        state: state,
        selectedWorks: state.selectedWorks,
        onSelectionChanged: (workId, selected) =>
            ref.read(workBrowseProvider.notifier).toggleSelection(workId),
      ),
    );
  }

  void _handleSelection(String workId, bool selected) {
    setState(() {
      if (selected) {
        _selectedWorks.add(workId);
      } else {
        _selectedWorks.remove(workId);
      }
    });
  }

  void _handleSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => ref.read(workBrowseProvider.notifier).searchWorks(value),
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
