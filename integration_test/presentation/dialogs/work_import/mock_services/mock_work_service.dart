import 'dart:io';

import 'package:demo/application/services/work/work_service.dart';
import 'package:demo/domain/models/work/work_entity.dart';

class MockWorkService implements WorkService {
  bool shouldFail = false;
  final importedWorks = <WorkEntity>[];
  final importedImages = <List<File>>[];

  @override
  Future<WorkEntity> importWork(List<File> images, WorkEntity work) async {
    if (shouldFail) {
      throw Exception('模拟导入失败');
    }
    importedWorks.add(work);
    importedImages.add(List.from(images));

    // 记录操作但返回原始实体
    return work;
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }

  void reset() {
    shouldFail = false;
    importedWorks.clear();
    importedImages.clear();
  }
}
