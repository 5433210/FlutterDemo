import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/value_objects/work/work_info.dart';
import '../../infrastructure/config/storage_paths.dart';
import '../../presentation/viewmodels/states/work_browse_state.dart';
import 'image_service.dart';

class WorkService {
  final WorkRepository _repository;
  final ImageService _imageService;
  final StoragePaths _paths;

  WorkService(this._repository, this._imageService, this._paths);

  Future<void> importWork(List<File> files, WorkInfo data) async {    
    Work? work;

    // Begin transaction
    return await _repository.transaction((tx) async {
      try {
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
        final workId = await tx.insertWork(work!.toMap());

        data.id = workId;

        // Create work directory
        await _paths.ensureDirectoryExists(_paths.getWorkPath(workId));

        // Process images
        await _imageService.processWorkImages(
          workId, 
          files,
        );
      } catch (e) {
        // If anything fails, the transaction will be rolled back automatically
        // Clean up any created directories
        if (work != null) {
          final workDir = _paths.getWorkPath(data.id!);
          if (await Directory(workDir).exists()) {
            await Directory(workDir).delete(recursive: true);
          }
        }
        rethrow;
      }
    });
  }

  Future<List<Work>> getWorks({
    String? query,
    WorkFilter? filter,
    SortField? sortField,
    SortOrder? sortOrder,
  }) async {
    // Convert sort field to column name
    String? orderBy;
    if (sortField != null) {
      orderBy = switch (sortField) {
        SortField.name => 'name',
        SortField.author => 'author',
        SortField.createTime => 'creation_date',
        SortField.updateTime => 'update_time',
      };
    }

    final works = await _repository.getWorks(
      query: query,
      styles: filter?.styles,
      tools: filter?.tools,
      dateRange: filter?.dateRange,
      orderBy: orderBy,
      descending: sortOrder == SortOrder.descending,
    );

    return works.map((map) => Work.fromMap(map)).toList();
  }

  Future<void> deleteWork(String workId) async {
    await _repository.deleteWork(workId);
  }

  Future<void> createWork(Map<String, dynamic> work) async {
    await _repository.insertWork(Work.fromMap(work));
  }
}
