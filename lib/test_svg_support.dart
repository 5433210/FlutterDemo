import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'infrastructure/logging/logger.dart';

/// 用于测试SVG图像处理的简单页面
class SvgTestPage extends StatelessWidget {
  const SvgTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG 测试'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SVG 图像处理测试'),
            SizedBox(height: 20),
            // 测试SVG组件是否正常工作
            _TestSvgWidget(),
          ],
        ),
      ),
    );
  }
}

class _TestSvgWidget extends StatelessWidget {
  const _TestSvgWidget();

  @override
  Widget build(BuildContext context) {
    // 创建一个简单的SVG内容用于测试
    const svgContent = '''
      <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <circle cx="50" cy="50" r="40" stroke="blue" stroke-width="3" fill="lightblue" />
        <text x="50" y="55" text-anchor="middle" fill="black">SVG</text>
      </svg>
    ''';

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.string(
        svgContent,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// 测试图像验证工具
void testImageValidation() async {
  // 这个函数可以在需要时调用来测试图像验证
  AppLogger.debug('图像验证测试开始', tag: 'SVGTest');

  // 测试不存在的文件
  final result1 = await _testValidation('/nonexistent/file.svg');
  AppLogger.debug(
    '不存在文件测试结果',
    tag: 'SVGTest',
    data: {
      'isValid': result1.isValid,
      'message': result1.message,
      'testType': 'nonexistent_file',
    },
  );

  AppLogger.debug('SVG 支持已配置完成', tag: 'SVGTest');
}

Future<_ValidationResult> _testValidation(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) {
      return _ValidationResult(false, '文件不存在');
    }
    return _ValidationResult(true, '文件存在');
  } catch (e) {
    return _ValidationResult(false, '验证失败: $e');
  }
}

class _ValidationResult {
  final bool isValid;
  final String message;

  _ValidationResult(this.isValid, this.message);
}
