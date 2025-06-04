import 'package:flutter/material.dart';

import '../../../widgets/practice/element_snapshot.dart';

/// 这个文件演示如何使用ElementSnapshot系统
/// 此示例可以作为集成参考，展示了ElementSnapshot的基本用法
class ElementSnapshotExample extends StatefulWidget {
  const ElementSnapshotExample({Key? key}) : super(key: key);

  @override
  State<ElementSnapshotExample> createState() => _ElementSnapshotExampleState();
}

class _ElementSnapshotExampleState extends State<ElementSnapshotExample> {
  // 创建快照管理器
  final ElementSnapshotManager _snapshotManager = ElementSnapshotManager(
    config: const ElementSnapshotConfig(
      enableWidgetCaching: true,
      enableImageCaching: false,
      maxCacheSize: 50,
    ),
  );

  // 模拟元素数据
  final List<Map<String, dynamic>> _sampleElements = [
    {
      'id': 'element1',
      'x': 100.0,
      'y': 100.0,
      'width': 150.0,
      'height': 80.0,
      'type': 'text',
      'text': '示例文本元素',
      'fontSize': 18.0,
    },
    {
      'id': 'element2',
      'x': 300.0,
      'y': 150.0,
      'width': 120.0,
      'height': 120.0,
      'type': 'image',
      'url': 'https://example.com/image.jpg',
    },
  ];

  // 跟踪拖拽状态
  bool _isDragging = false;
  String? _currentDragId;
  Offset _dragStartPosition = Offset.zero;
  Offset _dragCurrentPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ElementSnapshot 示例')),
      body: Column(
        children: [
          // 状态信息
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '拖拽状态: ${_isDragging ? "拖拽中" : "未拖拽"}\n'
              '当前快照数: ${_snapshotManager.getAllSnapshots().length}',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // 元素容器
          Expanded(
            child: GestureDetector(
              onPanStart: _handleDragStart,
              onPanUpdate: _handleDragUpdate,
              onPanEnd: _handleDragEnd,
              child: Container(
                color: Colors.grey.shade200,
                child: Stack(
                  children: [
                    // 渲染所有元素
                    ..._sampleElements.map((element) {
                      final id = element['id'] as String;
                      final x = (element['x'] as num).toDouble();
                      final y = (element['y'] as num).toDouble();

                      // 对于拖拽中的元素，使用快照位置
                      Offset position = Offset(x, y);
                      if (_isDragging && id == _currentDragId) {
                        final snapshot = _snapshotManager.getSnapshot(id);
                        if (snapshot != null) {
                          // 使用快照中存储的位置
                          position = Offset(
                            (snapshot.properties['x'] as num).toDouble(),
                            (snapshot.properties['y'] as num).toDouble(),
                          );
                        }
                      }

                      return Positioned(
                        left: position.dx,
                        top: position.dy,
                        child: _buildElement(element),
                      );
                    }),

                    // 显示性能信息
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          '内存: ${_snapshotManager.getMemoryStats()['memoryEstimateKB']} KB',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 控制按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _createSnapshots,
                  child: const Text('创建快照'),
                ),
                ElevatedButton(
                  onPressed: _clearSnapshots,
                  child: const Text('清除快照'),
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
    // 释放资源
    _snapshotManager.dispose();
    super.dispose();
  }

  // 构建元素UI
  Widget _buildElement(Map<String, dynamic> element) {
    final type = element['type'] as String;
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    Widget content;

    switch (type) {
      case 'text':
        final text = element['text'] as String;
        final fontSize = (element['fontSize'] as num).toDouble();
        content = Center(
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize),
          ),
        );
        break;
      case 'image':
        content = const Center(
          child: Icon(Icons.image, size: 40),
        );
        break;
      default:
        content = Center(
          child: Text('未知类型: $type'),
        );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        color: Colors.white,
      ),
      child: content,
    );
  }

  // 清除所有快照
  void _clearSnapshots() {
    _snapshotManager.clearSnapshots();
    setState(() {});
  }

  // 创建元素快照
  Future<void> _createSnapshots() async {
    await _snapshotManager.createSnapshots(_sampleElements);
    setState(() {});
  }

  // 处理拖拽结束
  void _handleDragEnd(DragEndDetails details) {
    if (_isDragging && _currentDragId != null) {
      // 获取最终的快照位置
      final snapshot = _snapshotManager.getSnapshot(_currentDragId!);
      if (snapshot != null) {
        // 更新元素实际位置
        final index =
            _sampleElements.indexWhere((e) => e['id'] == _currentDragId);
        if (index >= 0) {
          setState(() {
            _sampleElements[index]['x'] = snapshot.properties['x'];
            _sampleElements[index]['y'] = snapshot.properties['y'];
          });
        }
      }

      setState(() {
        _isDragging = false;
        _currentDragId = null;
      });
    }
  }

  // 处理拖拽开始
  void _handleDragStart(DragStartDetails details) {
    // 找出点击的元素
    final position = details.localPosition;
    String? hitElementId;

    for (final element in _sampleElements) {
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      if (position.dx >= x &&
          position.dx <= x + width &&
          position.dy >= y &&
          position.dy <= y + height) {
        hitElementId = element['id'] as String;
        break;
      }
    }

    if (hitElementId != null) {
      // 找到点击的元素，创建快照
      final elements =
          _sampleElements.where((e) => e['id'] == hitElementId).toList();

      _snapshotManager.createSnapshots(elements);

      setState(() {
        _isDragging = true;
        _currentDragId = hitElementId;
        _dragStartPosition = position;
        _dragCurrentPosition = position;
      });
    }
  }

  // 处理拖拽更新
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDragging && _currentDragId != null) {
      // 计算拖拽位移
      final delta = details.localPosition - _dragCurrentPosition;
      _dragCurrentPosition = details.localPosition;

      // 查找当前元素的快照
      final snapshot = _snapshotManager.getSnapshot(_currentDragId!);
      if (snapshot != null) {
        // 计算新位置
        final currentX = (snapshot.properties['x'] as num).toDouble();
        final currentY = (snapshot.properties['y'] as num).toDouble();
        final newX = currentX + delta.dx;
        final newY = currentY + delta.dy;

        // 更新快照位置
        _snapshotManager.updateSnapshotPosition(
          _currentDragId!,
          Offset(newX, newY),
        );

        // 触发重绘
        setState(() {});
      }
    }
  }
}
