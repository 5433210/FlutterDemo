import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/work.dart';
import '../../../application/providers/work_browse_provider.dart';
import '../../dialogs/work_import_dialog.dart';
import '../../viewmodels/states/work_browse_state.dart';


class WorkBrowsePage extends ConsumerStatefulWidget {
  const WorkBrowsePage({super.key});

  @override
  ConsumerState<WorkBrowsePage> createState() => _WorkBrowsePageState();
}

class _WorkBrowsePageState extends ConsumerState<WorkBrowsePage> {

 @override
  void initState() {
    super.initState();
    // Call loadWorks when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workBrowseProvider.notifier).loadWorks();
    });
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workBrowseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书法作品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
            tooltip: '排序',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: '筛选',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: '搜索作品名称或作者',
              onChanged: (value) => 
                  ref.read(workBrowseProvider.notifier).updateSearch(value),
            ),
          ),
          // Work grid
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.works.isEmpty
                        ? const Center(child: Text('暂无作品'))
                        : _buildWorkGrid(state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showSortDialog(BuildContext context) async {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.read(workBrowseProvider);

    final result = await showDialog<SortOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('排序方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<SortField>(
              title: const Text('作品名称'),
              value: SortField.name,
              groupValue: state.sortOption.field,
              onChanged: (value) => Navigator.pop(
                context,
                SortOption(field: value!, order: state.sortOption.order),
              ),
            ),
            RadioListTile<SortField>(
              title: const Text('创作者'),
              value: SortField.author,
              groupValue: state.sortOption.field,
              onChanged: (value) => Navigator.pop(
                context,
                SortOption(field: value!, order: state.sortOption.order),
              ),
            ),
            RadioListTile<SortField>(
              title: const Text('创作时间'),
              value: SortField.createTime,
              groupValue: state.sortOption.field,
              onChanged: (value) => Navigator.pop(
                context,
                SortOption(field: value!, order: state.sortOption.order),
              ),
            ),
            RadioListTile<SortField>(
              title: const Text('更新时间'),
              value: SortField.updateTime,
              groupValue: state.sortOption.field,
              onChanged: (value) => Navigator.pop(
                context,
                SortOption(field: value!, order: state.sortOption.order),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('降序排列'),
              value: state.sortOption.order == SortOrder.descending,
              onChanged: (value) => Navigator.pop(
                context,
                SortOption(
                  field: state.sortOption.field,
                  order: value ? SortOrder.descending : SortOrder.ascending,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      viewModel.setSortOption(result);
    }
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.read(workBrowseProvider);
    final currentFilter = state.filter;

    final selectedStyles = List<String>.from(currentFilter.styles);
    final selectedTools = List<String>.from(currentFilter.tools);
    var dateRange = currentFilter.dateRange;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('筛选条件'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('书法风格', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('楷书'),
                      selected: selectedStyles.contains('楷书'),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          selectedStyles.add('楷书');
                        } else {
                          selectedStyles.remove('楷书');
                        }
                      }),
                    ),
                    FilterChip(
                      label: const Text('行书'),
                      selected: selectedStyles.contains('行书'),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          selectedStyles.add('行书');
                        } else {
                          selectedStyles.remove('行书');
                        }
                      }),
                    ),
                    // Add more style chips...
                  ],
                ),
                const SizedBox(height: 16),
                const Text('书写工具', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('毛笔'),
                      selected: selectedTools.contains('毛笔'),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          selectedTools.add('毛笔');
                        } else {
                          selectedTools.remove('毛笔');
                        }
                      }),
                    ),
                    FilterChip(
                      label: const Text('硬笔'),
                      selected: selectedTools.contains('硬笔'),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          selectedTools.add('硬笔');
                        } else {
                          selectedTools.remove('硬笔');
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('创作时间', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  title: Text(dateRange != null 
                      ? '${_formatDate(dateRange!.start)} - ${_formatDate(dateRange!.end)}'
                      : '不限'),
                  trailing: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final newRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        initialDateRange: dateRange,
                      );
                      if (newRange != null) {
                        setState(() => dateRange = newRange);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                viewModel.updateFilter(const WorkFilter());
                Navigator.pop(context, false);
              },
              child: const Text('重置'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      viewModel.updateFilter(WorkFilter(
        styles: selectedStyles,
        tools: selectedTools,
        dateRange: dateRange,
      ));
    }
  }

  String _formatDate(DateTime date) => 
      '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';

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

  Widget _buildWorkGrid(WorkBrowseState state) {
    // Calculate grid layout based on screen width
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = switch (width) {
      < 600 => 1,  // Mobile
      < 900 => 2,  // Tablet portrait
      < 1200 => 3, // Tablet landscape
      < 1800 => 4, // Desktop
      _ => 5,      // Large desktop
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.works.length,
      itemBuilder: (context, index) => _WorkCard(
        work: state.works[index],
        onDelete: () => _deleteWork(state.works[index].id!),
      ),
    );
  }

  Future<void> _deleteWork(String workId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除作品'),
        content: const Text('确定要删除这个作品吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(workBrowseProvider.notifier).deleteWork(workId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('作品已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: ${e.toString()}')),
          );
        }
      }
    }
  }
}
class _WorkCard extends ConsumerWidget {
  final Work work;
  final VoidCallback onDelete;

  const _WorkCard({
    required this.work,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/work_detail',
          arguments: work.id,
        ),
        child: SizedBox(
          height: 280, // Fixed height for the card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with menu button
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverImage(ref),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _buildMenuButton(context),
                    ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildInfoSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(workBrowseProvider.notifier)
          .getWorkThumbnail(work.id!),
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

  Widget _buildMenuButton(BuildContext context) {
    return Material(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              // TODO: Implement edit
              break;
            case 'extract':
              // TODO: Implement character extraction
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('编辑'),
            ),
          ),
          const PopupMenuItem(
            value: 'extract',
            child: ListTile(
              leading: Icon(Icons.content_cut),
              title: Text('提取字'),
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('删除'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          work.name ?? '未命名',
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (work.author?.isNotEmpty ?? false) ...[
          Text(
            work.author!,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            if (work.style?.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  work.style!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const Spacer(),
            Text(
              '${work.imageCount}图',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}