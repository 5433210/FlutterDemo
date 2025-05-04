import 'package:flutter/material.dart';

/// 专门测试字体粗细变化的工具
class FontWeightTester extends StatelessWidget {
  const FontWeightTester({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字体粗细测试工具'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '字体粗细测试工具',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '这个工具专门用于测试思源黑体和思源宋体的字重变化。我们测试了不同的字重注册方式和渲染方式，以找出为什么只有两种粗细变化生效。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // 测试1: 直接使用FontWeight枚举
            _buildTestSection(
              '测试1: 使用FontWeight枚举',
              '测试直接使用Flutter的FontWeight枚举值来设置字重',
              [
                _buildWeightTest('SourceHanSans', FontWeight.w100, '思源黑体 w100'),
                _buildWeightTest('SourceHanSans', FontWeight.w300, '思源黑体 w300'),
                _buildWeightTest('SourceHanSans', FontWeight.w400, '思源黑体 w400'),
                _buildWeightTest('SourceHanSans', FontWeight.w700, '思源黑体 w700'),
                _buildWeightTest('SourceHanSans', FontWeight.w900, '思源黑体 w900'),
              ],
            ),

            const SizedBox(height: 24),

            // 测试2: 使用fontVariations
            _buildTestSection(
              '测试2: 使用fontVariations',
              '测试使用fontVariations属性直接设置字重轴的值',
              [
                _buildVariationTest('SourceHanSans', 100, '思源黑体 wght=100'),
                _buildVariationTest('SourceHanSans', 300, '思源黑体 wght=300'),
                _buildVariationTest('SourceHanSans', 400, '思源黑体 wght=400'),
                _buildVariationTest('SourceHanSans', 700, '思源黑体 wght=700'),
                _buildVariationTest('SourceHanSans', 900, '思源黑体 wght=900'),
              ],
            ),

            const SizedBox(height: 24),

            // 测试3: 思源宋体测试
            _buildTestSection(
              '测试3: 思源宋体测试',
              '测试思源宋体的字重变化',
              [
                _buildWeightTest(
                    'SourceHanSerif', FontWeight.w100, '思源宋体 w100'),
                _buildWeightTest(
                    'SourceHanSerif', FontWeight.w300, '思源宋体 w300'),
                _buildWeightTest(
                    'SourceHanSerif', FontWeight.w400, '思源宋体 w400'),
                _buildWeightTest(
                    'SourceHanSerif', FontWeight.w700, '思源宋体 w700'),
                _buildWeightTest(
                    'SourceHanSerif', FontWeight.w900, '思源宋体 w900'),
              ],
            ),

            const SizedBox(height: 24),

            // 测试4: 使用单独注册的字体家族
            _buildTestSection(
              '测试4: 使用单独注册的字体家族',
              '测试使用不同字体家族名称注册的同一字体文件',
              [
                _buildWeightTest('SourceHanSansLight', FontWeight.normal,
                    'SourceHanSansLight (w300)'),
                _buildWeightTest('SourceHanSansRegular', FontWeight.normal,
                    'SourceHanSansRegular (w400)'),
                _buildWeightTest('SourceHanSansBold', FontWeight.normal,
                    'SourceHanSansBold (w700)'),
              ],
            ),

            const SizedBox(height: 24),

            // 测试5: 系统字体对比
            _buildTestSection(
              '测试5: 系统字体对比',
              '测试系统字体的字重变化作为对比',
              [
                _buildWeightTest('Roboto', FontWeight.w100, 'Roboto w100'),
                _buildWeightTest('Roboto', FontWeight.w300, 'Roboto w300'),
                _buildWeightTest('Roboto', FontWeight.w400, 'Roboto w400'),
                _buildWeightTest('Roboto', FontWeight.w700, 'Roboto w700'),
                _buildWeightTest('Roboto', FontWeight.w900, 'Roboto w900'),
              ],
            ),

            const SizedBox(height: 24),

            // 测试5: 字体文件信息
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '字体文件信息',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('思源黑体 (SourceHanSans):'),
              Text('- 文件: assets/fonts/chinese/SourceHanSansCN-VF.otf'),
              Text('- 类型: 可变字体 (Variable Font)'),
              Text('- 字重轴: wght (100-900)'),
              SizedBox(height: 8),
              Text('思源宋体 (SourceHanSerif):'),
              Text('- 文件: assets/fonts/chinese/SourceHanSerifCN-VF.otf'),
              Text('- 类型: 可变字体 (Variable Font)'),
              Text('- 字重轴: wght (100-900)'),
              SizedBox(height: 16),
              Text(
                '注意: Flutter对可变字体的支持可能有限制。如果字重变化不明显，可能是因为:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. Flutter引擎对可变字体的支持不完整'),
              Text('2. 字体文件的字重轴未被正确识别'),
              Text('3. 字体注册方式不正确'),
              Text('4. 平台特定的字体渲染限制'),
              SizedBox(height: 16),
              Text(
                '可能的解决方案:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. 使用不同的字体家族名称注册同一字体文件的不同字重'),
              Text('2. 使用非可变字体的多个字重文件'),
              Text('3. 使用fontVariations属性直接设置字重轴的值'),
              Text('4. 在应用中提供字体粗细预览，帮助用户选择合适的字重'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection(
      String title, String description, List<Widget> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...tests,
      ],
    );
  }

  Widget _buildVariationTest(
      String fontFamily, double weightValue, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '永曰月明清风 ABC 123',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 20,
                  fontVariations: [FontVariation('wght', weightValue)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTest(String fontFamily, FontWeight weight, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '永曰月明清风 ABC 123',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 20,
                  fontWeight: weight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
