import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_types.dart';
import 'package:charasgem/presentation/widgets/practice/practice_edit_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('对齐模式调试测试', () {
    test('toggleAlignmentMode方法调用测试', () {
      final state = PracticeEditState();

      // 初始状态应该是none
      expect(state.alignmentMode, AlignmentMode.none);
      print('初始状态: ${state.alignmentMode}');

      // 第一次切换应该变为gridSnap
      state.toggleAlignmentMode();
      expect(state.alignmentMode, AlignmentMode.gridSnap);
      print('第一次切换: ${state.alignmentMode}');

      // 第二次切换应该变为guideline
      state.toggleAlignmentMode();
      expect(state.alignmentMode, AlignmentMode.guideline);
      print('第二次切换: ${state.alignmentMode}');

      // 第三次切换应该回到none
      state.toggleAlignmentMode();
      expect(state.alignmentMode, AlignmentMode.none);
      print('第三次切换: ${state.alignmentMode}');

      print('toggleAlignmentMode方法调用测试通过！');
    });
  });
}
