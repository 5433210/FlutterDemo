import 'dart:io';

import 'package:demo/domain/models/work/work_image.dart';
import 'package:demo/presentation/pages/works/components/thumbnail_strip.dart';
import 'package:demo/presentation/widgets/common/zoomable_image_view.dart';
import 'package:demo/presentation/widgets/works/enhanced_work_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<WorkImage> testImages;
  late String testImagePath;
  final now = DateTime.now();

  setUpAll(() {
    // Create test directory and files
    final testDir = Directory('test/assets');
    testDir.createSync(recursive: true);
    testImagePath = '${testDir.path}/test_image.png';
    File(testImagePath).writeAsBytesSync(kTransparentImage);

    // Create test images
    testImages = List.generate(
      3,
      (i) => WorkImage(
        id: 'test_$i',
        path: testImagePath,
        workId: 'work_1',
        originalPath: testImagePath,
        thumbnailPath: testImagePath,
        index: i,
        width: 100,
        height: 100,
        format: 'png',
        size: 100,
        createTime: now,
        updateTime: now,
      ),
    );
  });

  tearDownAll(() {
    Directory('test/assets').deleteSync(recursive: true);
  });

  group('EnhancedWorkPreview', () {
    testWidgets('displays empty state when no images', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWorkPreview(
              images: [],
              selectedIndex: 0,
            ),
          ),
        ),
      );

      expect(find.text('没有可显示的图片'), findsOneWidget);
    });

    testWidgets('displays custom toolbar actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWorkPreview(
              images: testImages,
              selectedIndex: 0,
              showToolbar: true,
              toolbarActions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                  tooltip: 'Add',
                ),
              ],
            ),
          ),
        ),
      );

      // Verify toolbar is shown
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Add'), findsOneWidget);
    });

    testWidgets('handles image selection', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWorkPreview(
              images: testImages,
              selectedIndex: 0,
              onIndexChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      // Find and tap thumbnail area
      await tester.tap(find.byType(ThumbnailStrip<WorkImage>));
      await tester.pump();

      expect(selectedIndex, isNotNull);
    });

    testWidgets('enables reordering in edit mode', (tester) async {
      int? oldIndex;
      int? newIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWorkPreview(
              images: testImages,
              selectedIndex: 0,
              isEditing: true,
              onImagesReordered: (o, n) {
                oldIndex = o;
                newIndex = n;
              },
            ),
          ),
        ),
      );

      final strip = find.byType(ThumbnailStrip<WorkImage>);
      expect(strip, findsOneWidget);

      // Verify reordering is enabled
      final stripWidget = tester.widget<ThumbnailStrip<WorkImage>>(strip);
      expect(stripWidget.isEditable, isTrue);
    });

    testWidgets('supports zooming image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWorkPreview(
              images: testImages,
              selectedIndex: 0,
            ),
          ),
        ),
      );

      final zoomableView = find.byType(ZoomableImageView);
      expect(zoomableView, findsOneWidget);

      // Verify zoom properties
      final view = tester.widget<ZoomableImageView>(zoomableView);
      expect(view.enableMouseWheel, isTrue);
      expect(view.minScale, equals(0.5));
      expect(view.maxScale, equals(4.0));
    });
  });
}

// 1x1 transparent PNG for testing
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
