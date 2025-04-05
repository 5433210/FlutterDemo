/// EraseToolWidget 使用示例文档
///
/// 本文件展示了如何在应用中集成和使用EraseToolWidget

// 1. 导入必要的包
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tools/erase/erase_tool_widget.dart';

// 2. 创建示例页面
class EraseToolExamplePage extends StatefulWidget {
  const EraseToolExamplePage({Key? key}) : super(key: key);

  @override
  State<EraseToolExamplePage> createState() => _EraseToolExamplePageState();
}

class _EraseToolExamplePageState extends State<EraseToolExamplePage> {
  ui.Image? _image;
  Map<String, dynamic>? _eraseResult;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('擦除工具示例'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _image == null
                ? const Text('图像加载失败')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 显示图像
                      Expanded(
                        child: Center(
                          child: _eraseResult != null
                              ? const Text('显示处理后的图像')
                              : const Text('显示原始图像'),
                          // 实际应用中，这里应该显示真实图像
                        ),
                      ),

                      // 操作按钮
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: _openEraseTool,
                          child: const Text('开始擦除'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  // 5. 处理擦除完成
  void _handleEraseComplete(Map<String, dynamic> result) {
    setState(() {
      _eraseResult = result;
    });

    // 在实际应用中，您可能想要:
    // - 保存结果图像
    // - 更新UI显示结果
    // - 继续下一步处理
  }

  // 3. 加载图像
  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 实际应用中，这里应该加载真实图像
      // 例如：从文件、网络或资源加载

      // 模拟图像加载
      await Future.delayed(const Duration(seconds: 1));

      // 假设我们已成功加载图像
      // _image = 已加载的图像;

      setState(() {
        _isLoading = false;
        // 实际应用中，应设置_image为真实加载的图像
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // 显示错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载图像失败: $e')),
        );
      }
    }
  }

  // 4. 打开擦除工具
  Future<void> _openEraseTool() async {
    if (_image == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EraseToolWidget(
          image: _image!,
          workId: 'example', // 示例代码使用临时ID，实际使用时需要传入真实的workId
          pageId: 'example_page', // 示例代码使用临时pageId，实际使用时需要传入当前图片页面的ID
          onComplete: _handleEraseComplete,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _eraseResult = result;
      });
    }
  }
}

/// 使用说明：
/// 
/// 1. 确保已正确设置Flutter环境
/// 2. 将EraseToolWidget及其依赖添加到您的项目中
/// 3. 加载要处理的图像（ui.Image对象）
/// 4. 将图像传递给EraseToolWidget
/// 5. 处理擦除完成后的结果
/// 
/// 示例代码展示了基本使用流程，实际应用中需要替换图像加载和结果处理逻辑。
