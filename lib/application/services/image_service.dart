import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import '../../domain/value_objects/image/image_info.dart';
import '../../domain/value_objects/image/image_size.dart';
import '../../infrastructure/config/storage_paths.dart';
import '../config/app_config.dart';

class ImageService {
  final StoragePaths _paths;

  ImageService(this._paths);

  Future<List<ImageInfo>> processWorkImages(
      String workId, List<File> images) async {
    final processedImages = <ImageInfo>[];

    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('无法解码图片：${path.basename(file.path)}');
      }

      // Create work picture directory
      final picturePath = _paths.getWorkPicturePath(workId, i);
      await _paths.ensureDirectoryExists(picturePath);

      // Save original if requested
      String? originalPath;

      originalPath = _paths.getWorkOriginalPicturePath(
          workId, i, path.extension(file.path));
      await file.copy(originalPath);

      // Process and save imported image
      final processed = _processImage(image);
      final importedPath = _paths.getWorkImportedPicturePath(workId, i);
      await File(importedPath).writeAsBytes(img.encodePng(processed));

      // Create thumbnail for this image
      final thumbnail = _createThumbnail(processed);
      final thumbnailPath = _paths.getWorkImportedThumbnailPath(workId, i);
      await File(thumbnailPath)
          .writeAsBytes(img.encodeJpg(thumbnail, quality: 80));

      // Add image info
      processedImages.add(ImageInfo(
          fileSize: bytes.length,
          format: path.extension(file.path).replaceAll('.', ''),
          path: importedPath,
          size: ImageSize(width: processed.width, height: processed.height),
          thumbnail: thumbnailPath,
          original: originalPath));
    }

    // Create work thumbnail if images exist
    if (processedImages.isNotEmpty) {
      final workThumbnail = _createThumbnail(
          img.decodeImage(await File(processedImages[0].path).readAsBytes())!);
      final workThumbnailPath = _paths.getWorkThumbnailPath(workId);
      await File(workThumbnailPath)
          .writeAsBytes(img.encodeJpg(workThumbnail, quality: 80));
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

  Future<File> rotateImage(File file, int angle) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片');

    // Rotate image
    image = img.copyRotate(image, angle: angle);

    // Create temp file with unique name
    final dir = path.dirname(file.path);
    final ext = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rotatedPath = path.join(dir, 'rotated_${timestamp}$ext');
    
    // Save rotated image
    final rotatedFile = File(rotatedPath);
    await rotatedFile.writeAsBytes(img.encodeJpg(image));
    
    // Delete original file if it's a temp file
    if (file.path.contains('temp_')) {
      await file.delete();
    }
    
    return rotatedFile;
  }

  Future<File> optimizeImage(
    File file, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片');

    // Calculate new dimensions maintaining aspect ratio
    double ratio = image.width / image.height;
    int newWidth = image.width;
    int newHeight = image.height;

    if (newWidth > maxWidth) {
      newWidth = maxWidth;
      newHeight = (newWidth / ratio).round();
    }

    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (newHeight * ratio).round();
    }

    // Resize if needed
    if (newWidth != image.width || newHeight != image.height) {
      image = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // Create optimized file
    final dir = path.dirname(file.path);
    final ext = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final optimizedPath = path.join(dir, 'optimized_${timestamp}$ext');
    
    // Save optimized image
    final optimizedFile = File(optimizedPath);
    await optimizedFile.writeAsBytes(img.encodeJpg(image, quality: quality));
    
    return optimizedFile;
  }

  Future<void> backupOriginal(File file) async {
    final backupDir = Directory(path.join(
      AppConfig.workspacePath,
      'originals',
    ));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = path.basename(file.path);
    final backupPath = path.join(backupDir.path, '${timestamp}_$filename');

    await file.copy(backupPath);
  }
}
