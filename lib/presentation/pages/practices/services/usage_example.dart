// Example usage of UnifiedServiceManager with Core Adapter Integration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../canvas/compatibility/canvas_controller_adapter.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import 'unified_service_manager.dart';

/// Provider for the service manager (optional)
final serviceManagerProvider = Provider<UnifiedServiceManager>((ref) {
  return UnifiedServiceManager.instance;
});

/// Example of how to initialize the service manager in your app startup
class ServiceManagerInitializer {
  static Future<void> initialize({
    required CanvasControllerAdapter canvasController,
    required WidgetRef widgetRef,
    required PracticeEditController practiceController,
  }) async {
    final serviceManager = UnifiedServiceManager.instance;

    // Initialize with all dependencies
    serviceManager.initializeWithDependencies(
      canvasController: canvasController,
      widgetRef: widgetRef,
    );

    // Set the practice controller
    serviceManager.setController(practiceController);

    print('🚀 UnifiedServiceManager fully initialized with all adapters');

    // Verify all adapters are registered
    final debugInfo = serviceManager.getDebugInfo();
    print('📊 Registered adapters: ${debugInfo['registeredAdapters']}');
  }
}

/// Example widget showing how to integrate UnifiedServiceManager with all adapters
class UnifiedServiceManagerExample extends ConsumerWidget {
  const UnifiedServiceManagerExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Service Manager - Core Adapter Integration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _initializeServiceManager(ref),
              child: const Text('Initialize Service Manager'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showDebugInfo,
              child: const Text('Show Debug Info'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showRegisteredAdapters,
              child: const Text('Show Registered Adapters'),
            ),
            const SizedBox(height: 16),
            const Text(
              'This example demonstrates the complete Core Adapter Integration:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('✅ UnifiedServiceManager with dependency injection'),
            const Text('✅ PagePropertyAdapter registration'),
            const Text('✅ MultiSelectionPropertyAdapter integration'),
            const Text('✅ LayerPanelAdapter integration'),
            const Text('✅ CollectionPropertyAdapter integration'),
            const Text('✅ ShapePropertyAdapter integration'),
            const Text('✅ Service registration system'),
            const Text('✅ Enhanced adapter management'),
          ],
        ),
      ),
    );
  }

  /// Create a mock canvas controller for demonstration
  CanvasControllerAdapter _createMockCanvasController() {
    // In a real implementation, this would be your actual canvas controller
    // For demonstration purposes, we'll return a mock or placeholder
    // This is just for compilation - replace with actual implementation
    throw UnimplementedError(
        'Replace with actual CanvasControllerAdapter implementation');
  }

  /// Create a mock practice controller for demonstration
  PracticeEditController _createMockPracticeController() {
    // In a real implementation, this would be your actual practice controller
    // For demonstration purposes, we'll return a mock or placeholder
    // This is just for compilation - replace with actual implementation
    throw UnimplementedError(
        'Replace with actual PracticeEditController implementation');
  }

  /// Initialize the service manager with all dependencies
  void _initializeServiceManager(WidgetRef ref) {
    final serviceManager = UnifiedServiceManager.instance;

    // Create mock dependencies for demonstration
    final mockCanvasController = _createMockCanvasController();
    final mockPracticeController = _createMockPracticeController();

    // Initialize with all dependencies
    serviceManager.initializeWithDependencies(
      canvasController: mockCanvasController,
      widgetRef: ref,
    );

    // Set the practice controller
    serviceManager.setController(mockPracticeController);

    print('✅ Service Manager initialized with all dependencies');
  }

  /// Show debug information about the service manager
  void _showDebugInfo() {
    final serviceManager = UnifiedServiceManager.instance;
    final debugInfo = serviceManager.getDebugInfo();

    print('🔍 UnifiedServiceManager Debug Info:');
    debugInfo.forEach((key, value) {
      print('  $key: $value');
    });
  }

  /// Show all registered adapters
  void _showRegisteredAdapters() {
    final serviceManager = UnifiedServiceManager.instance;
    final adapterTypes = serviceManager.registeredAdapterTypes;

    print('📋 Registered Adapters (${adapterTypes.length}):');
    for (final type in adapterTypes) {
      final adapter = serviceManager.getAdapter(type);
      print('  $type: ${adapter?.runtimeType}');
    }
  }
}
