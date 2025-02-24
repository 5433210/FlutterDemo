import 'dart:io';

import 'package:demo/domain/interfaces/i_work_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/value_objects/work/work_info.dart';
import '../../infrastructure/config/storage_paths.dart';
import '../../presentation/models/work_filter.dart';
import 'image_service.dart';

class WorkService implements IWorkService {
  final WorkRepository _workRepository;
  final ImageService _imageService;
  final StoragePaths _paths;

  WorkService(this._workRepository, this._imageService, this._paths);

  @override
  Future<void> importWork(List<File> files, Work data) async {
    try {
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
    } catch (e,stackTrace) {
      debugPrint('Import failed in service: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<Work>> getAllWorks() async {
    final works = await _workRepository.getWorks();
    return works.map((workData) => Work.fromMap(workData)).toList();
  }

  @override
  Future<List<Work>> queryWorks({
    String? searchQuery,
    WorkFilter? filter,
    SortOption? sortOption,
  }) async {
    try {
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

      return results.map((data) => Work.fromMap(Map<String, dynamic>.from(data))).toList();
    } catch (e) {
      debugPrint('Query works failed: $e');
      rethrow;
    }
  }

  // 添加排序字段映射方法
  String? _mapSortFieldToColumnName(SortField? field) {
    if (field == null) return null;
    
    return switch(field) {
      SortField.name => 'name',
      SortField.author => 'author',
      SortField.creationDate => 'creationDate',
      SortField.importDate => 'createTime',
      SortField.updateDate => 'updateTime',
      SortField.none => null,
    };
  }

  @override
  Future<void> deleteWork(String workId) async {
    await _workRepository.deleteWork(workId);
  }

  @override
  Future<Work?> getWork(String id) async {
    return await _workRepository.getWork(id);
  }

  @override
  Future<String?> getWorkThumbnail(String workId) async {
    try {
      final thumbnailPath = _paths.getWorkThumbnailPath(workId);
      final file = File(thumbnailPath);
      
      // 确保目录存在
      final directory = Directory(path.dirname(thumbnailPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      if (await file.exists()) {
        debugPrint('Found thumbnail at: $thumbnailPath');
        return thumbnailPath;
      } else {
        debugPrint('Thumbnail not found at: $thumbnailPath');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting thumbnail: $e');
      return null;
    }
  }
}
