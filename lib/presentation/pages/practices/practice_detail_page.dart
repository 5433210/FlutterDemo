import 'package:demo/domain/value_objects/practice/page_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/practice.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../routes/app_routes.dart';
import '../../providers/practice_detail_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/toolbar_action_button.dart';
import '../../widgets/page_layout.dart';
import 'components/practice_page_viewer.dart';

class PracticeDetailPage extends ConsumerStatefulWidget {
  final String practiceId;

  const PracticeDetailPage({super.key, required this.practiceId});

  @override
  ConsumerState<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends ConsumerState<PracticeDetailPage> {
  late final PracticeDetailNotifier _notifier;
  bool _isLoading = true;
  Practice? _practice;
  String? _errorMessage;
  int _currentPageIndex = 0;

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
    _notifier = ref.read(practiceDetailProvider.notifier);
    _loadPractice();
  }

  List<Widget> _buildActions() {
    if (_practice == null) return [];

    return [
      ToolbarActionButton(
        tooltip: '编辑练习',
        onPressed: _navigateToEdit,
        child: const Icon(Icons.edit),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'delete') {
            _confirmDelete();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Text('删除练习'),
          ),
        ],
      ),
    ];
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: '加载练习中...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPractice,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_practice == null) {
      return const Center(
        child: Text('练习不存在或已被删除'),
      );
    }

    return _buildPracticeContent(_practice!);
  }

  Widget _buildPageSelector(List<PracticePageInfo> pages) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(pages[index].title),
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

  Widget _buildPracticeContent(Practice practice) {
    final pages = practice.pages;
    if (pages.isEmpty) {
      return const Center(
        child: Text('此练习没有页面'),
      );
    }

    return Column(
      children: [
        // Page selector
        if (pages.length > 1) _buildPageSelector(pages),

        // Practice page content
        Expanded(
          child: PracticePageViewer(
            page: pages[_currentPageIndex],
            readOnly: true,
          ),
        ),

        // Practice metadata
        _buildPracticeMetadata(practice),
      ],
    );
  }

  Widget _buildPracticeMetadata(Practice practice) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Title area
        Expanded(
          child: _practice != null
              ? Row(
                  children: [
                    Flexible(
                      child: Text(
                        _practice!.title,
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_practice!.pages.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_practice!.pages.length}页',
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                )
              : Text('练习详情', style: theme.textTheme.titleLarge),
        ),

        // Actions
        if (_practice != null) ...[
          ToolbarActionButton(
            tooltip: '编辑练习',
            onPressed: _navigateToEdit,
            child: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除练习'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除练习'),
        content: Text('确定要删除练习"${_practice!.title}"吗？此操作不可撤销。'),
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
      setState(() {
        _isLoading = true;
      });

      final success = await _notifier.deletePractice(widget.practiceId);

      if (success && mounted) {
        Navigator.of(context).pop(); // Return to previous screen
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '删除失败';
        });
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
        setState(() {
          _isLoading = false;
          _errorMessage = '删除失败: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPractice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final practice = await _notifier.getPractice(widget.practiceId);

      if (mounted) {
        setState(() {
          _practice = practice;
          _isLoading = false;
          _currentPageIndex = 0;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load practice',
        tag: 'PracticeDetailPage',
        error: e,
        stackTrace: stack,
        data: {'id': widget.practiceId},
      );

      if (mounted) {
        setState(() {
          _errorMessage = '无法加载练习: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEdit() {
    Navigator.pushNamed(
      context,
      AppRoutes.practiceEdit,
      arguments: widget.practiceId,
    ).then((_) => _loadPractice()); // Refresh after edit
  }
}
