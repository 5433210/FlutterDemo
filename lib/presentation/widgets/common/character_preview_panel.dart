import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';

class CharacterPreviewPanel extends StatelessWidget {
  final CharacterRegion? region;
  final String? label;
  final VoidCallback? onClear;
  final VoidCallback? onSave;

  const CharacterPreviewPanel({
    super.key,
    this.region,
    this.label,
    this.onClear,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (region == null) {
      return const Center(child: Text('请选择或框选字符区域'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildPreview(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('保存'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              tooltip: '清除',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (region == null) return const SizedBox();

    return FutureBuilder<ui.Image>(
      future: _loadImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('加载预览...'),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.red),
                SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: CustomPaint(
            painter: _CharacterPreviewPainter(
              image: snapshot.data!,
              region: region!,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Future<ui.Image> _loadImage() async {
    final file = File(region!.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class _CharacterPreviewPainter extends CustomPainter {
  final ui.Image image;
  final CharacterRegion region;

  _CharacterPreviewPainter({
    required this.image,
    required this.region,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Fill background
    canvas.drawRect(Offset.zero & size, paint);

    // Calculate scale to fit
    final scale = math.min(
      size.width / region.rect.width,
      size.height / region.rect.height,
    );

    // Center the image
    final centeredRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: region.rect.width * scale,
      height: region.rect.height * scale,
    );

    // Apply transformations
    canvas.save();
    canvas.translate(centeredRect.center.dx, centeredRect.center.dy);
    canvas.rotate(region.rotation);
    canvas.translate(-centeredRect.center.dx, -centeredRect.center.dy);

    // Draw the image section
    paint.filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      image,
      region.rect,
      centeredRect,
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CharacterPreviewPainter oldDelegate) {
    return image != oldDelegate.image || region != oldDelegate.region;
  }
}
