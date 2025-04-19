import 'package:flutter/material.dart';

import 'practice_edit_controller.dart';

/// 属性面板组件
class PracticePropertyPanel extends StatelessWidget {
  final PracticeEditController controller;

  const PracticePropertyPanel({
    Key? key,
    required this.controller,
  }) : super(key: key);

  /// 创建集字内容属性面板
  factory PracticePropertyPanel.forCollection({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
    required Function(String) onUpdateChars,
  }) {
    return _CollectionPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
      onUpdateChars: onUpdateChars,
    );
  }

  /// 创建组合内容属性面板
  factory PracticePropertyPanel.forGroup({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return _GroupPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }

  /// 创建图片内容属性面板
  factory PracticePropertyPanel.forImage({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
    required VoidCallback onSelectImage,
  }) {
    return _ImagePropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
      onSelectImage: onSelectImage,
    );
  }

  factory PracticePropertyPanel.forLayer({
    required PracticeEditController controller,
    required Map<String, dynamic> layer,
    required Function(Map<String, dynamic>) onLayerPropertiesChanged,
  }) {
    return _LayerPropertyPanel(
      controller: controller,
      layer: layer,
      onLayerPropertiesChanged: onLayerPropertiesChanged,
    );
  }

  /// 创建多选内容属性面板
  factory PracticePropertyPanel.forMultiSelection({
    required PracticeEditController controller,
    required List<String> selectedIds,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return _MultiSelectionPropertyPanel(
      controller: controller,
      selectedIds: selectedIds,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }

  /// 创建页面属性面板
  factory PracticePropertyPanel.forPage({
    required PracticeEditController controller,
    required Map<String, dynamic>? page,
    required Function(Map<String, dynamic>) onPagePropertiesChanged,
  }) {
    return _PagePropertyPanel(
      controller: controller,
      page: page,
      onPagePropertiesChanged: onPagePropertiesChanged,
    );
  }

  /// 创建文本内容属性面板
  factory PracticePropertyPanel.forText({
    required PracticeEditController controller,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onElementPropertiesChanged,
  }) {
    return _TextPropertyPanel(
      controller: controller,
      element: element,
      onElementPropertiesChanged: onElementPropertiesChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('基础属性面板'));
  }

  /// 构建通用几何属性区域
  Widget buildGeometrySection({
    required String title,
    required double x,
    required double y,
    required double width,
    required double height,
    required double rotation,
    required Function(double) onXChanged,
    required Function(double) onYChanged,
    required Function(double) onWidthChanged,
    required Function(double) onHeightChanged,
    required Function(double) onRotationChanged,
  }) {
    return materialExpansionTile(
      title: Text(title),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // 位置控制
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'X',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                      ),
                      controller:
                          TextEditingController(text: x.toStringAsFixed(0)),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newValue = double.tryParse(value);
                        if (newValue != null) {
                          onXChanged(newValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Y',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                      ),
                      controller:
                          TextEditingController(text: y.toStringAsFixed(0)),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newValue = double.tryParse(value);
                        if (newValue != null) {
                          onYChanged(newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 尺寸控制
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '宽度',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                      ),
                      controller:
                          TextEditingController(text: width.toStringAsFixed(0)),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newValue = double.tryParse(value);
                        if (newValue != null && newValue > 0) {
                          onWidthChanged(newValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '高度',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                      ),
                      controller: TextEditingController(
                          text: height.toStringAsFixed(0)),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newValue = double.tryParse(value);
                        if (newValue != null && newValue > 0) {
                          onHeightChanged(newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 旋转控制
              TextField(
                decoration: const InputDecoration(
                  labelText: '旋转角度',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  suffixText: '°',
                ),
                controller:
                    TextEditingController(text: rotation.toStringAsFixed(0)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final newValue = double.tryParse(value);
                  if (newValue != null) {
                    onRotationChanged(newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建通用视觉属性区域
  Widget buildVisualSection({
    required String title,
    required double opacity,
    required Function(double) onOpacityChanged,
  }) {
    return materialExpansionTile(
      title: Text(title),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('透明度'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: opacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: '${(opacity * 100).toStringAsFixed(0)}%',
                      onChanged: onOpacityChanged,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text('${(opacity * 100).toStringAsFixed(0)}%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper method to create Material-wrapped ExpansionTile
  Widget materialExpansionTile({
    required Widget title,
    List<Widget> children = const <Widget>[],
    bool initiallyExpanded = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: title,
        initiallyExpanded: initiallyExpanded,
        children: children,
      ),
    );
  }
}

/// 集字内容属性面板
class _CollectionPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final Function(String) onUpdateChars;

  const _CollectionPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onUpdateChars,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 集字特有属性
    final content = element['content'] as String? ?? '';
    final direction = element['direction'] as String? ?? 'horizontal';
    final flowDirection =
        element['flowDirection'] as String? ?? 'top-to-bottom';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 36.0;
    final fontColor = element['fontColor'] as String? ?? '#000000';
    final backgroundColor = element['backgroundColor'] as String? ?? '#FFFFFF';
    final lineSpacing = (element['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (element['letterSpacing'] as num?)?.toDouble() ?? 5.0;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '集字内容属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 几何属性部分
        buildGeometrySection(
          title: '几何属性',
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          onXChanged: (value) => _updateProperty('x', value),
          onYChanged: (value) => _updateProperty('y', value),
          onWidthChanged: (value) => _updateProperty('width', value),
          onHeightChanged: (value) => _updateProperty('height', value),
          onRotationChanged: (value) => _updateProperty('rotation', value),
        ),

        // 视觉属性部分
        buildVisualSection(
          title: '视觉设置',
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 书写设置部分
        materialExpansionTile(
          title: const Text('书写设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 书写方向
                  const Text('书写方向'),
                  DropdownButton<String>(
                    value: direction,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'horizontal', child: Text('左往右')),
                      DropdownMenuItem(value: 'vertical', child: Text('右往左')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateProperty('direction', value);
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // 行间方向
                  const Text('行间方向'),
                  DropdownButton<String>(
                    value: flowDirection,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'top-to-bottom', child: Text('上往下')),
                      DropdownMenuItem(
                          value: 'bottom-to-top', child: Text('下往上')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateProperty('flowDirection', value);
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // 间距设置
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '行间距',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller: TextEditingController(
                              text: lineSpacing.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null) {
                              _updateProperty('lineSpacing', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '字间距',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller: TextEditingController(
                              text: letterSpacing.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null) {
                              _updateProperty('letterSpacing', newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 内容设置部分
        materialExpansionTile(
          title: const Text('内容设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 汉字内容
                  const Text('汉字内容'),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '输入要展示的汉字',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: content),
                    maxLines: 3,
                    onChanged: (value) {
                      onUpdateChars(value);
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 字体设置
                  const Text('字体设置'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '字号',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller:
                              TextEditingController(text: fontSize.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              _updateProperty('fontSize', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 这里可以添加颜色选择器
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 集字预览（简化版）
                  const Text('集字预览'),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: content.characters.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              content.characters.elementAt(index),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}

/// 组合内容属性面板
class _GroupPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const _GroupPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 组内元素数量
    final children = element['children'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '组合内容属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 几何属性部分
        buildGeometrySection(
          title: '几何属性',
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          onXChanged: (value) => _updateProperty('x', value),
          onYChanged: (value) => _updateProperty('y', value),
          onWidthChanged: (value) => _updateProperty('width', value),
          onHeightChanged: (value) => _updateProperty('height', value),
          onRotationChanged: (value) => _updateProperty('rotation', value),
        ),

        // 视觉属性部分
        buildVisualSection(
          title: '视觉设置',
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 组合信息部分
        materialExpansionTile(
          title: const Text('组合信息'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('包含 ${children.length} 个元素'),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      // 取消组合
                      // 这个功能通常在工具栏中实现
                    },
                    child: const Text('取消组合'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}

/// 图片内容属性面板
class _ImagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final VoidCallback onSelectImage;

  const _ImagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onSelectImage,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 图片特有属性
    final imageUrl = element['imageUrl'] as String? ?? '';

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '图片内容属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 几何属性部分
        buildGeometrySection(
          title: '几何属性',
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          onXChanged: (value) => _updateProperty('x', value),
          onYChanged: (value) => _updateProperty('y', value),
          onWidthChanged: (value) => _updateProperty('width', value),
          onHeightChanged: (value) => _updateProperty('height', value),
          onRotationChanged: (value) => _updateProperty('rotation', value),
        ),

        // 视觉属性部分
        buildVisualSection(
          title: '视觉设置',
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 图片选择部分
        materialExpansionTile(
          title: const Text('图片选择'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onSelectImage,
                          child: const Text('选择图片'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 从作品中选择
                          },
                          child: const Text('从作品选择'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      // 从集字中选择
                    },
                    child: const Text('从集字中选择'),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图片预览部分
        materialExpansionTile(
          title: const Text('图片预览'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Text('加载图片失败'));
                            },
                          )
                        : const Center(child: Text('没有选择图片')),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 图片变换部分
        materialExpansionTile(
          title: const Text('图片变换'),
          initiallyExpanded: false,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('旋转'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _updateProperty('rotation', (rotation - 90) % 360),
                        child: const Text('-90°'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _updateProperty('rotation', (rotation + 90) % 360),
                        child: const Text('+90°'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _updateProperty('rotation', (rotation + 180) % 360),
                        child: const Text('180°'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text('翻转'),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 水平翻转实现
                            // 这里需要更复杂的实现，可能涉及图片处理
                          },
                          child: const Text('水平翻转'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 垂直翻转实现
                            // 这里需要更复杂的实现，可能涉及图片处理
                          },
                          child: const Text('垂直翻转'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}

/// 图层属性面板
class _LayerPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> layer;
  final Function(Map<String, dynamic>) onLayerPropertiesChanged;

  const _LayerPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.layer,
    required this.onLayerPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final visible = layer['visible'] as bool? ?? true;
    final name = layer['name'] as String? ?? '未命名图层';
    final opacity = (layer['opacity'] as num?)?.toDouble() ?? 1.0;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '图层属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 图层信息部分
        materialExpansionTile(
          title: const Text('图层信息'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图层名称
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '图层名称',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: name),
                    onChanged: (value) {
                      _updateProperty('name', value);
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 图层可见性
                  Row(
                    children: [
                      const Text('可见性'),
                      const SizedBox(width: 16.0),
                      Switch(
                        value: visible,
                        onChanged: (value) {
                          _updateProperty('visible', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 视觉属性部分
        buildVisualSection(
          title: '视觉设置',
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onLayerPropertiesChanged(updates);
  }
}

/// 多选内容属性面板
class _MultiSelectionPropertyPanel extends PracticePropertyPanel {
  final List<String> selectedIds;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const _MultiSelectionPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.selectedIds,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '多选元素属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 视觉属性部分
        buildVisualSection(
          title: '视觉设置',
          opacity: 1.0, // 多选时默认值
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 多选信息部分
        materialExpansionTile(
          title: const Text('多选信息'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已选择 ${selectedIds.length} 个元素'),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      // 组合选中元素
                      // 这个功能通常在工具栏中实现
                    },
                    child: const Text('组合选中元素'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}

/// 页面属性面板
class _PagePropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic>? page;
  final Function(Map<String, dynamic>) onPagePropertiesChanged;

  const _PagePropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.page,
    required this.onPagePropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    if (page == null) {
      return const Center(child: Text('没有选中页面'));
    }

    final width = (page!['width'] as num?)?.toDouble() ?? 595.0; // A4默认宽度
    final height = (page!['height'] as num?)?.toDouble() ?? 842.0; // A4默认高度
    final backgroundColor = page!['backgroundColor'] as String? ?? '#FFFFFF';

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '页面属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 页面尺寸部分
        materialExpansionTile(
          title: const Text('页面尺寸'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 预设尺寸选择
                    const Text('预设尺寸'),
                    DropdownButton<String>(
                      value: _getPageSizePreset(width, height),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'A4', child: Text('A4 (210×297mm)')),
                        DropdownMenuItem(
                            value: 'A5', child: Text('A5 (148×210mm)')),
                        DropdownMenuItem(value: 'custom', child: Text('自定义')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          Map<String, double> newSize =
                              _getPageDimensions(value);
                          _updateProperty('width', newSize['width']!);
                          _updateProperty('height', newSize['height']!);
                        }
                      },
                    ),

                    const SizedBox(height: 16.0),

                    // 自定义尺寸
                    const Text('自定义尺寸'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '宽度',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              suffixText: 'px',
                            ),
                            controller: TextEditingController(
                                text: width.toStringAsFixed(0)),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final newValue = double.tryParse(value);
                              if (newValue != null && newValue > 0) {
                                _updateProperty('width', newValue);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '高度',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              suffixText: 'px',
                            ),
                            controller: TextEditingController(
                                text: height.toStringAsFixed(0)),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final newValue = double.tryParse(value);
                              if (newValue != null && newValue > 0) {
                                _updateProperty('height', newValue);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 背景设置部分
        materialExpansionTile(
          title: const Text('背景设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 背景颜色
                  const Text('背景颜色'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16.0),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _hexToColor(backgroundColor),
                            border: Border.all(color: Colors.grey),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(backgroundColor),
                        // 在这里可以添加颜色选择器
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, double> _getPageDimensions(String preset) {
    switch (preset) {
      case 'A4':
        return {'width': 595.0, 'height': 842.0};
      case 'A5':
        return {'width': 420.0, 'height': 595.0};
      default:
        return {'width': 595.0, 'height': 842.0};
    }
  }

  String _getPageSizePreset(double width, double height) {
    if ((width == 595 && height == 842) || (width == 842 && height == 595)) {
      return 'A4';
    } else if ((width == 420 && height == 595) ||
        (width == 595 && height == 420)) {
      return 'A5';
    }
    return 'custom';
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onPagePropertiesChanged(updates);
  }
}

/// 文本内容属性面板
class _TextPropertyPanel extends PracticePropertyPanel {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;

  const _TextPropertyPanel({
    Key? key,
    required PracticeEditController controller,
    required this.element,
    required this.onElementPropertiesChanged,
  }) : super(key: key, controller: controller);

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // 文本特有属性
    final text = element['text'] as String? ?? '';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontFamily = element['fontFamily'] as String? ?? 'sans-serif';
    final fontColor = element['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        element['backgroundColor'] as String? ?? 'transparent';
    final textAlign = element['textAlign'] as String? ?? 'left';

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '文本内容属性',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // 几何属性部分
        buildGeometrySection(
          title: '几何属性',
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          onXChanged: (value) => _updateProperty('x', value),
          onYChanged: (value) => _updateProperty('y', value),
          onWidthChanged: (value) => _updateProperty('width', value),
          onHeightChanged: (value) => _updateProperty('height', value),
          onRotationChanged: (value) => _updateProperty('rotation', value),
        ),

        // 视觉属性部分
        buildVisualSection(
          title: '视觉设置',
          opacity: opacity,
          onOpacityChanged: (value) => _updateProperty('opacity', value),
        ),

        // 文本设置部分
        materialExpansionTile(
          title: const Text('文本设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文本内容
                  const Text('文本内容'),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '输入文本内容',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: text),
                    maxLines: 5,
                    onChanged: (value) {
                      _updateProperty('text', value);
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 字体设置
                  const Text('字体设置'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '字号',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller:
                              TextEditingController(text: fontSize.toString()),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = double.tryParse(value);
                            if (newValue != null && newValue > 0) {
                              _updateProperty('fontSize', newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 这里可以添加更多字体设置控件
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  // 字体族设置
                  DropdownButton<String>(
                    value: fontFamily,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'sans-serif', child: Text('Sans Serif')),
                      DropdownMenuItem(value: 'serif', child: Text('Serif')),
                      DropdownMenuItem(
                          value: 'monospace', child: Text('Monospace')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateProperty('fontFamily', value);
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // 对齐方式
                  const Text('对齐方式'),
                  ToggleButtons(
                    isSelected: [
                      textAlign == 'left',
                      textAlign == 'center',
                      textAlign == 'right',
                    ],
                    onPressed: (index) {
                      String newAlign;
                      switch (index) {
                        case 0:
                          newAlign = 'left';
                          break;
                        case 1:
                          newAlign = 'center';
                          break;
                        case 2:
                          newAlign = 'right';
                          break;
                        default:
                          newAlign = 'left';
                      }
                      _updateProperty('textAlign', newAlign);
                    },
                    children: const [
                      Icon(Icons.align_horizontal_left),
                      Icon(Icons.align_horizontal_center),
                      Icon(Icons.align_horizontal_right),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    onElementPropertiesChanged(updates);
  }
}
