import 'package:flutter/material.dart';

/// 字符选择面板 - 用于集字内容属性面板的字形选择
class CharacterSelectionPanel extends StatefulWidget {
  final String character;
  final String? currentStyle;
  final Function(String style, String charId) onCharacterSelected;
  final VoidCallback onCancel;

  const CharacterSelectionPanel({
    Key? key,
    required this.character,
    this.currentStyle,
    required this.onCharacterSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CharacterSelectionPanel> createState() =>
      _CharacterSelectionPanelState();
}

class _CharacterSelectionPanelState extends State<CharacterSelectionPanel> {
  String _selectedStyle = '';
  String _searchKeyword = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _candidates = [];
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              Text(
                '选择"${widget.character}"的字形',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('取消'),
                onPressed: widget.onCancel,
              ),
            ],
          ),
        ),

        // 筛选工具栏
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              // 书法风格选择
              DropdownButton<String>(
                value: _selectedStyle,
                items: const [
                  DropdownMenuItem(value: '楷书', child: Text('楷书')),
                  DropdownMenuItem(value: '行书', child: Text('行书')),
                  DropdownMenuItem(value: '草书', child: Text('草书')),
                  DropdownMenuItem(value: '隶书', child: Text('隶书')),
                  DropdownMenuItem(value: '篆书', child: Text('篆书')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _changeStyle(value);
                  }
                },
              ),

              const SizedBox(width: 16),

              // 工具筛选
              DropdownButton<String>(
                value: '全部',
                items: const [
                  DropdownMenuItem(value: '全部', child: Text('全部')),
                  DropdownMenuItem(value: '硬笔', child: Text('硬笔')),
                  DropdownMenuItem(value: '毛笔', child: Text('毛笔')),
                ],
                onChanged: (value) {
                  // 工具类型筛选
                },
              ),

              const SizedBox(width: 16),

              // 搜索框
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '搜索...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _search,
                ),
              ),
            ],
          ),
        ),

        // 候选字形展示
        Expanded(
          child: _isLoading && _candidates.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _candidates.isEmpty
                  ? Center(
                      child: Text(
                        _searchKeyword.isEmpty
                            ? '没有找到"${widget.character}"的$_selectedStyle字形'
                            : '没有找到符合"$_searchKeyword"的$_selectedStyle字形',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _candidates.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // 显示加载指示器
                        if (index == _candidates.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final candidate = _candidates[index];
                        return _buildCandidateItem(candidate);
                      },
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.currentStyle ?? '楷书';
    _loadCharacterCandidates();

    // 监听滚动，实现滚动加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreCandidates();
      }
    });
  }

  /// 构建候选字形项
  Widget _buildCandidateItem(Map<String, dynamic> candidate) {
    return InkWell(
      onTap: () {
        widget.onCharacterSelected(_selectedStyle, candidate['id']);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // 字符预览
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                alignment: Alignment.center,
                child: Text(
                  widget.character,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 字形信息
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    candidate['style'],
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    candidate['author'],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换字体风格
  void _changeStyle(String style) {
    if (_selectedStyle != style) {
      setState(() {
        _selectedStyle = style;
      });
      _loadCharacterCandidates();
    }
  }

  /// 加载字符候选项
  Future<void> _loadCharacterCandidates() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });

    try {
      // 实际应用中应从API或数据库加载数据
      // 这里使用模拟数据
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _candidates = List.generate(16, (index) {
          return {
            'id': 'char_${widget.character}_${_selectedStyle}_$index',
            'character': widget.character,
            'style': _selectedStyle,
            'author': '作者$index',
            'dynasty': index % 2 == 0 ? '唐代' : '宋代',
            'previewUrl': 'https://example.com/char_$index.png', // 实际应用中应是真实URL
          };
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _candidates = [];
      });
      _showErrorSnackBar('加载候选字形失败: $e');
    }
  }

  /// 加载更多候选项
  Future<void> _loadMoreCandidates() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _page++;
    });

    try {
      // 实际应用中应从API或数据库加载更多数据
      await Future.delayed(const Duration(milliseconds: 500));

      final newCandidates = List.generate(8, (index) {
        final realIndex = _candidates.length + index;
        return {
          'id': 'char_${widget.character}_${_selectedStyle}_$realIndex',
          'character': widget.character,
          'style': _selectedStyle,
          'author': '作者$realIndex',
          'dynasty': realIndex % 2 == 0 ? '唐代' : '宋代',
          'previewUrl': 'https://example.com/char_$realIndex.png',
        };
      });

      setState(() {
        _candidates.addAll(newCandidates);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('加载更多候选字形失败: $e');
    }
  }

  /// 搜索
  void _search(String keyword) {
    setState(() {
      _searchKeyword = keyword;
    });
    // 实际应用中应该根据关键词重新加载数据
    _loadCharacterCandidates();
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
