import "package:flutter_test/flutter_test.dart";
import "package:demo/domain/models/processing_options.dart";

void main() {
  group("ProcessingOptions", () {
    test("should create with default values", () {
      final options = ProcessingOptions();
      expect(options.inverted, false);
      expect(options.showContour, false);
      expect(options.threshold, 0.5);
      expect(options.noiseReduction, 0.5);
      expect(options.removeBg, true);
    });
  });
}
