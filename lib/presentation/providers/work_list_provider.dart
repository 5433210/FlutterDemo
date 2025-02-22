import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../models/work_filter.dart';
import 'work_filter_provider.dart';

final workListProvider = FutureProvider.autoDispose<List<Work>>((ref) async {
  final filter = ref.watch(workFilterProvider);
  
  // 获取作品列表
  final worksData = await ref.read(workRepositoryProvider).getWorks();
  final works = worksData.map((data) => Work.fromJson(data)).toList();
  
  // 应用筛选
  var filteredWorks = works.where((work) {
    if (work.style != filter.selectedStyle) {
      return false;
    }
    if (work.tool != filter.selectedTool) {
      return false;
    }
    // ...更多筛选条件
    return true;
  }).toList();

  // 应用排序
  if (!filter.sortOption.isEmpty) {
    filteredWorks.sort((a, b) {
      int compare;
      switch (filter.sortOption.field) {
        case SortField.name:
          compare = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case SortField.author:
          compare = (a.author ?? '').compareTo(b.author ?? '');
          break;
        case SortField.creationDate:
          compare = (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0));
          break;
        case SortField.importDate:
          compare = (a.createTime ?? DateTime(0)).compareTo(b.createTime ?? DateTime(0));
          break;
        default:
          return 0;
      }
      return filter.sortOption.descending ? -compare : compare;
    });
  }

  return filteredWorks;
});
