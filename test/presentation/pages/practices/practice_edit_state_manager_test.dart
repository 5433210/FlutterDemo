import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/presentation/pages/practices/state/practice_edit_state_manager.dart';

void main() {
  group('PracticeEditStateManager Tests', () {
    late PracticeEditStateManager stateManager;

    setUp(() {
      stateManager = PracticeEditStateManager();
    });

    tearDown(() {
      stateManager.dispose();
    });

    test('初始状态应该正确', () {
      expect(stateManager.isLeftPanelOpen, false);
      expect(stateManager.isRightPanelOpen, true);
      expect(stateManager.showThumbnails, false);
      expect(stateManager.isPreviewMode, false);
      expect(stateManager.currentTool, '');
      expect(stateManager.isFormatBrushActive, false);
      expect(stateManager.clipboardHasContent, false);
    });

    test('左侧面板状态切换应该正常工作', () {
      expect(stateManager.isLeftPanelOpen, false);

      stateManager.toggleLeftPanel();
      expect(stateManager.isLeftPanelOpen, true);

      stateManager.setLeftPanelOpen(false);
      expect(stateManager.isLeftPanelOpen, false);
    });

    test('工具状态管理应该正常工作', () {
      expect(stateManager.currentTool, '');

      stateManager.setCurrentTool('text');
      expect(stateManager.currentTool, 'text');

      // 设置相同的工具不应该触发通知
      stateManager.setCurrentTool('text');
      expect(stateManager.currentTool, 'text');
    });

    test('格式刷状态管理应该正常工作', () {
      expect(stateManager.isFormatBrushActive, false);
      expect(stateManager.formatBrushStyles, null);

      stateManager.activateFormatBrush();
      expect(stateManager.isFormatBrushActive, true);

      final mockElement = {'id': 'test', 'fontSize': 16};
      stateManager.copyFormatBrushStyles(mockElement);
      expect(stateManager.formatBrushStyles, isNotNull);

      stateManager.deactivateFormatBrush();
      expect(stateManager.isFormatBrushActive, false);
      expect(stateManager.formatBrushStyles, null);
    });

    test('剪贴板状态管理应该正常工作', () {
      expect(stateManager.clipboardHasContent, false);
      expect(stateManager.clipboardElement, null);

      final mockElement = {'id': 'test', 'type': 'text'};
      stateManager.copyElement(mockElement);
      expect(stateManager.clipboardHasContent, true);
      expect(stateManager.clipboardElement, mockElement);

      stateManager.clearClipboard();
      expect(stateManager.clipboardHasContent, false);
      expect(stateManager.clipboardElement, null);
    });

    test('预览模式切换应该正常工作', () {
      expect(stateManager.isPreviewMode, false);

      stateManager.togglePreviewMode();
      expect(stateManager.isPreviewMode, true);

      stateManager.setPreviewMode(false);
      expect(stateManager.isPreviewMode, false);
    });

    test('缩略图显示状态管理应该正常工作', () {
      expect(stateManager.showThumbnails, false);

      stateManager.toggleShowThumbnails();
      expect(stateManager.showThumbnails, true);

      stateManager.setShowThumbnails(false);
      expect(stateManager.showThumbnails, false);
    });
  });
}
