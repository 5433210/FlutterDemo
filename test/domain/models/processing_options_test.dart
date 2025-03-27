import 'package:demo/domain/models/character/processing_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessingOptions', () {
    test('should create with default values', () {
      const options = ProcessingOptions();
      expect(options.inverted, false);
      expect(options.showContour, false);
      expect(options.threshold, 0.5);
      expect(options.noiseReduction, 0.5);
    });
  });
}
