import 'dart:convert';
import 'dart:typed_data';

import 'package:demo/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../theme/app_sizes.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/page_toolbar.dart';

class PracticeListPage extends ConsumerStatefulWidget {
  const PracticeListPage({super.key});

  @override
  ConsumerState<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends ConsumerState<PracticeListPage> {
  bool _isGridView = true;

  // List to store practices data
  List<Map<String, dynamic>> _practices = [];

  // Loading state
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      toolbar: PageToolbar(
        leading: [
          FilledButton.icon(
            onPressed: () => _navigateToEditPage(),
            icon: const Icon(Icons.add),
            label: const Text('新建练习'),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            tooltip: _isGridView ? '列表视图' : '网格视图',
          ),
        ],
        trailing: const [
          SizedBox(
            width: 240,
            child: SearchBar(
              hintText: '搜索练习...',
              leading: Icon(Icons.search),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_isGridView ? _buildGridView() : _buildListView()),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load practices when the page is initialized
    _loadPractices();
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.gridCrossAxisCount,
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,
        childAspectRatio: 1,
      ),
      itemCount: _practices.length,
      itemBuilder: (context, index) {
        final practice = _practices[index];
        return Card(
          child: InkWell(
            onTap: () {
              _navigateToPracticeDetail(context, practice['id']);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.grey[300],
                        child: Center(child: Text(practice['title'] ?? '')),
                      ),
                      if (_getFirstPagePreview(practice) != null)
                        Positioned.fill(
                          child: Image.memory(
                            _getFirstPagePreview(practice)!,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(practice['title'] ?? '',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('最后更新: ${_formatDateTime(practice['updateTime'])}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      itemCount: _practices.length,
      itemBuilder: (context, index) {
        final practice = _practices[index];
        return Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: _getFirstPagePreview(practice) != null
                  ? Image.memory(
                      _getFirstPagePreview(practice)!,
                      fit: BoxFit.cover,
                    )
                  : Center(child: Text('${index + 1}')),
            ),
            title: Text(practice['title'] ?? ''),
            subtitle: Text('最后更新: ${_formatDateTime(practice['updateTime'])}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _navigateToPracticeDetail(context, practice['id']);
            },
          ),
        );
      },
    );
  }

  // Helper method to format date time string
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  // Helper method to get first page preview image if available
  Uint8List? _getFirstPagePreview(Map<String, dynamic> practice) {
    // If there's a thumbnail field with image data, use it
    if (practice.containsKey('thumbnail') &&
        practice['thumbnail'] != null &&
        practice['thumbnail'] is String &&
        practice['thumbnail'].isNotEmpty) {
      try {
        return base64Decode(practice['thumbnail']);
      } catch (e) {
        // Failed to decode thumbnail
        return null;
      }
    }
    return null;
  }

  // Load practices from the service
  Future<void> _loadPractices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final practiceService = ref.read(practiceServiceProvider);
      final practices = await practiceService.getAllPractices();

      setState(() {
        _practices = practices;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载字帖失败: $e')),
        );
      }
    }
  }

  void _navigateToEditPage([String? practiceId]) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.practiceEdit,
      arguments: practiceId,
    );

    // 在返回时刷新字帖列表
    _loadPractices();
  }

  void _navigateToPracticeDetail(BuildContext context, String practiceId) {
    _navigateToEditPage(practiceId);
  }
}
