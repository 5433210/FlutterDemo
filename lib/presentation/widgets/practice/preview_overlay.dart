import 'package:flutter/material.dart';

import 'preview_manager.dart';
import 'preview_painter.dart';

/// 预览覆盖层
class PreviewOverlay extends StatelessWidget {
  /// 预览管理器
  final PreviewManager previewManager;
  
  /// 页面大小
  final Size pageSize;
  
  /// 子组件
  final Widget child;
  
  /// 构造函数
  const PreviewOverlay({
    Key? key,
    required this.previewManager,
    required this.pageSize,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 预览背景
        if (previewManager.isPreviewMode)
          Positioned.fill(
            child: CustomPaint(
              painter: PreviewPainter(
                previewManager: previewManager,
                pageSize: pageSize,
              ),
            ),
          ),
        
        // 子组件
        Positioned.fill(
          child: AnimatedScale(
            scale: previewManager.isPreviewMode ? previewManager.previewScale : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: child,
          ),
        ),
        
        // 预览模式控制按钮
        if (previewManager.isPreviewMode)
          Positioned(
            top: 16,
            right: 16,
            child: _buildPreviewControls(),
          ),
      ],
    );
  }
  
  /// 构建预览模式控制按钮
  Widget _buildPreviewControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 退出预览模式按钮
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '退出预览模式',
              onPressed: () => previewManager.togglePreviewMode(),
            ),
            
            const Divider(),
            
            // 缩放控制
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  tooltip: '缩小',
                  onPressed: () => previewManager.setPreviewScale(
                    previewManager.previewScale / 1.2,
                  ),
                ),
                Text(
                  '${(previewManager.previewScale * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  tooltip: '放大',
                  onPressed: () => previewManager.setPreviewScale(
                    previewManager.previewScale * 1.2,
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // 显示页面边界
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('显示页面边界'),
                const SizedBox(width: 8),
                Switch(
                  value: previewManager.showPageBoundary,
                  onChanged: (_) => previewManager.togglePageBoundary(),
                ),
              ],
            ),
            
            // 显示打印标记
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('显示打印标记'),
                const SizedBox(width: 8),
                Switch(
                  value: previewManager.showPrintMarks,
                  onChanged: (_) => previewManager.togglePrintMarks(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
