import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/work.dart';
import '../../domain/interfaces/i_work_service.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/config/storage_paths.dart';
import '../../infrastructure/logging/logger.dart';
import '../../presentation/models/work_filter.dart';
import 'image_service.dart';

class WorkService implements IWorkService {
  final WorkRepository _workRepository;
  final ImageService _imageService;
  final StoragePaths _paths;

  WorkService(this._workRepository, this._imageService, this._paths);

  @override
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

  @override
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

  @override
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

  @override
  Future<String?> getWorkThumbnail(String workId) async {
    try {
      AppLogger.debug('Fetching work thumbnail',
          tag: 'WorkService', data: {'workId': workId});
      final thumbnailPath = _paths.getWorkThumbnailPath(workId);
      final file = File(thumbnailPath);

      // 确保目录存在
      final directory = Directory(path.dirname(thumbnailPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      if (await file.exists()) {
        AppLogger.debug('Found thumbnail at: $thumbnailPath',
            tag: 'WorkService', data: {'workId': workId});
        return thumbnailPath;
      } else {
        AppLogger.debug('Thumbnail not found at: $thumbnailPath',
            tag: 'WorkService', data: {'workId': workId});
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

  @override
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

      // Create work directory
      await _paths.ensureDirectoryExists(_paths.getWorkPath(workId));

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

  @override
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
