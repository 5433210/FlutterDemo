import 'dart:convert';
import 'dart:io';

import 'package:demo/domain/value_objects/work/work_entity.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/work.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/value_objects/work/work_collected_char.dart';
import '../../domain/value_objects/work/work_image.dart';
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

  Future<WorkEntity?> getWorkEntity(String id) async {
    try {
      AppLogger.debug('Fetching work entity details',
          tag: 'WorkService', data: {'workId': id});

      // 1. 从数据库获取作品基本信息
      final work = await _workRepository.getWork(id);
      if (work == null) {
        AppLogger.warning('Work not found',
            tag: 'WorkService', data: {'workId': id});
        return null;
      }

      // 2. 获取该作品关联的所有字符
      final characters = await _workRepository.getCharactersByWorkId(id);

      // 3. 获取作品所有图片信息
      final images = await _loadWorkImages(id);

      // 4. 构建并返回 WorkEntity 对象
      return _buildWorkEntity(
          work.toMap(), characters.map((c) => c.toMap()).toList(), images);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get work entity',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
        data: {'workId': id},
      );
      return null;
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

      // Insert work into database within transaction
      final workId = await _workRepository.insertWork(data);

      data.id = workId;

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

  Future<void> updateWork(Work work) async {
    final workData = {
      'name': work.name,
      'author': work.author,
      'style': work.style,
      'tool': work.tool,
      'creationDate': work.creationDate?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'remark': work.remark,
    };
  }

  /// 构建 WorkEntity 对象
  WorkEntity _buildWorkEntity(Map<String, dynamic> workMap,
      List<Map<String, dynamic>> characters, List<WorkImage> images) {
    // 解析枚举值
    WorkStyle? style;
    if (workMap['style'] != null) {
      style = WorkStyle.values.firstWhere(
        (s) => s.value == workMap['style'],
        orElse: () => WorkStyle.regular,
      );
    }

    WorkTool? tool;
    if (workMap['tool'] != null) {
      tool = WorkTool.values.firstWhere(
        (t) => t.value == workMap['tool'],
        orElse: () => WorkTool.brush,
      );
    }

    // 解析元数据和标签
    WorkMetadata? metadata;
    if (workMap['metadata'] != null) {
      dynamic metadataValue = workMap['metadata'];
      Map<String, dynamic> metadataMap;

      if (metadataValue is String) {
        try {
          metadataMap = jsonDecode(metadataValue);
          List<String> tags = [];
          if (metadataMap.containsKey('tags') && metadataMap['tags'] is List) {
            tags = List<String>.from(metadataMap['tags']);
          }
          metadata = WorkMetadata(tags: tags);
        } catch (e) {
          AppLogger.warning('Failed to parse metadata',
              tag: 'WorkService', error: e);
        }
      } else if (metadataValue is Map) {
        metadataMap = Map<String, dynamic>.from(metadataValue);
        List<String> tags = [];
        if (metadataMap.containsKey('tags') && metadataMap['tags'] is List) {
          tags = List<String>.from(metadataMap['tags']);
        }
        metadata = WorkMetadata(tags: tags);
      }
    }

    // 处理日期字段
    DateTime? createTime, updateTime, creationDate;
    if (workMap['createTime'] != null) {
      createTime = _parseDateTime(workMap['createTime']);
    }

    if (workMap['updateTime'] != null) {
      updateTime = _parseDateTime(workMap['updateTime']);
    }

    if (workMap['creationDate'] != null) {
      creationDate = _parseDateTime(workMap['creationDate']);
    }

    // 构建收集的字符列表
    List<WorkCollectedChar> collectedChars = [];
    for (var charMap in characters) {
      try {
        // 解析区域信息
        Map<String, dynamic> regionData = {};
        if (charMap['sourceRegion'] != null) {
          if (charMap['sourceRegion'] is String) {
            regionData = jsonDecode(charMap['sourceRegion']);
          } else if (charMap['sourceRegion'] is Map) {
            regionData = Map<String, dynamic>.from(charMap['sourceRegion']);
          }
        }

        // 创建字符对象
        collectedChars.add(
          WorkCollectedChar(
            id: charMap['id'],
            createTime: _parseDateTime(charMap['createTime']) ?? DateTime.now(),
            region: SourceRegion(
              index: regionData['index'] ?? 0,
              x: (regionData['x'] ?? 0).toDouble(),
              y: (regionData['y'] ?? 0).toDouble(),
              width: (regionData['width'] ?? 0).toDouble(),
              height: (regionData['height'] ?? 0).toDouble(),
            ),
          ),
        );
      } catch (e) {
        AppLogger.warning('Failed to parse character data',
            tag: 'WorkService', error: e);
      }
    }

    // 创建并返回完整的 WorkEntity
    return WorkEntity(
      id: workMap['id'],
      name: workMap['name'] ?? '',
      author: workMap['author'],
      style: style,
      tool: tool,
      imageCount: workMap['imageCount'] ?? images.length,
      creationDate: creationDate,
      remark: workMap['remark'],
      createTime: createTime,
      updateTime: updateTime,
      images: images,
      collectedChars: collectedChars,
      metadata: metadata,
    );
  }

  /// 查找带有特定前缀的文件
  Future<File?> _findFileWithPrefix(Directory dir, String prefix) async {
    try {
      final files = await dir
          .list()
          .where((e) => e is File && path.basename(e.path).startsWith(prefix))
          .toList();

      if (files.isNotEmpty) {
        return files.first as File;
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to find file with prefix',
        tag: 'WorkService',
        error: e,
        data: {'directory': dir.path, 'prefix': prefix},
      );
    }
    return null;
  }

  /// 获取图片文件信息
  Future<ImageDetail?> _getImageFileInfo(File file) async {
    try {
      final fileStat = await file.stat();

      // 获取图片尺寸
      int width = 0;
      int height = 0;

      try {
        final bytes = await file.readAsBytes();
        final image = await decodeImageFromList(bytes);
        width = image.width;
        height = image.height;
      } catch (e) {
        AppLogger.warning(
          'Failed to decode image dimensions',
          tag: 'WorkService',
          error: e,
          data: {'path': file.path},
        );
      }

      return ImageDetail(
        path: file.path,
        width: width,
        height: height,
        format: path.extension(file.path).replaceFirst('.', ''),
        size: fileStat.size,
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to get image file info',
        tag: 'WorkService',
        error: e,
        data: {'path': file.path},
      );
    }
    return null;
  }

  /// 加载作品图片信息
  Future<List<WorkImage>> _loadWorkImages(String workId) async {
    final images = <WorkImage>[];

    try {
      final workDir = await PathHelper.getWorkPath(workId);
      final picturesDir = Directory(path.join(workDir, 'pictures'));

      if (!await picturesDir.exists()) {
        return images;
      }

      // 获取所有图片目录
      final List<FileSystemEntity> entities = await picturesDir.list().toList();
      final List<Directory> indexDirs = [];

      for (var entity in entities) {
        if (entity is Directory) {
          indexDirs.add(entity);
        }
      }

      // 按索引排序
      indexDirs.sort((a, b) {
        final indexA = int.tryParse(path.basename(a.path)) ?? 0;
        final indexB = int.tryParse(path.basename(b.path)) ?? 0;
        return indexA.compareTo(indexB);
      });

      // 处理每个索引目录中的图片
      for (int i = 0; i < indexDirs.length; i++) {
        final indexDir = indexDirs[i];
        final index = int.tryParse(path.basename(indexDir.path)) ?? i;

        // 找原始图片
        final originalFile = await _findFileWithPrefix(indexDir, 'original');
        final originalInfo =
            originalFile != null ? await _getImageFileInfo(originalFile) : null;

        // 找导入图片
        final importedFile = await _findFileWithPrefix(indexDir, 'imported');
        final importedInfo =
            importedFile != null ? await _getImageFileInfo(importedFile) : null;

        // 找缩略图
        final thumbnailFile = await _findFileWithPrefix(indexDir, 'thumbnail');
        final thumbnailInfo = thumbnailFile != null
            ? await _getImageFileInfo(thumbnailFile)
            : null;

        // 将 ImageDetail 转换为 ImageThumbnail
        final thumbnailData = thumbnailInfo != null
            ? ImageThumbnail(
                path: thumbnailInfo.path,
                width: thumbnailInfo.width,
                height: thumbnailInfo.height)
            : null;

        // 只有至少有原图或导入图时才添加
        if (originalInfo != null || importedInfo != null) {
          images.add(WorkImage(
            index: index,
            original: originalInfo,
            imported: importedInfo,
            thumbnail: thumbnailData,
          ));
        }
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load work images',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
    }

    return images;
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

  /// 解析日期时间
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to parse date time',
        tag: 'WorkService',
        error: e,
        data: {'value': value},
      );
    }
    return null;
  }
}
