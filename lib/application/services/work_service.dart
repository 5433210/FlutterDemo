import 'dart:io';

import 'package:demo/domain/interfaces/i_work_service.dart';

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
  Future<void> importWork(List<File> files, WorkInfo data) async {
    Work? work;

    // Create work info first
    work = Work(
      name: data.name,
      author: data.author,
      style: data.style?.name,
      tool: data.tool?.name,
      creationDate: data.creationDate,
      imageCount: files.length, // Initial count
    );

    // Insert work into database within transaction
    final workId = await _workRepository.insertWork(work);

    data.id = workId;

    // Create work directory
    await _paths.ensureDirectoryExists(_paths.getWorkPath(workId));

    // Process images
    await _imageService.processWorkImages(
      workId,
      files,
    );
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
    SortOption? sortOption, // 保留参数但不使用它
  }) async {
    // 构建查询参数
    final queryParams = <String, dynamic>{};

    // 添加搜索条件
    if (searchQuery?.isNotEmpty ?? false) {
      queryParams['search'] = searchQuery;
    }

    // 添加筛选和排序条件
    if (filter != null) {
      queryParams.addAll(filter.toQueryParams());
    }

    // 执行查询
    final works = await _workRepository.getWorks();
    return works.map((workData) => Work.fromMap(workData)).toList();
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
    final thumbnailPath = _paths.getWorkThumbnailPath(workId);
    final file = File(thumbnailPath);
    if (await file.exists()) {
      return thumbnailPath;
    }
    return null;
  }
}
