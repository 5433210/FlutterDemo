import 'dart:io';

import '../../presentation/models/work_filter.dart';
import '../entities/work.dart';

abstract class IWorkService {
  Future<void> deleteWork(String workId);
  Future<List<Work>> getAllWorks();
  Future<Work?> getWork(String id);
  Future<String?> getWorkThumbnail(String workId);
  Future<void> importWork(List<File> files, Work work);
  Future<List<Work>> queryWorks({
    String? searchQuery,
    WorkFilter? filter,
    SortOption? sortOption, // 保持接口一致性
  });
}
