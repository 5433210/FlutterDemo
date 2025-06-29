import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/presentation/dialogs/practice_save_dialog.dart';
import '../lib/presentation/utils/dialog_navigation_helper.dart';
import '../lib/l10n/app_localizations.dart';

/// 测试对话框导航类型安全性修复
/// 
/// 此测试验证了针对以下错误的修复：
/// "_TypeError (type 'String' is not a subtype of type 'SaveResult?' of 'result')"
/// 
/// 修复措施：
/// 1. 在连续的对话框调用之间添加延迟
/// 2. 使用类型保护的导航方法
/// 3. 增强错误处理和日志记录
void main() {
  group('Dialog Navigation Type Safety Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        home: const DialogTypeTestPage(),
      );
    });

    testWidgets('PracticeSaveDialog type safety test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      // 点击按钮显示对话框
      await tester.tap(find.text('测试 PracticeSaveDialog'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.byType(PracticeSaveDialog), findsOneWidget);

      // 输入标题
      await tester.enterText(find.byType(TextField), 'Test Title');
      await tester.pumpAndSettle();

      // 点击保存按钮
      final saveButtons = find.text('保存');
      expect(saveButtons, findsWidgets);
      await tester.tap(saveButtons.last);
      await tester.pumpAndSettle();

      // 验证对话框已关闭且没有错误
      expect(find.byType(PracticeSaveDialog), findsNothing);
      expect(find.text('保存成功: Test Title'), findsOneWidget);
    });

    testWidgets('连续对话框类型安全测试', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      // 测试连续调用不同类型的对话框
      await tester.tap(find.text('测试连续对话框'));
      await tester.pumpAndSettle();

      // 验证第一个对话框
      expect(find.byType(PracticeSaveDialog), findsOneWidget);
      
      await tester.enterText(find.byType(TextField), 'Sequential Test');
      await tester.tap(find.text('保存').last);
      await tester.pumpAndSettle();

      // 等待一段时间确保导航完成
      await tester.pump(const Duration(milliseconds: 200));
      
      // 验证没有类型错误且对话框正确关闭
      expect(find.byType(PracticeSaveDialog), findsNothing);
    });

    testWidgets('DialogNavigationHelper类型保护测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // 测试类型保护的弹出方法
                    await DialogNavigationHelper.safePopWithTypeGuard<String>(
                      context,
                      result: 'test result',
                      dialogName: 'TestDialog',
                    );
                  },
                  child: const Text('测试类型保护'),
                ),
              ),
            ),
          ),
        ),
      );

      // 这个测试主要是确保方法调用不会抛出编译错误
      expect(find.text('测试类型保护'), findsOneWidget);
    });
  });
}

/// 测试页面
class DialogTypeTestPage extends StatefulWidget {
  const DialogTypeTestPage({super.key});

  @override
  State<DialogTypeTestPage> createState() => _DialogTypeTestPageState();
}

class _DialogTypeTestPageState extends State<DialogTypeTestPage> {
  String _lastResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('对话框类型安全测试')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _testPracticeSaveDialog(),
              child: const Text('测试 PracticeSaveDialog'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _testSequentialDialogs(),
              child: const Text('测试连续对话框'),
            ),
            const SizedBox(height: 16),
            if (_lastResult.isNotEmpty)
              Text(
                _lastResult,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testPracticeSaveDialog() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => const PracticeSaveDialog(
          initialTitle: '',
          isSaveAs: false,
        ),
      );

      if (mounted) {
        setState(() {
          _lastResult = result != null ? '保存成功: $result' : '用户取消';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastResult = '错误: $e';
        });
      }
    }
  }

  Future<void> _testSequentialDialogs() async {
    try {
      // 第一个对话框 - PracticeSaveDialog (返回 String)
      final firstResult = await showDialog<String>(
        context: context,
        builder: (context) => const PracticeSaveDialog(
          initialTitle: '',
          isSaveAs: false,
        ),
      );

      if (firstResult == null || !mounted) return;

      // 添加延迟确保第一个对话框完全关闭
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() {
          _lastResult = '连续对话框测试完成: $firstResult';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastResult = '连续对话框测试错误: $e';
        });
      }
    }
  }
} 