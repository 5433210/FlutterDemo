import 'package:flutter/material.dart';

class ZoomControlBar extends StatelessWidget {
  final double zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const ZoomControlBar({
    Key? key,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 缩小按钮
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: '缩小',
            onPressed: zoomLevel > 0.5 ? onZoomOut : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            iconSize: 20,
          ),

          // 重置按钮
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('${(zoomLevel * 100).toInt()}%'),
          ),

          // 放大按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '放大',
            onPressed: zoomLevel < 3.0 ? onZoomIn : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
