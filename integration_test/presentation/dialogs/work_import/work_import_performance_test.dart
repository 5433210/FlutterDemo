import 'dart:io';
import 'dart:math' show Random;

import 'package:demo/presentation/dialogs/work_import/components/form/work_import_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'performance_utils.dart';
import 'test_work_import_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });

  tearDown(() {
    viewModel.dispose();
    profiler.stopProfiling();
    container.dispose();
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

  Widget buildTestWidget(TestConfig config) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: config.screenSize,
          highContrast: config.highContrast,
          textScaler: TextScaler.linear(config.textScale),
          platformBrightness: Brightness.light,
        ),
        child: child!,
      ),
      theme: ThemeData(
        platform: config.platform == 'ios'
            ? TargetPlatform.iOS
            : TargetPlatform.android,
      ),
      home: ProviderScope(
        parent: container,
        child: Material(
          child: WorkImportForm(
            viewModel: viewModel,
            state: viewModel.state,
          ),
        ),
      ),
    );
  }

  // Test implementations...
  // Previous test groups remain the same...
}

const _accessibilityScales = [1.0, 1.3, 1.5];
const _accessibleFrameThreshold = 20.0;
const _jankPercentageThreshold = 5.0;
const _normalFrameThreshold = 16.0;
const _platforms = ['android', 'ios'];

// Test configurations
const _screenSizes = <Size>[
  Size(320, 480), // Small phone
  Size(400, 800), // Regular phone
  Size(600, 1024), // Tablet
  Size(800, 1200), // Large tablet
];

/// Helper to simulate network conditions
Future<T> withNetworkCondition<T>({
  required NetworkCondition condition,
  required Future<T> Function() operation,
}) async {
  if (condition.packetLoss > 0 &&
      Random().nextDouble() < condition.packetLoss) {
    throw const SocketException('Simulated packet loss');
  }

  await Future.delayed(condition.latency);
  final result = await operation();

  final bytes = 100 * 1024; // Assume 100KB response
  final transferTime =
      Duration(milliseconds: (bytes / condition.bandwidth).ceil());
  await Future.delayed(transferTime);

  return result;
}

/// Network conditions to test
class NetworkCondition {
  static const fast = NetworkCondition(
    name: 'Fast 4G',
    latency: Duration(milliseconds: 50),
    bandwidth: 1000,
  );
  static const slow = NetworkCondition(
    name: 'Slow 3G',
    latency: Duration(milliseconds: 200),
    packetLoss: 0.03,
    bandwidth: 100,
  );
  static const poor = NetworkCondition(
    name: 'Poor Network',
    latency: Duration(milliseconds: 400),
    packetLoss: 0.05,
    bandwidth: 50,
  );
  final String name;

  final Duration latency;

  final double packetLoss;

  final int bandwidth; // KB/s

  const NetworkCondition({
    required this.name,
    required this.latency,
    this.packetLoss = 0.0,
    required this.bandwidth,
  });
}

/// Test configuration
class TestConfig {
  final Size screenSize;
  final String platform;
  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  final NetworkCondition? networkCondition;

  const TestConfig({
    required this.screenSize,
    required this.platform,
    this.textScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
    this.networkCondition,
  });

  @override
  String toString() {
    final features = <String>[
      '$platform ${screenSize.width.toInt()}x${screenSize.height.toInt()}',
      if (textScale != 1.0) '${textScale}x text',
      if (highContrast) 'high contrast',
      if (reduceMotion) 'reduced motion',
      if (networkCondition != null) networkCondition!.name,
    ];
    return features.join(', ');
  }
}
