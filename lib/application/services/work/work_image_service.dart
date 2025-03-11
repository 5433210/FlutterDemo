import 'dart:io';

import '../../../domain/models/work/work_image.dart';
import '../../../domain/services/work_image_processing_interface.dart';
import '../../../domain/services/work_image_storage_interface.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/storage/storage_interface.dart';
import './service_errors.dart';

/// Work Image Service Implementation
class WorkImageService with WorkImageErrorHandler {
  final IStorage _storage;
  final IWorkImageStorage _workImageStorage;
  final IWorkImageProcessing _processor;

  WorkImageService({
    required IStorage storage,
    required IWorkImageStorage workImageStorage,
    required IWorkImageProcessing processor,
  })  : _storage = storage,
        _workImageStorage = workImageStorage,
        _processor = processor;

  /// Clean up all work images
  Future<void> cleanupWorkImages(String workId) async {
    return handleImageOperation(
      'cleanupWorkImages',
      () async {
        // Get all work images
        final images = await getWorkImages(workId);

        // Delete each image
        for (final imagePath in images) {
          await _workImageStorage.deleteWorkImage(workId, imagePath);

          AppLogger.debug(
            'Deleted work image',
            tag: 'WorkImageService',
            data: {'workId': workId, 'path': imagePath},
          );
        }
      },
      data: {'workId': workId},
    );
  }

  /// Create temporary file
  Future<String> createTempFile(List<int> bytes, String extension) async {
    return handleImageOperation(
      'createTempFile',
      () => _storage.saveTempFile(bytes),
      data: {'extension': extension},
    );
  }

  Future<File> createThumbnail(
    File image,
  ) async {
    return handleImageOperation(
      'generateWorkThumbnail',
      () => _processor.generateWorkThumbnail(image),
      data: {'path': image.path},
    );
  }

  /// Delete work image
  Future<void> deleteWorkImage(String workId, String imagePath) async {
    return handleImageOperation(
      'deleteWorkImage',
      () => _workImageStorage.deleteWorkImage(workId, imagePath),
      data: {'workId': workId, 'imagePath': imagePath},
    );
  }

  /// Get work images
  Future<List<String>> getWorkImages(String workId) async {
    return handleImageOperation(
      'getWorkImages',
      () => _workImageStorage.getWorkImages(workId),
      data: {'workId': workId},
    );
  }

  /// Optimize image with optional size constraints
  Future<File> optimizeImage(
    File image, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    return handleImageOperation(
      'optimizeImage',
      () async {
        File optimized = await _processor.optimize(image, quality);

        // Resize if needed
        if (maxWidth != null || maxHeight != null) {
          optimized = await _processor.resize(
            optimized,
            width: maxWidth ?? maxHeight ?? 1920,
            height: maxHeight ?? maxWidth ?? 1080,
          );
        }

        return optimized;
      },
      data: {
        'path': image.path,
        'quality': quality,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
      },
    );
  }

  /// Process work images in batches
  Future<List<WorkImage>> processImagesInBatches(
    String workId,
    List<File> files, {
    int batchSize = 3,
  }) async {
    return handleImageOperation(
      'processImagesInBatches',
      () async {
        final results = <WorkImage>[];

        // Process files in batches
        for (var i = 0; i < files.length; i += batchSize) {
          final end =
              (i + batchSize < files.length) ? i + batchSize : files.length;
          final batch = files.sublist(i, end);

          AppLogger.debug(
            'Processing batch ${(i ~/ batchSize) + 1}',
            tag: 'WorkImageService',
            data: {'workId': workId, 'batchSize': batch.length},
          );

          // Process batch
          final processedBatch =
              await _processor.processWorkImages(workId, batch);
          results.addAll(processedBatch);

          AppLogger.debug(
            'Batch processed',
            tag: 'WorkImageService',
            data: {
              'workId': workId,
              'processedCount': processedBatch.length,
            },
          );
        }

        return results;
      },
      data: {'workId': workId, 'fileCount': files.length},
    );
  }

  /// Rotate image
  Future<File> rotateImage(
    File image,
    int angle, {
    bool preserveSize = false,
  }) async {
    return handleImageOperation(
      'rotateImage',
      () => _processor.rotate(image, angle, preserveSize: preserveSize),
      data: {'path': image.path, 'angle': angle},
    );
  }

  /// Save work image
  Future<String> saveWorkImage(String workId, File image) async {
    return handleImageOperation(
      'saveWorkImage',
      () => _workImageStorage.saveWorkImage(workId, image),
      data: {'workId': workId, 'imagePath': image.path},
    );
  }
}
