import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import './image_processor.dart';

class LocalImageProcessor implements ImageProcessor {
  String? _tempPath;
  String? _thumbnailCachePath;

  @override
  String get tempPath {
    if (_tempPath == null) {
      throw StateError('Temp path not initialized');
    }
    return _tempPath!;
  }

  @override
  String get thumbnailCachePath {
    if (_thumbnailCachePath == null) {
      throw StateError('Thumbnail cache path not initialized');
    }
    return _thumbnailCachePath!;
  }

  @override
  Future<void> cleanupTempFiles() async {
    await Directory(tempPath).delete(recursive: true);
    await Directory(tempPath).create();
  }

  @override
  Future<File> createPlaceholder(int width, int height) async {
    final image = img.Image(width: width, height: height);
    final png = img.encodePng(image);
    final file = await createTempFile('placeholder');
    await file.writeAsBytes(png);
    return file;
  }

  @override
  Future<File> createTempFile(String prefix) async {
    return File(path.join(
        tempPath, '${prefix}_${DateTime.now().millisecondsSinceEpoch}.tmp'));
  }

  Future<void> initialize() async {
    final tempDir = await getTemporaryDirectory();
    _tempPath = path.join(tempDir.path, 'image_processing');
    _thumbnailCachePath = path.join(tempDir.path, 'thumbnails');

    await Directory(_tempPath!).create(recursive: true);
    await Directory(_thumbnailCachePath!).create(recursive: true);
  }

  @override
  Future<File> optimizeImage(File input) async {
    final image = img.decodeImage(await input.readAsBytes());
    if (image == null) throw Exception('Failed to decode image');

    final optimized = img.encodeJpg(image, quality: 85);
    final output = await createTempFile('optimized');
    await output.writeAsBytes(optimized);
    return output;
  }

  @override
  Future<File> processImage(
    File input, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    final image = img.decodeImage(await input.readAsBytes());
    if (image == null) throw Exception('Failed to decode image');

    final scaled = _scaleImage(image, maxWidth, maxHeight);
    final processed = img.encodeJpg(scaled, quality: quality);
    final output = await createTempFile('processed');
    await output.writeAsBytes(processed);
    return output;
  }

  @override
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  }) async {
    final image = img.decodeImage(await input.readAsBytes());
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(image, width: width, height: height);
    final processed = img.encodePng(resized);
    final output = await createTempFile('resized');
    await output.writeAsBytes(processed);
    return output;
  }

  @override
  Future<File> rotateImage(File input, int degrees) async {
    final image = img.decodeImage(await input.readAsBytes());
    if (image == null) throw Exception('Failed to decode image');

    final rotated = img.copyRotate(image, angle: degrees);
    final processed = img.encodePng(rotated);
    final output = await createTempFile('rotated');
    await output.writeAsBytes(processed);
    return output;
  }

  img.Image _scaleImage(img.Image image, int maxWidth, int maxHeight) {
    final ratio = image.width / image.height;
    int width = image.width;
    int height = image.height;

    if (width > maxWidth) {
      width = maxWidth;
      height = (width / ratio).round();
    }

    if (height > maxHeight) {
      height = maxHeight;
      width = (height * ratio).round();
    }

    return img.copyResize(image, width: width, height: height);
  }
}
