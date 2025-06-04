import 'dart:async';

import 'package:charasgem/presentation/pages/practices/widgets/content_render_controller.dart';
import 'package:charasgem/presentation/pages/practices/widgets/element_change_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Canvas Performance Tests - Task 2 Verification', () {
    testWidgets(
        'ContentRenderController should handle element changes efficiently',
        (WidgetTester tester) async {
      final controller = ContentRenderController();

      // Test element initialization
      final testElements = [
        {
          'id': 'element1',
          'type': 'text',
          'x': 100.0,
          'y': 100.0,
          'width': 200.0,
          'height': 50.0
        },
        {
          'id': 'element2',
          'type': 'image',
          'x': 200.0,
          'y': 200.0,
          'width': 300.0,
          'height': 200.0
        },
      ];

      controller.initializeElements(testElements);

      expect(controller.isElementTracked('element1'), isTrue);
      expect(controller.isElementTracked('element2'), isTrue);

      // Test element change detection
      controller.notifyElementChanged(
        elementId: 'element1',
        newProperties: {
          'id': 'element1',
          'type': 'text',
          'x': 150.0,
          'y': 100.0,
          'width': 200.0,
          'height': 50.0
        },
      );

      final changes = controller.getChangesForElement('element1');
      expect(changes.length, equals(1));
      expect(changes.first.changeType, equals(ElementChangeType.positionOnly));

      controller.dispose();
    });

    testWidgets('ContentRenderController should categorize changes correctly',
        (WidgetTester tester) async {
      final controller = ContentRenderController();

      // Initialize element
      controller.initializeElement(
        elementId: 'test_element',
        properties: {
          'id': 'test_element',
          'type': 'text',
          'x': 100.0,
          'y': 100.0,
          'width': 200.0,
          'height': 50.0,
          'opacity': 1.0
        },
      );

      // Test position-only change
      controller.notifyElementChanged(
        elementId: 'test_element',
        newProperties: {
          'id': 'test_element',
          'type': 'text',
          'x': 150.0,
          'y': 120.0,
          'width': 200.0,
          'height': 50.0,
          'opacity': 1.0
        },
      );

      // Test size-only change
      controller.notifyElementChanged(
        elementId: 'test_element',
        newProperties: {
          'id': 'test_element',
          'type': 'text',
          'x': 150.0,
          'y': 120.0,
          'width': 250.0,
          'height': 60.0,
          'opacity': 1.0
        },
      );

      // Test opacity-only change
      controller.notifyElementChanged(
        elementId: 'test_element',
        newProperties: {
          'id': 'test_element',
          'type': 'text',
          'x': 150.0,
          'y': 120.0,
          'width': 250.0,
          'height': 60.0,
          'opacity': 0.5
        },
      );

      final changes = controller.getChangesForElement('test_element');
      expect(changes.length, equals(3));
      expect(changes[0].changeType, equals(ElementChangeType.positionOnly));
      expect(changes[1].changeType, equals(ElementChangeType.sizeOnly));
      expect(changes[2].changeType, equals(ElementChangeType.opacity));

      controller.dispose();
    });
    test('ContentRenderController stream should emit changes', () async {
      final controller = ContentRenderController();
      final List<ElementChangeInfo> receivedChanges = [];
      final Completer<void> completer = Completer<void>();

      // Listen to change stream
      final subscription = controller.changeStream.listen((change) {
        receivedChanges.add(change);
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Initialize and change element
      controller.initializeElement(
        elementId: 'stream_test',
        properties: {
          'id': 'stream_test',
          'type': 'text',
          'x': 100.0,
          'y': 100.0
        },
      );

      controller.notifyElementChanged(
        elementId: 'stream_test',
        newProperties: {
          'id': 'stream_test',
          'type': 'text',
          'x': 200.0,
          'y': 200.0
        },
      );

      // Wait for stream event with timeout
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException(
            'Stream event not received', const Duration(seconds: 2)),
      );

      expect(receivedChanges.length, equals(1));
      expect(receivedChanges.first.elementId, equals('stream_test'));
      expect(receivedChanges.first.changeType,
          equals(ElementChangeType.positionOnly));

      await subscription.cancel();
      controller.dispose();
    });

    test('ElementChangeInfo should detect change types correctly', () {
      final oldProps = {
        'id': 'test',
        'type': 'text',
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 50.0,
        'opacity': 1.0,
        'content': {'text': 'Hello'}
      };

      // Test position change
      final positionChange = ElementChangeInfo.fromChanges(
        elementId: 'test',
        oldProperties: oldProps,
        newProperties: {...oldProps, 'x': 150.0, 'y': 120.0},
      );
      expect(positionChange.changeType, equals(ElementChangeType.positionOnly));

      // Test size change
      final sizeChange = ElementChangeInfo.fromChanges(
        elementId: 'test',
        oldProperties: oldProps,
        newProperties: {...oldProps, 'width': 250.0, 'height': 60.0},
      );
      expect(sizeChange.changeType, equals(ElementChangeType.sizeOnly));

      // Test content change
      final contentChange = ElementChangeInfo.fromChanges(
        elementId: 'test',
        oldProperties: oldProps,
        newProperties: {
          ...oldProps,
          'content': {'text': 'World'}
        },
      );
      expect(contentChange.changeType, equals(ElementChangeType.contentOnly));

      // Test combined change
      final combinedChange = ElementChangeInfo.fromChanges(
        elementId: 'test',
        oldProperties: oldProps,
        newProperties: {
          ...oldProps,
          'x': 150.0,
          'width': 250.0,
          'content': {'text': 'World'}
        },
      );
      expect(combinedChange.changeType, equals(ElementChangeType.multiple));
    });
  });
}
