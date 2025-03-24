import 'dart:io';

import 'package:demo/infrastructure/image/image_processor.dart';

class MockImageProcessor implements ImageProcessor {
  bool shouldFail = false;
  final processedImages = <File>[];
  final processedParams = <Map<String, dynamic>>[];

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }

  @override
  Future<File> processImage(
    File image, {
    required int maxHeight,
    required int maxWidth,
    required int quality,
  }) async {
    if (shouldFail) {
      throw Exception('模拟图片处理失败');
    }

    processedImages.add(image);
    processedParams.add({
      'maxHeight': maxHeight,
      'maxWidth': maxWidth,
      'quality': quality,
    });

    return image;
  }

  void reset() {
    shouldFail = false;
    processedImages.clear();
    processedParams.clear();
  }
}
