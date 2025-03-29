import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/character/detected_outline.dart';
import './image_processor.dart';

class DefaultImageProcessor implements ImageProcessor {
  late final String _tempPath;
  late final String _thumbnailPath;

  DefaultImageProcessor() {
    _initPaths();
  }

  @override
  String get tempPath => _tempPath;

  @override
  String get thumbnailCachePath => _thumbnailPath;

  @override
  Future<Uint8List> applyEraseMask(
    Uint8List image,
    List<List<Offset>> erasePaths,
    double brushSize,
  ) async {
    final source = img.decodeImage(image);
    if (source == null) throw Exception('Failed to decode image');

    final result =
        img.copyResize(source, width: source.width, height: source.height);
    final brushRadius = brushSize / 2;
    final white = img.ColorRgb8(255, 255, 255);

    for (final path in erasePaths) {
      for (final point in path) {
        final x = point.dx.clamp(0, source.width - 1).toInt();
        final y = point.dy.clamp(0, source.height - 1).toInt();

        for (var dy = -brushRadius; dy <= brushRadius; dy++) {
          for (var dx = -brushRadius; dx <= brushRadius; dx++) {
            if (dx * dx + dy * dy <= brushRadius * brushRadius) {
              final px = (x + dx).round();
              final py = (y + dy).round();
              if (px >= 0 &&
                  px < result.width &&
                  py >= 0 &&
                  py < result.height) {
                result.setPixel(px, py, white);
              }
            }
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  @override
  Future<Uint8List> binarizeImage(
    Uint8List image,
    double threshold,
    bool inverted,
  ) async {
    final source = img.decodeImage(image);
    if (source == null) throw Exception('Failed to decode image');

    final gray = img.grayscale(source);
    final thresholdValue = threshold.toInt().clamp(0, 255);

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
        gray.setPixel(
          x,
          y,
          luminance > thresholdValue
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0),
        );
      }
    }

    final result = inverted ? img.invert(gray) : gray;
    return Uint8List.fromList(img.encodePng(result));
  }

  @override
  Future<void> cleanupTempFiles() async {
    final tempDir = Directory(_tempPath);
    final thumbDir = Directory(_thumbnailPath);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await thumbDir.exists()) await thumbDir.delete(recursive: true);
    await _initPaths();
  }

  @override
  Future<File> createPlaceholder(int width, int height) async {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final data = img.encodePng(image);
    final file = File(path.join(_tempPath, 'placeholder_${width}x$height.png'));
    await file.writeAsBytes(data);
    return file;
  }

  @override
  Future<String> createSvgOutline(DetectedOutline outline) async {
    final width = outline.boundingRect.width;
    final height = outline.boundingRect.height;
    final svg = StringBuffer()
      ..write(
          '<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">');

    for (final contour in outline.contourPoints) {
      if (contour.isEmpty) continue;
      svg.write('<path d="M${contour[0].dx},${contour[0].dy} ');
      for (int i = 1; i < contour.length; i++) {
        svg.write('L${contour[i].dx},${contour[i].dy} ');
      }
      svg.write('" stroke="black" fill="none" />');
    }

    svg.write('</svg>');
    return svg.toString();
  }

  @override
  Future<File> createTempFile(String prefix) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File(path.join(_tempPath, '${prefix}_$timestamp.tmp'));
  }

  @override
  Future<Uint8List> createThumbnail(Uint8List image, int maxSize) async {
    final source = img.decodeImage(image);
    if (source == null) throw Exception('Failed to decode image');

    final ratio = maxSize / math.max(source.width, source.height);
    final thumbnail = img.copyResize(
      source,
      width: (source.width * ratio).round(),
      height: (source.height * ratio).round(),
      interpolation: img.Interpolation.cubic,
    );

    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
  }

  @override
  Future<Uint8List> cropImage(Uint8List sourceImage, Rect region) async {
    final source = img.decodeImage(sourceImage);
    if (source == null) throw Exception('Failed to decode image');

    final cropped = img.copyCrop(
      source,
      x: region.left.toInt().clamp(0, source.width - 1),
      y: region.top.toInt().clamp(0, source.height - 1),
      width: region.width.toInt().clamp(1, source.width),
      height: region.height.toInt().clamp(1, source.height),
    );

    return Uint8List.fromList(img.encodePng(cropped));
  }

  @override
  Future<Uint8List> denoiseImage(
    Uint8List binaryImage,
    double noiseReduction,
  ) async {
    final source = img.decodeImage(binaryImage);
    if (source == null) throw Exception('Failed to decode image');

    var kernelSize = (noiseReduction * 3).toInt().clamp(1, 9);
    if (kernelSize % 2 == 0) kernelSize++;
    final processed = img.gaussianBlur(source, radius: kernelSize ~/ 2);

    return Uint8List.fromList(img.encodePng(processed));
  }

  @override
  Future<DetectedOutline> detectOutline(Uint8List binaryImage) async {
    final image = img.decodeImage(binaryImage);
    if (image == null) throw Exception('Failed to decode image');

    // Simple bounding box outline
    return DetectedOutline(
      boundingRect: Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      contourPoints: [
        [
          const Offset(0, 0),
          Offset(image.width.toDouble(), 0),
          Offset(image.width.toDouble(), image.height.toDouble()),
          Offset(0, image.height.toDouble()),
          const Offset(0, 0),
        ]
      ],
    );
  }

  @override
  Future<File> optimizeImage(File input) async {
    final bytes = await input.readAsBytes();
    final image = img.decodeImage(bytes);
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
    final bytes = await input.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final ratio = math.min(
      maxWidth / image.width,
      maxHeight / image.height,
    );

    final processed = ratio < 1
        ? img.copyResize(
            image,
            width: (image.width * ratio).round(),
            height: (image.height * ratio).round(),
            interpolation: img.Interpolation.cubic,
          )
        : image;

    final outputBytes = img.encodeJpg(processed, quality: quality);
    final output = await createTempFile('processed');
    await output.writeAsBytes(outputBytes);
    return output;
  }

  @override
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  }) async {
    final bytes = await input.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.cubic,
    );

    final output = await createTempFile('resized');
    await output.writeAsBytes(img.encodePng(resized));
    return output;
  }

  @override
  Future<File> rotateImage(File input, int degrees) async {
    final bytes = await input.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final rotated = img.copyRotate(image, angle: degrees);
    final output = await createTempFile('rotated');
    await output.writeAsBytes(img.encodePng(rotated));
    return output;
  }

  @override
  Future<bool> validateImageData(Uint8List data) async {
    try {
      final image = img.decodeImage(data);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initPaths() async {
    final tempDir = await getTemporaryDirectory();
    _tempPath = path.join(tempDir.path, 'image_processing');
    _thumbnailPath = path.join(tempDir.path, 'thumbnails');

    await Directory(_tempPath).create(recursive: true);
    await Directory(_thumbnailPath).create(recursive: true);
  }
}
