import 'dart:io';
import '../entities/work.dart';
import '../value_objects/work/work_info.dart';
import '../../presentation/models/work_filter.dart';

abstract class IWorkService {
  Future<List<Work>> getAllWorks();
  Future<Work?> getWork(String id);
  Future<String?> getWorkThumbnail(String workId);
  Future<void> deleteWork(String workId);
  Future<void> importWork(List<File> files, WorkInfo info);
  Future<List<Work>> queryWorks({
    String? searchQuery,
    WorkFilter? filter,
    SortOption? sortOption, // 保持接口一致性
  });
}
