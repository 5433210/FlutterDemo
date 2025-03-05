import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../domain/models/practice/element_content.dart';
import '../../../../domain/models/practice/practice_element.dart';
import '../../../../domain/models/practice/practice_layer.dart';
import '../../../../domain/models/practice/practice_page.dart';
import '../../../../theme/app_colors.dart';
import '../../../widgets/common/empty_state.dart';

/// 字帖页面预览组件
class PracticePageViewer extends StatefulWidget {
  /// 字帖页面
  final PracticePage page;

  /// 是否只读模式
  final bool readOnly;

  /// 元素点击回调
  final void Function(PracticeElement element)? onElementTap;

  /// 图层切换回调
  final void Function(PracticeLayer layer)? onLayerToggle;

  const PracticePageViewer({
    super.key,
    required this.page,
    this.readOnly = true,
    this.onElementTap,
    this.onLayerToggle,
  });

  @override
  State<PracticePageViewer> createState() => _PracticePageViewerState();
}

class _PracticePageViewerState extends State<PracticePageViewer> {
  /// 缩放比例
  double _scale = 1.0;

  /// 是否显示图层控制面板
  bool _showLayers = false;

  /// 当前选中的元素ID
  String? _selectedElementId;

  @override
  Widget build(BuildContext context) {
    // 如果页面没有图层，显示空状态
    if (widget.page.layers.isEmpty) {
      return const EmptyState();
    }

    return Scaffold(
      // 使用Scaffold只为了获取背景色和FloatingActionButton支持
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.readOnly ? null : _buildFab(),
      body: Column(
        children: [
          // 顶部控制区
          _buildControls(),

          // 页面内容区 (占据大部分空间)
          Expanded(
            child: _buildPageContent(),
          ),
        ],
      ),
    );
  }

  /// 构建字符元素
  Widget _buildCharsElement(PracticeElement element) {
    final charsContent = element.content as CharsContent;

    // 如果没有字符，显示占位符
    if (charsContent.chars.isEmpty) {
      return const Center(
        child: Text('无字符内容'),
      );
    }

    // 绘制所有字符 (复杂逻辑简化示例)
    return Stack(
      children: charsContent.chars.map((charElement) {
        // 这里简化了字符定位和变换，实际实现需更复杂
        return Center(
          child: Text(
            '字符: ${charElement.charId}',
            style: TextStyle(
              color: Color(int.parse(
                    charElement.style.color?.substring(1) ?? 'FF000000',
                    radix: 16,
                  ) |
                  0xFF000000),
              fontSize: 16.0 * charElement.transform.scaleX,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建顶部控制区
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 缩放控制
          Text(
            '缩放: ${(_scale * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _scale = min(_scale + 0.1, 2.0);
              });
            },
            tooltip: '放大',
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _scale = max(_scale - 0.1, 0.5);
              });
            },
            tooltip: '缩小',
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),

          const Spacer(),

          // 页面信息
          Text(
            '${widget.page.size.width.toStringAsFixed(0)}×${widget.page.size.height.toStringAsFixed(0)} ${widget.page.size.unit}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// 根据元素类型构建对应的Widget
  Widget? _buildElementWidget(PracticeElement element) {
    final geometry = element.geometry;
    final isSelected = element.id == _selectedElementId;

    // 计算元素实际位置和大小(应用缩放)
    final left = geometry.x * _scale;
    final top = geometry.y * _scale;
    final width = geometry.width * _scale;
    final height = geometry.height * _scale;

    // 基础容器
    Widget? contentWidget;

    // 根据元素类型创建内容
    switch (element.type) {
      case 'chars':
        // 处理字符类型元素
        if (element.content is CharsContent) {
          contentWidget = _buildCharsElement(element);
        }
        break;
      case 'text':
        // 处理文本类型元素
        if (element.content is TextContent) {
          contentWidget = _buildTextElement(element);
        }
        break;
      case 'image':
        // 处理图像类型元素
        if (element.content is ImageContent) {
          contentWidget = _buildImageElement(element);
        }
        break;
      default:
        // 未知元素类型
        contentWidget = const Center(
          child: Text('未知元素类型'),
        );
    }

    if (contentWidget == null) return null;

    // 创建可交互元素
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: geometry.rotation * (pi / 180), // 转换为弧度
        child: Opacity(
          opacity: element.style.opacity,
          child: GestureDetector(
            onTap: widget.readOnly
                ? null
                : () {
                    setState(() {
                      _selectedElementId = element.id;
                    });
                    widget.onElementTap?.call(element);
                  },
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2.0,
                      ),
                    )
                  : null,
              child: contentWidget,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部浮动按钮
  Widget? _buildFab() {
    if (widget.readOnly) return null;

    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showLayers = !_showLayers;
        });
      },
      tooltip: _showLayers ? '隐藏图层面板' : '显示图层面板',
      child: Icon(_showLayers ? Icons.layers_clear : Icons.layers),
    );
  }

  /// 构建图像元素
  Widget _buildImageElement(PracticeElement element) {
    final imagePath = (element.content as ImageContent).image.path;

    try {
      // 尝试加载图像
      final file = File(imagePath);
      if (!file.existsSync()) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 32, color: Colors.grey),
              SizedBox(height: 4),
              Text('图片不存在', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 32, color: Colors.red),
                SizedBox(height: 4),
                Text('图片损坏', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 32, color: Colors.red),
            const SizedBox(height: 4),
            Text(
                '加载错误: ${e.toString().substring(0, min(20, e.toString().length))}...'),
          ],
        ),
      );
    }
  }

  /// 构建所有图层的所有元素
  List<Widget> _buildLayeredElements() {
    final List<Widget> elements = [];

    // 按照图层顺序构建元素（索引较小的图层在下方）
    final visibleLayers = widget.page.layers
        .where((layer) => layer.visible)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    for (final layer in visibleLayers) {
      for (final element in layer.elements) {
        // 如果元素不可见，则跳过
        if (!element.style.visible) continue;

        // 根据元素类型构建不同的视图
        final elementWidget = _buildElementWidget(element);
        if (elementWidget != null) {
          elements.add(elementWidget);
        }
      }
    }

    return elements;
  }

  /// 构建单个图层项
  Widget _buildLayerItem(PracticeLayer layer) {
    return ListTile(
      title: Text(
        layer.name,
        style: TextStyle(
          fontWeight: layer.locked ? FontWeight.normal : FontWeight.bold,
          color: !layer.visible
              ? Theme.of(context).disabledColor
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text('${layer.elements.length} 个元素'),
      leading: Icon(
        layer.type == 'background' ? Icons.landscape : Icons.layers,
        color: layer.visible
            ? (layer.type == 'background'
                ? Colors.green
                : Theme.of(context).colorScheme.primary)
            : Theme.of(context).disabledColor,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 可见性切换
          IconButton(
            icon: Icon(
              layer.visible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: widget.readOnly
                ? null
                : () {
                    final updatedLayer = layer.toggleVisibility();
                    widget.onLayerToggle?.call(updatedLayer);
                    // 如果没有外部处理，在本地更新状态
                    if (widget.onLayerToggle == null) {
                      setState(() {});
                    }
                  },
            tooltip: layer.visible ? '隐藏图层' : '显示图层',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),

          // 锁定切换
          IconButton(
            icon: Icon(
              layer.locked ? Icons.lock_outline : Icons.lock_open,
            ),
            onPressed: widget.readOnly
                ? null
                : () {
                    final updatedLayer = layer.toggleLock();
                    widget.onLayerToggle?.call(updatedLayer);
                    // 如果没有外部处理，在本地更新状态
                    if (widget.onLayerToggle == null) {
                      setState(() {});
                    }
                  },
            tooltip: layer.locked ? '解锁图层' : '锁定图层',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
      ),
      onTap: widget.readOnly
          ? null
          : () {
              // 点击图层项的行为，例如选择该图层
            },
    );
  }

  /// 构建图层控制面板
  Widget _buildLayersPanel() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 面板标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '图层',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showLayers = false;
                    });
                  },
                  tooltip: '关闭图层面板',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 图层列表
          Expanded(
            child: ListView.builder(
              itemCount: widget.page.layers.length,
              itemBuilder: (context, index) {
                final layer = widget.page.layers[index];
                return _buildLayerItem(layer);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建页面画布
  Widget _buildPageCanvas() {
    final pageSize = widget.page.size;

    // 计算实际显示尺寸 (应用缩放比例)
    final displayWidth = pageSize.width * _scale;
    final displayHeight = pageSize.height * _scale;

    return Container(
      margin: const EdgeInsets.all(20),
      width: displayWidth,
      height: displayHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          children: _buildLayeredElements(),
        ),
      ),
    );
  }

  /// 构建页面内容区
  Widget _buildPageContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 主内容区域
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildPageCanvas(),
              ),
            ),
          ),
        ),

        // 显示图层面板 (如果启用)
        if (_showLayers && !widget.readOnly) _buildLayersPanel(),
      ],
    );
  }

  /// 构建文本元素
  Widget _buildTextElement(PracticeElement element) {
    final textContent = (element.content as TextContent).text;

    // 设置对齐方式
    TextAlign textAlign = TextAlign.left;
    switch (textContent.alignment) {
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'justify':
        textAlign = TextAlign.justify;
        break;
      default:
        textAlign = TextAlign.left;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      child: Text(
        textContent.content,
        style: TextStyle(
          fontFamily: textContent.fontFamily,
          fontSize: textContent.fontSize * _scale,
          color: Color(int.parse(
                textContent.color.substring(1),
                radix: 16,
              ) |
              0xFF000000),
        ),
        textAlign: textAlign,
      ),
    );
  }
}
