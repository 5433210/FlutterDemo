import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../domain/value_objects/image/image_info.dart';
import '../../domain/value_objects/image/image_size.dart';
import '../config/app_config.dart';

class ImageService {
  final String _basePath;
  
  ImageService({required String basePath}) : _basePath = basePath;

  Future<List<ImageInfo>> processWorkImages(
    List<File> images, {
    bool optimize = true,
    bool keepOriginals = true,
  }) async {
    final processedImages = <ImageInfo>[];

    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('无法解码图片：${path.basename(file.path)}');
      }

      final id = const Uuid().v4();
      final ext = path.extension(file.path).toLowerCase();
      
      // Create directory structure
      final workImagesDir = path.join(_basePath, 'works', id);
      await Directory(workImagesDir).create(recursive: true);

      ImageInfo imageInfo;
      if (optimize) {
        // Process and save optimized version
        final processed = _processImage(image);
        final optimizedPath = path.join(workImagesDir, 'optimized$ext');
        await File(optimizedPath).writeAsBytes(
          ext == '.png' ? img.encodePng(processed) : img.encodeJpg(processed, quality: 85)
        );

        // Create thumbnail
        final thumbnail = _createThumbnail(processed);
        final thumbnailPath = path.join(workImagesDir, 'thumbnail.jpg');
        await File(thumbnailPath).writeAsBytes(img.encodeJpg(thumbnail, quality: 80));

        // Save original if requested
        final String? originalPath;
        if (keepOriginals) {
          originalPath = path.join(workImagesDir, 'original$ext');
          await file.copy(originalPath);
        } else {
          originalPath = null;
        }

        imageInfo = ImageInfo(
          id: id,
          path: optimizedPath,
          size: ImageSize(width: processed.width, height: processed.height),
          fileSize: await File(optimizedPath).length(),
          format: ext.replaceAll('.', ''),
          thumbnail: thumbnailPath,
          original: keepOriginals ? originalPath : null
        );
      } else {
        // Use original file directly
        final imagePath = path.join(workImagesDir, 'image$ext');
        await file.copy(imagePath);

        // Still create thumbnail
        final thumbnail = _createThumbnail(image);
        final thumbnailPath = path.join(workImagesDir, 'thumbnail.jpg');
        await File(thumbnailPath).writeAsBytes(img.encodeJpg(thumbnail, quality: 80));

        imageInfo = ImageInfo(
          id: id,
          path: imagePath,
          size: ImageSize(width: image.width, height: image.height),
          fileSize: await File(imagePath).length(),
          format: ext.replaceAll('.', ''),
          thumbnail: thumbnailPath,
        );
      }

      processedImages.add(imageInfo);
    }

    return processedImages;
  }

  img.Image _processImage(img.Image image) {
    // Resize if needed
    if (image.width > AppConfig.maxImageWidth || 
        image.height > AppConfig.maxImageHeight) {
      final aspectRatio = image.width / image.height;
      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > AppConfig.maxImageWidth) {
        newWidth = AppConfig.maxImageWidth;
        newHeight = (AppConfig.maxImageWidth / aspectRatio).round();
      }

      if (newHeight > AppConfig.maxImageHeight) {
        newHeight = AppConfig.maxImageHeight;
        newWidth = (AppConfig.maxImageHeight * aspectRatio).round();
      }

      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    return image;
  }

  img.Image _createThumbnail(img.Image image) {
    final aspectRatio = image.width / image.height;
    int thumbWidth = AppConfig.thumbnailSize;
    int thumbHeight = AppConfig.thumbnailSize;

    if (aspectRatio > 1) {
      thumbHeight = (AppConfig.thumbnailSize / aspectRatio).round();
    } else {
      thumbWidth = (AppConfig.thumbnailSize * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: thumbWidth,
      height: thumbHeight,
      interpolation: img.Interpolation.linear,
    );
  }
}