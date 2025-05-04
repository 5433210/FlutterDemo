import 'package:flutter/material.dart';

/// 字体测试工具，用于显示不同字体的效果
class FontTester extends StatelessWidget {
  const FontTester({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字体测试工具'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '字体测试工具',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '这个工具用于测试不同字体的显示效果。每种字体都会显示相同的文本，包括英文、数字和中文。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildFontSection(
              '字体对比（使用相同的文本）',
              [
                {
                  'name': '系统默认',
                  'fontFamily': '.SF Pro Text'
                }, // macOS/iOS 的系统字体
                {'name': '思源黑体 Source Han Sans', 'fontFamily': 'SourceHanSans'},
                {
                  'name': '思源宋体 Source Han Serif',
                  'fontFamily': 'SourceHanSerif'
                },
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSample(String fontName, String fontFamily) {
    const sampleText = '永曰月明清风渡江 MagicWeb 2024';
    const fontSize = 32.0; // 增大字号以突出字体特征

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey.shade100,
            child: Text(
              fontName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 常规文本示例
                _buildTextSample('标准字重示例', sampleText, fontFamily, fontSize,
                    FontWeight.w400),
                const SizedBox(height: 16),

                // 字重变化示例
                Row(
                  children: [
                    Expanded(
                      child: _buildTextSample('细体 Light', '永曰月\n明清风',
                          fontFamily, fontSize * 0.8, FontWeight.w300),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextSample('粗体 Bold', '永曰月\n明清风', fontFamily,
                          fontSize * 0.8, FontWeight.w700),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 数字和字母示例
                _buildTextSample('数字和字母', 'MagicWeb 2024', fontFamily,
                    fontSize * 0.7, FontWeight.w400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSection(String title, List<Map<String, String>> fonts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...fonts.map(
            (font) => _buildFontSample(font['name']!, font['fontFamily']!)),
      ],
    );
  }

  /// 构建文本样例
  Widget _buildTextSample(String label, String text, String fontFamily,
      double fontSize, FontWeight weight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: weight,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
