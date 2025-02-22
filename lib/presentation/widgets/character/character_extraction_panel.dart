import 'package:flutter/material.dart';

class CharacterExtractionPanel extends StatefulWidget {
  final String workId;
  final int imageIndex;
  
  const CharacterExtractionPanel({
    super.key,
    required this.workId,
    required this.imageIndex,
  });

  @override
  State<CharacterExtractionPanel> createState() => _CharacterExtractionPanelState();
}

class _CharacterExtractionPanelState extends State<CharacterExtractionPanel> {
  bool _autoRecognitionEnabled = true;
  double _noiseReduction = 0.5;
  double _binarization = 0.5;
  double _grayScale = 0.5;
  String _selectedTool = 'select'; // select, rect, lasso
  final List<Rect> _selectedRegions = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _pages = []; // 存储所有页面的图片路径

  @override
  void initState() {
    super.initState();
    // TODO: 加载实际的页面数据
    _pages = List.generate(5, (index) => 'Page ${index + 1}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          _buildTopToolbar(),
          Expanded(
            child: Row(
              children: [
                _buildLeftToolbar(),
                Expanded(
                  child: _buildPreviewArea(),
                ),
                _buildRightPanel(),
              ],
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: '退出',
          ),
          const VerticalDivider(),
          // 预处理工具组
          Row(
            children: [
              Switch(
                value: _autoRecognitionEnabled,
                onChanged: (value) => setState(() => _autoRecognitionEnabled = value),
              ),
              const Text('自动识别笔画'),
              const SizedBox(width: 16),
              _buildSlider('降噪', _noiseReduction),
              _buildSlider('二值化', _binarization),
              _buildSlider('灰度范围', _grayScale),
              TextButton(
                onPressed: _resetPreprocess,
                child: const Text('重置'),
              ),
            ],
          ),
          const Spacer(),
          // 操作工具组
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSelection,
            tooltip: '清空选择',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
            tooltip: '重做',
          ),
        ],
      ),
    );
  }

  Widget _buildLeftToolbar() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // 选择工具
          IconButton(
            icon: const Icon(Icons.touch_app),
            onPressed: () => setState(() => _selectedTool = 'select'),
            isSelected: _selectedTool == 'select',
            tooltip: '点击选择',
          ),
          IconButton(
            icon: const Icon(Icons.crop_square),
            onPressed: () => setState(() => _selectedTool = 'rect'),
            isSelected: _selectedTool == 'rect',
            tooltip: '矩形框选',
          ),
          IconButton(
            icon: const Icon(Icons.gesture),
            onPressed: () => setState(() => _selectedTool = 'lasso'),
            isSelected: _selectedTool == 'lasso',
            tooltip: '套索选择',
          ),
          const Divider(),
          // 视图工具
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: '放大',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: '缩小',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Column(
      children: [
        // 工具栏
        // ...existing code...

        // 主预览区（支持左右滑动）
        Expanded(
          child: Row(
            children: [
              // 左翻页按钮
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              // 中央预览区
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: Text('${_pages[index]} 预览区域'),
                          ),
                        );
                      },
                    ),
                    // 页码指示器
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentPage + 1} / ${_pages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 右翻页按钮
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _pages.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
        // 底部缩略图导航栏
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final isSelected = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text('${index + 1}'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // 结果预览
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('集字预览'),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Center(
                        child: Text('预览结果'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // 登记信息
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: '简体字 *',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 1,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '风格',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kai', child: Text('楷书')),
                    DropdownMenuItem(value: 'xing', child: Text('行书')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '工具',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'brush', child: Text('毛笔')),
                    DropdownMenuItem(value: 'pen', child: Text('硬笔')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveCharacter,
                  child: const Text('保存集字'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text('当前工具: $_selectedTool'),
          const Spacer(),
          Text('已选择区域: ${_selectedRegions.length}'),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        SizedBox(
          width: 100,
          child: Slider(
            value: value,
            onChanged: (v) => setState(() {
              switch (label) {
                case '降噪':
                  _noiseReduction = v;
                  break;
                case '二值化':
                  _binarization = v;
                  break;
                case '灰度范围':
                  _grayScale = v;
                  break;
              }
            }),
          ),
        ),
      ],
    );
  }

  void _resetPreprocess() {
    setState(() {
      _noiseReduction = 0.5;
      _binarization = 0.5;
      _grayScale = 0.5;
    });
  }

  void _clearSelection() {
    setState(() => _selectedRegions.clear());
  }

  void _undo() {
    // TODO: 实现撤销功能
  }

  void _redo() {
    // TODO: 实现重做功能
  }

  void _zoomIn() {
    // TODO: 实现放大功能
  }

  void _zoomOut() {
    // TODO: 实现缩小功能
  }

  void _handleTap(TapDownDetails details) {
    // TODO: 实现点击选择功能
  }

  void _handlePanStart(DragStartDetails details) {
    // TODO: 实现拖动开始
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // TODO: 实现拖动更新
  }

  void _handlePanEnd(DragEndDetails details) {
    // TODO: 实现拖动结束
  }

  void _saveCharacter() {
    // TODO: 实现保存集字功能
  }
}

class CharacterExtractionPainter extends CustomPainter {
  final List<Rect> regions;
  final String currentTool;

  CharacterExtractionPainter({
    required this.regions,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: 实现绘制功能
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
