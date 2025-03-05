import 'package:demo/domain/models/character/character_image.dart';
import 'package:demo/domain/models/processing_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterImage', () {
    const testSize = ImageSize(width: 100, height: 200);
    const testOptions = ProcessingOptions(
      inverted: true,
      threshold: 0.7,
    );

    test('should create with required values', () {
      final image = const CharacterImage(
        path: 'path/to/image',
        binary: 'path/to/binary',
        thumbnail: 'path/to/thumbnail',
        size: testSize,
      );

      expect(image.path, 'path/to/image');
      expect(image.binary, 'path/to/binary');
      expect(image.thumbnail, 'path/to/thumbnail');
      expect(image.svg, null);
      expect(image.processingOptions, null);
      expect(image.size.width, 100);
      expect(image.size.height, 200);
    });

    test('should create with all values', () {
      final image = const CharacterImage(
        path: 'path/to/image',
        binary: 'path/to/binary',
        thumbnail: 'path/to/thumbnail',
        svg: 'path/to/svg',
        size: testSize,
        processingOptions: testOptions,
      );

      expect(image.svg, 'path/to/svg');
      expect(image.processingOptions, testOptions);
    });
  });

  group('ImageSize', () {
    test('should create with values', () {
      const size = ImageSize(width: 100, height: 200);
      expect(size.width, 100);
      expect(size.height, 200);
    });
  });
}
