import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'test_widget.dart';

/// 原型验证测试页面
class PrototypeTestPage extends StatefulWidget {
  const PrototypeTestPage({Key? key}) : super(key: key);

  @override
  State<PrototypeTestPage> createState() => _PrototypeTestPageState();
}

class _PrototypeTestPageState extends State<PrototypeTestPage> {
  ui.Image? _testImage;
  String? _error;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('原型验证测试'),
        actions: [
          // 重新加载按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTestImage,
            tooltip: '重新加载测试图像',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  @override
  void dispose() {
    _testImage?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTestImage();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载测试图像...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTestImage,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_testImage == null) {
      return const Center(
        child: Text('未加载测试图像'),
      );
    }

    // 显示测试组件
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 操作说明
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '操作说明：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('• 点击测试坐标转换'),
                      Text('• 滚轮或双指缩放'),
                      Text('• Alt + 拖动平移'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 测试区域
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: PrototypeTestWidget(
                        image: _testImage!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 加载测试图像
  Future<void> _loadTestImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 加载测试图像
      const assetPath = 'assets/test_images/test_char.png';
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();

      setState(() {
        _testImage = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载测试图像失败: $e';
        _isLoading = false;
      });
    }
  }
}
