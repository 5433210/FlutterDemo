import 'dart:convert';

import 'package:demo/routes/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/models/practice/practice_filter.dart';
import '../../../theme/app_sizes.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/page_toolbar.dart';
import '../../widgets/pagination/pagination_controls.dart';

class PracticeListPage extends ConsumerStatefulWidget {
  const PracticeListPage({super.key});

  @override
  ConsumerState<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends ConsumerState<PracticeListPage> {
  bool _isGridView = true;
  bool _isBatchMode = false; // 批量选择模式
  final Set<String> _selectedPractices = {}; // 已选中的字帖ID

  // List to store practices data
  List<Map<String, dynamic>> _practices = [];
  final List<Map<String, dynamic>> _filteredPractices = [];

  // Loading and error states
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // 分页相关
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalItems = 0;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;

  // 排序相关
  String _sortField = 'updateTime'; // 默认按更新时间排序
  String _sortOrder = 'desc'; // 默认降序排序

  // 调试信息
  final bool _debugMode = true; // 开启调试模式

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

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
          const SizedBox(width: AppSizes.spacingMedium),
          // 批量操作按钮
          IconButton(
            onPressed: () => _toggleBatchMode(),
            icon: Icon(_isBatchMode ? Icons.cancel : Icons.select_all),
            tooltip: _isBatchMode ? '取消批量操作' : '批量操作',
          ),
          if (_isBatchMode && _selectedPractices.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmDeleteSelected,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: Text('删除所选(${_selectedPractices.length})'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
        trailing: [
          // 排序下拉菜单
          DropdownButton<String>(
            value: _sortField,
            items: [
              DropdownMenuItem(
                value: 'updateTime',
                child: Text('按更新时间${_sortOrder == 'desc' ? '↓' : '↑'}'),
              ),
              DropdownMenuItem(
                value: 'createTime',
                child: Text('按创建时间${_sortOrder == 'desc' ? '↓' : '↑'}'),
              ),
              DropdownMenuItem(
                value: 'title',
                child: Text('按标题${_sortOrder == 'desc' ? '↓' : '↑'}'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  if (_sortField == value) {
                    // 如果选择了相同的字段，切换排序方向
                    _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
                  } else {
                    // 如果选择了不同的字段，设置为默认排序方向（降序）
                    _sortField = value;
                    _sortOrder = 'desc';
                  }
                });
                _loadPractices();
              }
            },
          ),
          const SizedBox(width: AppSizes.spacingMedium),
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_isGridView ? _buildGridView() : _buildListView()),
          ),
          // 分页控件
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('共 $_totalItems 条记录，当前第 $_currentPage 页'),
                  const SizedBox(width: 16),
                  PaginationControls(
                    currentPage: _currentPage,
                    pageSize: _pageSize,
                    totalItems: _totalItems,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                      _loadPractices();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 添加滚动监听器，用于实现滚动加载更多
    _scrollController.addListener(_scrollListener);
    // Load practices when the page is initialized
    _loadPractices();
  }

  Widget _buildGridView() {
    if (_filteredPractices.isEmpty) {
      return const Center(child: Text('没有找到字帖'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSizes.gridCrossAxisCount,
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,
        childAspectRatio: 1,
      ),
      itemCount: _filteredPractices.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (index == _filteredPractices.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final practice = _filteredPractices[index];
        final isSelected = _selectedPractices.contains(practice['id']);

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () {
              if (_isBatchMode) {
                _togglePracticeSelection(practice['id']);
              } else {
                _navigateToPracticeDetail(context, practice['id']);
              }
            },
            onLongPress: () {
              if (!_isBatchMode) {
                setState(() {
                  _isBatchMode = true;
                  _togglePracticeSelection(practice['id']);
                });
              }
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
                      // 批量选择模式下显示选择指示器
                      if (_isBatchMode)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? Colors.blue : Colors.grey,
                              size: 24,
                            ),
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
                      Text(
                        practice['title'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '最后更新: ${_formatDateTime(practice['updateTime'])}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${practice['pageCount'] ?? 0}页',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
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
    if (_filteredPractices.isEmpty) {
      return const Center(child: Text('没有找到字帖'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      itemCount: _filteredPractices.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (index == _filteredPractices.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final practice = _filteredPractices[index];
        final isSelected = _selectedPractices.contains(practice['id']);

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _getFirstPagePreview(practice) != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            _getFirstPagePreview(practice)!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(child: Text('${index + 1}')),
                ),
                // 批量选择模式下显示选择指示器
                if (_isBatchMode)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              practice['title'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最后更新: ${_formatDateTime(practice['updateTime'])}'),
                Text('${practice['pageCount'] ?? 0}页'),
              ],
            ),
            trailing: _isBatchMode ? null : const Icon(Icons.chevron_right),
            onTap: () {
              if (_isBatchMode) {
                _togglePracticeSelection(practice['id']);
              } else {
                _navigateToPracticeDetail(context, practice['id']);
              }
            },
            onLongPress: () {
              if (!_isBatchMode) {
                setState(() {
                  _isBatchMode = true;
                  _togglePracticeSelection(practice['id']);
                });
              }
            },
          ),
        );
      },
    );
  }

  // 确认删除所选字帖
  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除所选的${_selectedPractices.length}个字帖吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelectedPractices();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 删除所选字帖
  Future<void> _deleteSelectedPractices() async {
    if (_selectedPractices.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final practiceService = ref.read(practiceServiceProvider);
      await practiceService.deletePractices(_selectedPractices.toList());

      setState(() {
        _isLoading = false;
        _isBatchMode = false;
        _selectedPractices.clear();
      });

      // 重新加载字帖列表
      _loadPractices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '删除字帖失败: $e';
      });
    }
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

  // 加载更多字帖
  Future<void> _loadMorePractices() async {
    if (!_hasMoreItems || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final filter = PracticeFilter(
        sortField: _sortField,
        sortOrder: _sortOrder,
        limit: _pageSize,
        offset: (nextPage - 1) * _pageSize,
      );

      final practiceService = ref.read(practiceServiceProvider);
      final practicesResult = await practiceService.queryPractices(filter);

      if (practicesResult.isEmpty) {
        setState(() {
          _hasMoreItems = false;
          _isLoadingMore = false;
        });
        return;
      }

      // 将PracticeEntity列表转换为Map<String, dynamic>列表
      final List<Map<String, dynamic>> practicesMap = [];
      for (final practice in practicesResult) {
        try {
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
        }
      }

      if (mounted) {
        setState(() {
          _practices.addAll(practicesMap);
          _filteredPractices.addAll(practicesMap);
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('加载更多字帖失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // Load practices from the service
  Future<void> _loadPractices() async {
    setState(() {
      _isLoading = true;
      _hasError = false; // 重置错误状态
    });

    try {
      final practiceService = ref.read(practiceServiceProvider);

      // 创建过滤器，包含排序和分页参数
      final filter = PracticeFilter(
        sortField: _sortField,
        sortOrder: _sortOrder,
        limit: _pageSize,
        offset: (_currentPage - 1) * _pageSize,
      );

      if (_debugMode) {
        debugPrint('加载字帖，排序字段: ${filter.sortField}, 排序方向: ${filter.sortOrder}');
        debugPrint(
            '分页参数: 页码=$_currentPage, 每页数量=$_pageSize, 偏移量=${(_currentPage - 1) * _pageSize}');
      }

      // 使用过滤器查询字帖
      var practicesResult = [];
      try {
        practicesResult = await practiceService.queryPractices(filter);
        if (_debugMode) {
          debugPrint('查询结果: ${practicesResult.length} 条记录');
          if (practicesResult.isNotEmpty) {
            final first = practicesResult.first;
            debugPrint('第一条记录: id=${first.id}, title=${first.title}');
            debugPrint('排序字段值: ${first.updateTime}');
          }
        }
      } catch (e) {
        debugPrint('查询字帖失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('查询字帖失败: $e')),
          );
        }
      }

      // 获取总数量
      int totalCount = 0;
      try {
        totalCount = await practiceService.count(filter);
        if (_debugMode) {
          debugPrint('总记录数: $totalCount');
        }
      } catch (e) {
        debugPrint('获取总记录数失败: $e');
      }

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
          _totalItems = totalCount;
          _hasMoreItems = _practices.length < _totalItems;
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

  // 滚动监听器，用于实现滚动加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreItems && !_isLoadingMore) {
        _loadMorePractices();
      }
    }
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

  // 切换批量选择模式
  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      if (!_isBatchMode) {
        _selectedPractices.clear();
      }
    });
  }

  // 切换字帖选择状态
  void _togglePracticeSelection(String id) {
    setState(() {
      if (_selectedPractices.contains(id)) {
        _selectedPractices.remove(id);
      } else {
        _selectedPractices.add(id);
      }
    });
  }
}
