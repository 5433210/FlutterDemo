import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_work_import_view_model.dart';

/// Helper for accessibility interactions
Future<void> performAccessibilityChecks(
  WidgetTester tester,
  TestWorkImportViewModel model,
) async {
  // Test keyboard navigation
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();

  await tester.enterText(find.byType(TextField).first, 'Test Title');
  await tester.pump();

  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();

  await tester.enterText(find.byType(TextField).at(1), 'Test Author');
  await tester.pump();

  // Test form controls are accessible
  expect(
    tester.getSemantics(find.byType(TextField).first),
    matchesSemantics(
      isTextField: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
    ),
  );
}

/// Helper for basic form inputs
Future<void> performBasicInputs(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Test Title');
  await tester.pump(const Duration(milliseconds: 16));

  await tester.enterText(find.byType(TextField).at(1), 'Test Author');
  await tester.pump(const Duration(milliseconds: 16));

  await tester.enterText(find.byType(TextField).last, 'Test Remark');
  await tester.pump(const Duration(milliseconds: 16));
}

/// Helper for image operations
Future<void> performImageOperations(
  WidgetTester tester,
  List<File> images,
  TestWorkImportViewModel model,
) async {
  for (var i = 0; i < images.length; i++) {
    model.selectImage(i);
    await tester.pump(const Duration(milliseconds: 16));

    // Simulate image rotation
    if (i % 2 == 0) {
      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  // Test reordering
  if (images.length > 1) {
    model.reorderImages(0, images.length - 1);
    await tester.pumpAndSettle();
  }
}

/// Helper for platform-specific gestures
Future<void> performPlatformGestures(
  WidgetTester tester,
  String platform,
) async {
  if (platform == 'ios') {
    await tester.drag(
      find.byType(CupertinoTextField),
      const Offset(-100, 0),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final textField = find.byType(CupertinoTextField).first;
    await tester.timedDrag(
      textField,
      const Offset(50, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump();
  } else {
    await tester.fling(
      find.byType(TextField).first,
      const Offset(0, -200),
      1000,
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(TextField).first);
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Helper for rapid interactions
Future<void> performRapidInteractions(WidgetTester tester) async {
  // Rapid typing
  for (var i = 0; i < 10; i++) {
    await tester.enterText(find.byType(TextField).first, 'Test Title $i');
    await tester.pump(const Duration(milliseconds: 8));
  }

  // Quick scrolling
  for (var i = 0; i < 5; i++) {
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 100),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}
