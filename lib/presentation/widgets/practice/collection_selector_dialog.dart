import 'package:flutter/material.dart';

import 'collection_manager.dart';

/// 集字选择对话框
class CollectionSelectorDialog extends StatefulWidget {
  /// 初始查询
  final String initialQuery;
  
  /// 构造函数
  const CollectionSelectorDialog({
    Key? key,
    required this.initialQuery,
  }) : super(key: key);
  
  @override
  State<CollectionSelectorDialog> createState() => _CollectionSelectorDialogState();
}

class _CollectionSelectorDialogState extends State<CollectionSelectorDialog> {
  // 集字管理器
  final CollectionManager _collectionManager = CollectionManager();
  
  // 搜索控制器
  late final TextEditingController _searchController;
  
  // 当前查询
  late String _query;
  
  // 当前风格
  String? _selectedStyle;
  
  // 当前工具
  String? _selectedTool;
  
  // 集字列表
  List<Map<String, dynamic>> _collectionItems = [];
  
  // 是否正在加载
  bool _isLoading = false;
  
  // 是否已加载全部
  bool _hasReachedEnd = false;
  
  // 当前页码
  int _currentPage = 0;
  
  // 每页数量
  final int _pageSize = 20;
  
  // 选中的集字
  final List<Map<String, dynamic>> _selectedItems = [];
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    
    // 加载初始数据
    _loadCollectionItems();
    
    // 添加滚动监听
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            const Text(
              '选择集字内容',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 搜索和筛选
            Row(
              children: [
                // 搜索框
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '搜索',
                      hintText: '输入汉字',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _query = value;
                        _currentPage = 0;
                        _collectionItems = [];
                        _hasReachedEnd = false;
                      });
                      _loadCollectionItems();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // 风格筛选
                DropdownButton<String>(
                  hint: const Text('风格'),
                  value: _selectedStyle,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('全部风格'),
                    ),
                    ..._collectionManager.getCollectionStyles().map((style) {
                      return DropdownMenuItem<String>(
                        value: style,
                        child: Text(style),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStyle = value;
                      _currentPage = 0;
                      _collectionItems = [];
                      _hasReachedEnd = false;
                    });
                    _loadCollectionItems();
                  },
                ),
                const SizedBox(width: 16),
                
                // 工具筛选
                DropdownButton<String>(
                  hint: const Text('工具'),
                  value: _selectedTool,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('全部工具'),
                    ),
                    ..._collectionManager.getCollectionTools().map((tool) {
                      return DropdownMenuItem<String>(
                        value: tool,
                        child: Text(tool),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTool = value;
                      _currentPage = 0;
                      _collectionItems = [];
                      _hasReachedEnd = false;
                    });
                    _loadCollectionItems();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 集字列表
            Expanded(
              child: _buildCollectionList(),
            ),
            const SizedBox(height: 16),
            
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('已选择 ${_selectedItems.length} 项'),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedItems.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selectedItems),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建集字列表
  Widget _buildCollectionList() {
    if (_isLoading && _collectionItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_collectionItems.isEmpty) {
      return const Center(
        child: Text('没有找到匹配的集字内容'),
      );
    }
    
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _collectionItems.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _collectionItems.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final item = _collectionItems[index];
        final isSelected = _selectedItems.any((selected) => selected['id'] == item['id']);
        
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedItems.removeWhere((selected) => selected['id'] == item['id']);
              } else {
                _selectedItems.add(item);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // 集字内容
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 字符图片
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/placeholder.png', // 实际应用中应该使用item['thumbnailUrl']
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                      // 字符信息
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          children: [
                            Text(
                              item['character'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${item['style']} - ${item['author']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 选中标记
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 加载集字内容
  Future<void> _loadCollectionItems() async {
    if (_isLoading || _hasReachedEnd) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await _collectionManager.getCollectionItems(
        _query,
        style: _selectedStyle,
        tool: _selectedTool,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      
      setState(() {
        _collectionItems.addAll(items);
        _currentPage++;
        _hasReachedEnd = items.length < _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }
  
  /// 滚动监听
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadCollectionItems();
    }
  }
}
