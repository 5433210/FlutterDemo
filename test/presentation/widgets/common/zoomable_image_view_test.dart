import 'dart:io';

import 'package:demo/presentation/widgets/common/zoomable_image_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_lib;

void main() {
  // Test image path
  late String testImagePath;

  setUpAll(() async {
    // Create a test image file
    final testDir = Directory('test/assets');
    testDir.createSync(recursive: true);
    testImagePath = path_lib.join(testDir.path, 'test_image.png');
    File(testImagePath).writeAsBytesSync(kTransparentImage);

    // Register platform channels for keyboard events
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      SystemChannels.keyEvent.name,
      (ByteData? message) async => null,
    );
  });

  tearDownAll(() {
    // Clean up test files
    Directory('test/assets').deleteSync(recursive: true);
  });

  group('ZoomableImageView', () {
    testWidgets('displays image and basic controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: testImagePath,
              showControls: true,
            ),
          ),
        ),
      );

      // Verify image is displayed
      expect(find.byType(Image), findsOneWidget);

      // Initially no zoom controls as not zoomed
      expect(find.byIcon(Icons.zoom_out_map), findsNothing);
    });

    testWidgets('handles pinch zoom', (tester) async {
      bool scaleChanged = false;
      double? lastScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: testImagePath,
              showControls: true,
              onScaleChanged: (scale) {
                scaleChanged = true;
                lastScale = scale;
              },
            ),
          ),
        ),
      );

      // Simulate pinch zoom
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final gesture1 = await tester.createGesture();
      final gesture2 = await tester.createGesture();

      await gesture1.down(center);
      await gesture2.down(center + const Offset(20, 0));
      await tester.pump();

      await gesture1.moveTo(center - const Offset(10, 0));
      await gesture2.moveTo(center + const Offset(30, 0));
      await tester.pump();

      // Verify zoom state changed
      expect(scaleChanged, isTrue);

      // Zoom control should appear
      await tester.pump();
      expect(find.byIcon(Icons.zoom_out_map), findsOneWidget);

      // Clean up
      await gesture1.up();
      await gesture2.up();
    });

    testWidgets('handles mouse wheel zoom', (tester) async {
      bool scaleChanged = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: testImagePath,
              enableMouseWheel: true,
              onScaleChanged: (scale) => scaleChanged = true,
            ),
          ),
        ),
      );

      // Simulate Ctrl + Mouse wheel
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.controlLeft,
          character: 'Control');

      final center = tester.getCenter(find.byType(InteractiveViewer));
      final testPointer = TestPointer(1, PointerDeviceKind.mouse);

      // Add pointer
      await tester.sendEventToBinding(testPointer.hover(center));

      // Send scroll wheel event
      await tester
          .sendEventToBinding(testPointer.scroll(const Offset(0, -20.0)));
      await tester.pumpAndSettle();

      // Verify scale changed
      expect(scaleChanged, isTrue);

      // Clean up
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });

    testWidgets('handles tap interaction', (tester) async {
      Offset? tapPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: testImagePath,
              onTapDown: (position) => tapPosition = position,
            ),
          ),
        ),
      );

      // Tap the image
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      // Verify tap was registered
      expect(tapPosition, isNotNull);
      expect(tapPosition!.dx, 100);
      expect(tapPosition!.dy, 100);
    });

    testWidgets('shows error state for invalid image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: 'invalid_path.png',
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify error state is shown
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
      expect(find.text('无法加载图片'), findsOneWidget);
    });

    testWidgets('supports custom error builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: 'invalid_path.png',
              errorBuilder: (context, error, stack) =>
                  const Text('Custom Error'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify custom error is shown
      expect(find.text('Custom Error'), findsOneWidget);
    });

    testWidgets('supports custom loading builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: testImagePath,
              loadingBuilder: (context) => const Text('Custom Loading'),
            ),
          ),
        ),
      );

      // Verify custom loading is shown initially
      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('respects zoom limits', (tester) async {
      const minScale = 0.5;
      const maxScale = 2.0;
      double? lastScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImageView(
              imagePath: testImagePath,
              minScale: minScale,
              maxScale: maxScale,
              onScaleChanged: (scale) => lastScale = scale,
            ),
          ),
        ),
      );

      // Test minimum scale
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final testPointer = TestPointer(2, PointerDeviceKind.mouse);

      // Add pointer and zoom out
      await tester.sendEventToBinding(testPointer.hover(center));
      await tester
          .sendEventToBinding(testPointer.scroll(const Offset(0, 100.0)));
      await tester.pumpAndSettle();
      expect(lastScale, greaterThanOrEqualTo(minScale));

      // Zoom in
      await tester
          .sendEventToBinding(testPointer.scroll(const Offset(0, -100.0)));
      await tester.pumpAndSettle();
      expect(lastScale, lessThanOrEqualTo(maxScale));

      // Clean up
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });
  });
}

// 1x1 transparent PNG
const kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82
];
