import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models/character_region.dart';

class CharacterPreviewPanel extends StatefulWidget {
  final CharacterRegion? selectedRegion;
  final String? imagePath;
  final Function(CharacterRegion)? onSave;
  final VoidCallback? onCancel;
  final ValueChanged<bool>? onInvertColors;

  const CharacterPreviewPanel({
    super.key,
    this.selectedRegion,
    this.imagePath,
    this.onSave,
    this.onCancel,
    this.onInvertColors,
  });

  @override
  State<CharacterPreviewPanel> createState() => _CharacterPreviewPanelState();
}

class _CharacterPreviewPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> erasePoints;
  final bool isInverted;

  _CharacterPreviewPainter({
    required this.image,
    required this.erasePoints,
    this.isInverted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    if (isInverted) {
      paint.colorFilter = const ColorFilter.matrix([
        -1, 0, 0, 0, 255, // Red
        0, -1, 0, 0, 255, // Green
        0, 0, -1, 0, 255, // Blue
        0, 0, 0, 1, 0, // Alpha
      ]);
    }

    // 绘制图片
    canvas.drawImage(image, Offset.zero, paint);

    // 绘制擦除点
    if (erasePoints.isNotEmpty) {
      paint.color = Colors.white;
      paint.strokeWidth = 10;
      paint.strokeCap = StrokeCap.round;

      for (int i = 0; i < erasePoints.length - 1; i++) {
        canvas.drawLine(erasePoints[i], erasePoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CharacterPreviewPainter oldDelegate) {
    return image != oldDelegate.image ||
        erasePoints != oldDelegate.erasePoints ||
        isInverted != oldDelegate.isInverted;
  }
}

class _CharacterPreviewPanelState extends State<CharacterPreviewPanel> {
  bool _isErasing = false;
  bool _isInverted = false;
  final TextEditingController _characterController = TextEditingController();
  ui.Image? _previewImage;
  final List<Offset> _erasePoints = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 工具栏
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.brush,
                  color: _isErasing ? Theme.of(context).primaryColor : null,
                ),
                onPressed: () {
                  setState(() {
                    _isErasing = !_isErasing;
                  });
                },
                tooltip: '擦除工具',
              ),
              IconButton(
                icon: const Icon(Icons.invert_colors),
                onPressed: () {
                  setState(() {
                    _isInverted = !_isInverted;
                    if (widget.onInvertColors != null) {
                      widget.onInvertColors!(_isInverted);
                    }
                  });
                },
                tooltip: '反转颜色',
              ),
            ],
          ),

          // 预览区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _previewImage == null
                  ? const Center(child: Text('无预览内容'))
                  : GestureDetector(
                      onPanUpdate: _isErasing ? _handleErase : null,
                      child: CustomPaint(
                        painter: _CharacterPreviewPainter(
                          image: _previewImage!,
                          erasePoints: _erasePoints,
                          isInverted: _isInverted,
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // 字符输入
          TextField(
            controller: _characterController,
            decoration: const InputDecoration(
              labelText: '输入汉字',
              hintText: '请输入对应的简体汉字',
            ),
            maxLength: 1,
          ),

          const SizedBox(height: 16),

          // 按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _characterController.text.isEmpty
                    ? null
                    : () {
                        if (widget.selectedRegion != null &&
                            widget.onSave != null) {
                          // TODO: 处理图片并保存
                          widget.onSave!(widget.selectedRegion!);
                        }
                      },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(CharacterPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePath != oldWidget.imagePath ||
        widget.selectedRegion != oldWidget.selectedRegion) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _characterController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _handleErase(DragUpdateDetails details) {
    setState(() {
      _erasePoints.add(details.localPosition);
    });
  }

  Future<void> _loadImage() async {
    if (widget.imagePath == null || widget.selectedRegion == null) {
      setState(() {
        _previewImage = null;
      });
      return;
    }

    // 加载图片
    final file = File(widget.imagePath!);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _previewImage = frame.image;
    });
  }
}
