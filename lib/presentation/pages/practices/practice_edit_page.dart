import 'package:flutter/material.dart';
import '../../widgets/window/title_bar.dart';
import '../../widgets/practice/practice_tool_panel.dart';
import '../../widgets/practice/practice_layer_panel.dart';
import '../../widgets/practice/practice_property_panel.dart';

class PracticeEditPage extends StatefulWidget {
  final String? practiceId; // 可选ID，如果为null则表示新建

  const PracticeEditPage({
    Key? key, 
    this.practiceId,
  }) : super(key: key);

  @override
  State<PracticeEditPage> createState() => _PracticeEditPageState();
}

class _PracticeEditPageState extends State<PracticeEditPage> {
  bool _hasUnsavedChanges = false;
  List<Map<String, dynamic>> _layers = [];
  Map<String, dynamic>? _selectedElement;

  @override
  void initState() {
    super.initState();
    // TODO: 加载字帖数据
    _layers = [
      {
        'id': '1',
        'name': '背景层',
        'visible': true,
        'locked': false,
        'selected': false,
      },
      {
        'id': '2',
        'name': '内容层',
        'visible': true,
        'locked': false,
        'selected': true,
      },
    ];
  }

  void _handleToolSelected(String tool) {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  void _handleLayerSelected(int index) {
    setState(() {
      for (var i = 0; i < _layers.length; i++) {
        _layers[i]['selected'] = i == index;
      }
    });
  }

  void _handleLayerVisibilityChanged(int index, bool visible) {
    setState(() {
      _layers[index]['visible'] = visible;
      _hasUnsavedChanges = true;
    });
  }

  void _handleLayerLockChanged(int index, bool locked) {
    setState(() {
      _layers[index]['locked'] = locked;
      _hasUnsavedChanges = true;
    });
  }

  void _handleLayerDeleted(int index) {
    setState(() {
      _layers.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _handleLayerReordered(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _layers.removeAt(oldIndex);
      _layers.insert(newIndex, item);
      _hasUnsavedChanges = true;
    });
  }

  void _handlePropertyChanged(Map<String, dynamic> updatedElement) {
    setState(() {
      _selectedElement = updatedElement;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _handleSave() async {
    // TODO: 实现保存逻辑
    setState(() => _hasUnsavedChanges = false);
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('有未保存的更改，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Column(
          children: [
            const TitleBar(),
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (await _onWillPop()) {
                    Navigator.pop(context);
                  }
                },
              ),
              title: Text(
                widget.practiceId == null ? '新建字帖' : '编辑字帖',
                style: const TextStyle(fontSize: 20),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print),
                  label: const Text('打印'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download),
                  label: const Text('导出'),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  // 左侧工具面板和图层列表
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        Expanded(
                          child: PracticeToolPanel(
                            onToolSelected: _handleToolSelected,
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: PracticeLayerPanel(
                            layers: _layers,
                            onLayerSelected: _handleLayerSelected,
                            onLayerVisibilityChanged: _handleLayerVisibilityChanged,
                            onLayerLockChanged: _handleLayerLockChanged,
                            onLayerDeleted: _handleLayerDeleted,
                            onLayerReordered: _handleLayerReordered,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // 中央编辑区
                  Expanded(
                    child: Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Container(
                          width: 595, // A4纸宽度
                          height: 842, // A4纸高度
                          color: Colors.white,
                          child: Stack(
                            children: [
                              // TODO: 实现画布和编辑功能
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // 右侧属性面板
                  SizedBox(
                    width: 280,
                    child: PracticePropertyPanel(
                      selectedElement: _selectedElement,
                      onPropertyChanged: _handlePropertyChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
