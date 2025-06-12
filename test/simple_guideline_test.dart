import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/presentation/widgets/practice/guideline_alignment/guideline_manager.dart';

void main() {
  test('Simple GuidelineManager test', () {
    final manager = GuidelineManager.instance;
    expect(manager, isNotNull);
  });
}
