import 'dart:convert';

import 'package:demo/routes/app_routes.dart';
import 'package:flutter/foundation.dart';
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
  final List<Map<String, dynamic>> _filteredPractices = [];

  // Loading and error states
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 如果有错误且是第一次构建后显示，使用WidgetsBinding.instance.addPostFrameCallback
    if (_hasError) {
      // 使用addPostFrameCallback确保在构建完成后显示SnackBar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage)),
          );
          // 重置错误状态，避免重复显示
          setState(() {
            _hasError = false;
          });
        }
      });
    }

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
        trailing: [
          SizedBox(
            width: 240,
            child: SearchBar(
              controller: _searchController,
              hintText: '搜索练习...',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
              ),
              onChanged: _searchPractices,
              trailing: [
                _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchPractices('');
                        },
                      )
                    : const SizedBox.shrink(),
              ],
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      itemCount: _filteredPractices.length,
      itemBuilder: (context, index) {
        final practice = _filteredPractices[index];
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
      itemCount: _filteredPractices.length,
      itemBuilder: (context, index) {
        final practice = _filteredPractices[index];
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
  String _formatDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return '';

    try {
      DateTime dateTime;

      if (dateTimeValue is String) {
        // 处理字符串格式的日期
        dateTime = DateTime.parse(dateTimeValue);
      } else if (dateTimeValue is DateTime) {
        // 直接使用DateTime对象
        dateTime = dateTimeValue;
      } else {
        // 其他类型，返回空字符串
        return '';
      }

      // 格式化为 YYYY-MM-DD
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('格式化日期时间失败: $e');
      // 如果是字符串，直接返回；否则返回空字符串
      return dateTimeValue is String ? dateTimeValue : '';
    }
  }

  // Helper method to get first page preview image if available
  Uint8List? _getFirstPagePreview(Map<String, dynamic> practice) {
    // If there's a thumbnail field with image data, use it
    if (practice.containsKey('thumbnail') && practice['thumbnail'] != null) {
      // Handle case where thumbnail is already a Uint8List
      if (practice['thumbnail'] is Uint8List) {
        return practice['thumbnail'];
      }
      // Handle case where thumbnail is a base64 encoded string
      else if (practice['thumbnail'] is String &&
          practice['thumbnail'].isNotEmpty) {
        try {
          return base64Decode(practice['thumbnail']);
        } catch (e) {
          debugPrint('Failed to decode thumbnail: $e');
          return null;
        }
      }
    }
    return null;
  }

  // Load practices from the service
  Future<void> _loadPractices() async {
    setState(() {
      _isLoading = true;
      _hasError = false; // 重置错误状态
    });

    try {
      final practiceService = ref.read(practiceServiceProvider);
      final practicesResult = await practiceService.getAllPractices();

      // 将PracticeEntity列表转换为Map<String, dynamic>列表，使用安全的方式处理
      final List<Map<String, dynamic>> practicesMap = [];

      for (final practice in practicesResult) {
        try {
          // 手动构建基本信息，避免复杂对象序列化问题
          final Map<String, dynamic> practiceMap = {
            'id': practice.id,
            'title': practice.title,
            'status': practice.status,
            'createTime': practice.createTime.toIso8601String(),
            'updateTime': practice.updateTime.toIso8601String(),
            'thumbnail': practice.thumbnail,
            'pageCount': practice.pages.length,
          };
          practicesMap.add(practiceMap);
        } catch (e) {
          debugPrint('转换练习实体失败: $e');
          // 继续处理下一个实体
        }
      }

      if (mounted) {
        setState(() {
          _practices = practicesMap;
          _filteredPractices.clear();
          _filteredPractices.addAll(practicesMap);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      // Handle error with more details
      debugPrint('加载字帖失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true; // 设置错误状态
          _errorMessage = '加载字帖失败: $e'; // 保存错误信息
        });

        // 不在initState中使用ScaffoldMessenger，而是在build方法中显示错误
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

  // Search practices by title
  void _searchPractices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPractices.clear();
        _filteredPractices.addAll(_practices);
      } else {
        _filteredPractices.clear();
        _filteredPractices.addAll(_practices.where((practice) {
          final title = practice['title'] as String? ?? '';
          return title.toLowerCase().contains(query.toLowerCase());
        }));
      }
    });
  }
}
