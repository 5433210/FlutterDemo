import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';
import 'package:charasgem/presentation/widgets/practice/intelligent_notification_mixin.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_state.dart';
import 'package:charasgem/presentation/widgets/practice/tool_management_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolManagementMixin toggleAlignmentMode 测试', () {
    late TestController controller;

    setUp(() {
      controller = TestController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('toggleAlignmentMode 方法应该正确切换模式', () {
      // 初始状态应该是none
      expect(controller.state.alignmentMode, equals(AlignmentMode.none));
      print('初始模式: ${controller.state.alignmentMode.name}');

      // 第一次切换：none -> gridSnap
      controller.toggleAlignmentMode();
      expect(controller.state.alignmentMode, equals(AlignmentMode.gridSnap));
      print('第一次切换后: ${controller.state.alignmentMode.name}');

      // 第二次切换：gridSnap -> guideline
      controller.toggleAlignmentMode();
      expect(controller.state.alignmentMode, equals(AlignmentMode.guideline));
      print('第二次切换后: ${controller.state.alignmentMode.name}');

      // 第三次切换：guideline -> none
      controller.toggleAlignmentMode();
      expect(controller.state.alignmentMode, equals(AlignmentMode.none));
      print('第三次切换后: ${controller.state.alignmentMode.name}');

      print('✅ toggleAlignmentMode 方法测试通过！');
    });

    test('setAlignmentMode 方法应该正确设置模式', () {
      // 测试直接设置模式
      controller.setAlignmentMode(AlignmentMode.guideline);
      expect(controller.state.alignmentMode, equals(AlignmentMode.guideline));
      print('设置为guideline模式: ${controller.state.alignmentMode.name}');

      controller.setAlignmentMode(AlignmentMode.gridSnap);
      expect(controller.state.alignmentMode, equals(AlignmentMode.gridSnap));
      print('设置为gridSnap模式: ${controller.state.alignmentMode.name}');

      controller.setAlignmentMode(AlignmentMode.none);
      expect(controller.state.alignmentMode, equals(AlignmentMode.none));
      print('设置为none模式: ${controller.state.alignmentMode.name}');

      print('✅ setAlignmentMode 方法测试通过！');
    });

    test('snapEnabled 状态应该与gridSnap模式同步', () {
      // 初始状态
      expect(controller.state.snapEnabled, isFalse);

      // 切换到gridSnap模式
      controller.setAlignmentMode(AlignmentMode.gridSnap);
      expect(controller.state.snapEnabled, isTrue);
      print('gridSnap模式下，snapEnabled: ${controller.state.snapEnabled}');

      // 切换到其他模式
      controller.setAlignmentMode(AlignmentMode.guideline);
      expect(controller.state.snapEnabled, isFalse);
      print('guideline模式下，snapEnabled: ${controller.state.snapEnabled}');

      controller.setAlignmentMode(AlignmentMode.none);
      expect(controller.state.snapEnabled, isFalse);
      print('none模式下，snapEnabled: ${controller.state.snapEnabled}');

      print('✅ snapEnabled 状态同步测试通过！');
    });
  });
}

// 创建一个测试类来实现mixin
class TestController extends ChangeNotifier
    with ToolManagementMixin, IntelligentNotificationMixin {
  final PracticeEditState _state = PracticeEditState();
  bool _disposed = false;

  @override
  dynamic get intelligentDispatcher => null; // 简单的测试实现

  @override
  PracticeEditState get state => _state;

  @override
  void checkDisposed() {
    if (_disposed) {
      throw StateError('Controller has been disposed');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void intelligentNotify({
    required String changeType,
    String? operation,
    required Map<String, dynamic> eventData,
    List<String>? affectedElements,
    List<String>? affectedUIComponents,
    List<String>? affectedLayers,
  }) {
    // 简单的通知实现
    notifyListeners();
  }

  @override
  void throttledNotifyListeners({Duration? delay}) {
    // 简单的节流通知实现
    notifyListeners();
  }
}
