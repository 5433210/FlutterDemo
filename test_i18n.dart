import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'lib/l10n/app_localizations.dart';

void main() {
  print('=== 多语言支持测试 ===');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'I18n Test',
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'),
        Locale('zh'),
      ],
      home: TestPage(),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('多语言测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('元素管理相关本地化测试：'),
            const SizedBox(height: 8),
            Text('- 集字元素: ${l10n.collectionElement}'),
            Text('- 图片元素: ${l10n.imageElement}'),
            Text('- 文本元素: ${l10n.textElement}'),
            Text('- 默认编辑文本: ${l10n.defaultEditableText}'),
            Text('- 默认图层: ${l10n.defaultLayer}'),
            const SizedBox(height: 16),
            const Text('Canvas相关本地化测试：'),
            const SizedBox(height: 8),
            Text('- 当前工具: ${l10n.currentTool}'),
            Text('- 选择模式: ${l10n.selectionMode}'),
            Text('- 重置视图: ${l10n.canvasResetViewTooltip}'),
          ],
        ),
      ),
    );
  }
}
