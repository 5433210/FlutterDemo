import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'performance_utils.dart';
import 'test_work_import_view_model.dart';

Future<void> main() async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProviderContainer container;
  late TestWorkImportViewModel viewModel;
  late PerformanceProfiler profiler;

  setUpAll(() async {
    tempDir = await getTemporaryDirectory();
  });

  setUp(() {
    container = ProviderContainer();
    viewModel = TestWorkImportViewModel();
    profiler = PerformanceProfiler();

    binding.window.physicalSizeTestValue = const Size(400, 800);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    viewModel.dispose();
    profiler.stopProfiling();
    container.dispose();
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  tearDownAll(() async {
    final files = tempDir.listSync().where((e) => e.path.endsWith('.jpg'));
    for (final file in files) {
      await file.delete();
    }
  });

  Future<File> createTestImage() async {
    final bytes = List<int>.filled(1024 * 1024, 0); // 1MB test image
    final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(path.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  // Test implementations to follow...

  // Previous test groups remain the same...
}

const _accessibilityScales = [1.0, 1.3, 1.5];
const _accessibleFrameThreshold = 20.0;
const _jankPercentageThreshold = 5.0;
const _normalFrameThreshold = 16.0;
const _platforms = ['android', 'ios'];

// Test configurations
final _screenSizes = <Size>[
  const Size(320, 480), // Small phone
  const Size(400, 800), // Regular phone
  const Size(600, 1024), // Tablet
  const Size(800, 1200), // Large tablet
];

class TestConfig {
  final Size screenSize;
  final String platform;
  final double textScale;
  final bool highContrast;
  final bool reduceMotion;

  const TestConfig({
    required this.screenSize,
    required this.platform,
    this.textScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
  });

  @override
  String toString() {
    return '$platform ${screenSize.width.toInt()}x${screenSize.height.toInt()}'
        '${textScale != 1.0 ? ", ${textScale}x text" : ""}'
        '${highContrast ? ", high contrast" : ""}'
        '${reduceMotion ? ", reduced motion" : ""}';
  }
}
