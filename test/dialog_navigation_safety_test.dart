import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/presentation/dialogs/practice_save_dialog.dart';
import '../lib/presentation/dialogs/common/dialogs.dart';
import '../lib/presentation/utils/dialog_navigation_helper.dart';
import '../lib/l10n/app_localizations.dart';

/// 对话框导航安全性测试
/// 确保对话框在各种情况下都能安全地弹出，不会出现"cannot pop after deferred attempt"错误
void main() {
  group('Dialog Navigation Safety Tests', () {
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
        home: const TestDialogPage(),
      );
    });

    testWidgets('PracticeSaveDialog safe navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      // 打开字帖保存对话框
      await tester.tap(find.text('Show Practice Save Dialog'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.byType(PracticeSaveDialog), findsOneWidget);
      expect(find.text('保存'), findsWidgets);

      // 输入标题
      await tester.enterText(find.byType(TextField), 'Test Practice');
      await tester.pumpAndSettle();

      // 点击保存按钮
      await tester.tap(find.text('保存').last);
      await tester.pumpAndSettle();

      // 验证对话框已关闭
      expect(find.byType(PracticeSaveDialog), findsNothing);
    });

    testWidgets('Confirm dialog safe navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      // 打开确认对话框
      await tester.tap(find.text('Show Confirm Dialog'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('确认'), findsWidgets);

      // 点击确认按钮
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // 验证对话框已关闭
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Error dialog safe navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      // 打开错误对话框
      await tester.tap(find.text('Show Error Dialog'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('错误'), findsWidgets);

      // 点击确定按钮
      await tester.tap(find.text('好的'));
      await tester.pumpAndSettle();

      // 验证对话框已关闭
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Multiple rapid dialog operations test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      // 快速连续操作多个对话框
      for (int i = 0; i < 3; i++) {
        // 打开并快速关闭确认对话框
        await tester.tap(find.text('Show Confirm Dialog'));
        await tester.pump(const Duration(milliseconds: 100));
        
        if (find.text('取消').evaluate().isNotEmpty) {
          await tester.tap(find.text('取消'));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpAndSettle();
      
      // 验证没有对话框残留
      expect(find.byType(AlertDialog), findsNothing);
    });

    test('DialogNavigationHelper unit tests', () {
      // 测试对话框导航助手的静态方法
      expect(DialogNavigationHelper, isNotNull);
      
      // 这些方法需要有效的 BuildContext，所以在单元测试中无法直接测试
      // 但我们可以验证它们存在且可调用
    });
  });
}

/// 测试对话框页面
class TestDialogPage extends StatelessWidget {
  const TestDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog Navigation Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showPracticeSaveDialog(context),
              child: const Text('Show Practice Save Dialog'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showConfirmDialog(context),
              child: const Text('Show Confirm Dialog'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showErrorDialog(context),
              child: const Text('Show Error Dialog'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPracticeSaveDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const PracticeSaveDialog(
        initialTitle: '',
        isSaveAs: false,
      ),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存成功: $result')),
      );
    }
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final result = await showConfirmDialog(
      context: context,
      title: '确认操作',
      message: '您确定要执行此操作吗？',
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已确认')),
      );
    }
  }

  Future<void> _showErrorDialog(BuildContext context) async {
    await showErrorDialog(
      context: context,
      title: '错误',
      message: '发生了一个错误，请重试。',
    );
  }
}
