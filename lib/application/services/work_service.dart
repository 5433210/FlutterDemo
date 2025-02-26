import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../presentation/models/work_filter.dart';
import '../../utils/path_helper.dart';
import 'image_service.dart';

class WorkService {
  final WorkRepository _workRepository;
  final ImageService _imageService;

  WorkService(this._workRepository, this._imageService);

  Future<void> deleteWork(String workId) async {
    try {
      AppLogger.info('Deleting work',
          tag: 'WorkService', data: {'workId': workId});
      await _workRepository.deleteWork(workId);
      AppLogger.info('Work deleted successfully',
          tag: 'WorkService', data: {'workId': workId});
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete work',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
      rethrow;
    }
  }

  Future<List<Work>> getAllWorks() async {
    try {
      AppLogger.debug('Fetching all works', tag: 'WorkService');
      final works = await _workRepository.getWorks();
      AppLogger.debug('Fetched all works successfully', tag: 'WorkService');
      return works.map((workData) => Work.fromMap(workData)).toList();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to fetch all works',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<Work?> getWork(String id) async {
    try {
      AppLogger.debug('Fetching work details',
          tag: 'WorkService', data: {'workId': id});
      final work = await _workRepository.getWork(id);
      AppLogger.debug('Fetched work details successfully',
          tag: 'WorkService', data: {'workId': id});
      return work;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get work',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
        data: {'workId': id},
      );
      rethrow;
    }
  }

  Future<String?> getWorkThumbnail(String workId) async {
    try {
      AppLogger.debug('Fetching work thumbnail',
          tag: 'WorkService', data: {'workId': workId});

      final thumbnailPath = await PathHelper.getWorkCoverThumbnailPath(workId);

      // 检查缩略图是否存在
      final file = File(thumbnailPath);
      if (await file.exists()) {
        AppLogger.debug('Found thumbnail at: $thumbnailPath',
            tag: 'WorkService', data: {'workId': workId});

        // 检查文件是否为空或者无效
        if (await file.length() == 0) {
          AppLogger.warning('Thumbnail exists but is empty',
              tag: 'WorkService', data: {'workId': workId});

          // 创建占位图替代空文件
          await PathHelper.createPlaceholderImage(thumbnailPath);
        }

        return thumbnailPath;
      } else {
        AppLogger.debug('Thumbnail not found at: $thumbnailPath',
            tag: 'WorkService', data: {'workId': workId});

        // 如果文件不存在，但目录结构存在，创建一个占位图
        if (Directory(path.dirname(thumbnailPath)).existsSync()) {
          await PathHelper.createPlaceholderImage(thumbnailPath);
          AppLogger.debug('Created placeholder thumbnail',
              tag: 'WorkService', data: {'workId': workId});
          return thumbnailPath;
        }

        return null;
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error getting thumbnail',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
      return null;
    }
  }

  Future<void> importWork(List<File> files, Work data) async {
    try {
      AppLogger.info('Importing work',
          tag: 'WorkService', data: {'work': data});
      Work? work;

      // Create work info first
      work = Work(
        name: data.name,
        author: data.author,
        style: data.style,
        tool: data.tool,
        creationDate: data.creationDate,
        imageCount: files.length, // Initial count
      );

      // Insert work into database within transaction
      final workId = await _workRepository.insertWork(work);

      data = Work(
        id: workId,
        name: data.name,
        author: data.author,
        style: data.style,
        tool: data.tool,
        creationDate: data.creationDate,
        imageCount: files.length,
      );

      // 确保工作目录结构存在
      await PathHelper.ensureWorkDirectoryExists(workId);

      // Process images
      await _imageService.processWorkImages(
        workId,
        files,
      );

      AppLogger.info('Imported work successfully',
          tag: 'WorkService', data: {'workId': workId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Import failed in service',
        tag: 'WorkService',
        error: e,
        stackTrace: stackTrace,
        data: {'work': data},
      );
      rethrow;
    }
  }

  Future<List<Work>> queryWorks({
    String? searchQuery,
    WorkFilter? filter,
    SortOption? sortOption,
  }) async {
    try {
      AppLogger.debug('Querying works', tag: 'WorkService', data: {
        'searchQuery': searchQuery,
        'filter': filter,
        'sortOption': sortOption,
      });
      final List<Map<String, dynamic>> results = await _workRepository.getWorks(
        query: searchQuery?.trim(),
        style: filter?.style?.value,
        tool: filter?.tool?.value,
        creationDateRange: filter?.dateRange != null
            ? DateTimeRange(
                start: filter!.dateRange!.start,
                end: filter.dateRange!.end,
              )
            : null,
        // 确保使用正确的列名
        orderBy: _mapSortFieldToColumnName(filter?.sortOption.field),
        descending: filter?.sortOption.descending ?? true,
      );

      AppLogger.debug('Queried works successfully', tag: 'WorkService');
      return results
          .map((data) => Work.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'Query works failed',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
        data: {
          'searchQuery': searchQuery,
          'filter': filter,
          'sortOption': sortOption,
        },
      );
      rethrow;
    }
  }

  // 添加排序字段映射方法
  String? _mapSortFieldToColumnName(SortField? field) {
    if (field == null) return null;

    return switch (field) {
      SortField.name => 'name',
      SortField.author => 'author',
      SortField.creationDate => 'creationDate',
      SortField.importDate => 'createTime',
      SortField.updateDate => 'updateTime',
      SortField.none => null,
    };
  }
}
