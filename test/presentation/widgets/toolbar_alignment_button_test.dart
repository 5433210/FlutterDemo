import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:charasgem/application/services/practice/practice_service.dart';
import 'package:charasgem/l10n/app_localizations.dart';
import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';
import 'package:charasgem/presentation/widgets/practice/m3_edit_toolbar.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_controller.dart';

void main() {
  group('工具栏对齐模式按钮测试', () {
    testWidgets('对齐模式按钮应该存在并且可以点击', (WidgetTester tester) async {
      // 创建一个假的控制器
      final mockService = MockPracticeService();
      final controller = PracticeEditController(mockService);
      bool toggleCalled = false;

      // 构建测试应用
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('zh', ''), // Chinese
          ],
          home: Scaffold(
            appBar: M3EditToolbar(
              controller: controller,
              gridVisible: false,
              snapEnabled: false,
              alignmentMode: AlignmentMode.none,
              onToggleGrid: () {},
              onToggleSnap: () {},
              onToggleAlignmentMode: () {
                toggleCalled = true;
                print('toggleAlignmentMode 被调用了！');
              },
              onCopy: () {},
              onPaste: () {},
              onGroupElements: () {},
              onUngroupElements: () {},
              onBringToFront: () {},
              onSendToBack: () {},
              onMoveUp: () {},
              onMoveDown: () {},
              onDelete: () {},
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );

      // 等待本地化加载
      await tester.pumpAndSettle();

      print('寻找对齐模式按钮...');

      // 简单查找：直接找包含 "无辅助对齐" 的Tooltip
      final alignmentTooltip = find.byWidgetPredicate((widget) {
        return widget is Tooltip && widget.message?.contains('无辅助对齐') == true;
      });

      expect(alignmentTooltip, findsOneWidget, reason: '应该找到一个对齐模式按钮');

      print('找到对齐模式按钮，尝试点击...');

      // 找到tooltip的子IconButton
      final iconButton = find.descendant(
        of: alignmentTooltip,
        matching: find.byType(IconButton),
      );

      expect(iconButton, findsOneWidget, reason: '应该在tooltip中找到IconButton');

      // 点击按钮
      await tester.tap(iconButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // 验证回调被调用
      expect(toggleCalled, true, reason: 'toggleAlignmentMode 回调应该被调用');
      print('测试成功：按钮点击成功触发回调');
    });
  });
}

// Mock classes
class MockPracticeService extends Mock implements PracticeService {}
