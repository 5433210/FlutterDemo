import 'package:flutter/material.dart';

import 'test_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const PrototypeApp());
}

/// 原型验证应用
class PrototypeApp extends StatelessWidget {
  const PrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '字符编辑面板原型验证',
      debugShowCheckedModeBanner: false, // 移除调试标记
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PrototypeTestPage(),
    );
  }
}

/* 运行说明

1. 创建资源目录和测试图像：
   mkdir -p assets/test_images
   # 将测试用的字体图片复制到 assets/test_images/test_char.png

2. 在 pubspec.yaml 中添加资源配置：
   flutter:
     assets:
       - assets/test_images/

3. 运行原型验证程序：
   flutter run -t lib/presentation/widgets/character_collection/erase_tool/utils/prototype/main.dart

4. 验证项目：
   - 坐标转换精确性测试
   - 性能监控观察
   - 内存使用分析
   - 交互体验验证
*/
