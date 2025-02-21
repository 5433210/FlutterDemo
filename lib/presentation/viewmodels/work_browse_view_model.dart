import 'dart:io';

import 'package:demo/domain/entities/work.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/work_service.dart';
import '../../infrastructure/config/storage_paths.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final WorkService _workService;
  final StoragePaths _paths;

  WorkBrowseViewModel(this._workService, this._paths) 
      : super(const WorkBrowseState());

  Future<void> loadWorks() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final works = await _workService.getWorks(
        query: state.searchQuery,
        filter: state.filter,
      );
      _sortWorks(works);
      state = state.copyWith(works: works, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateSearch(String? query) {
    state = state.copyWith(searchQuery: query);
    loadWorks();
  }

  void updateFilter(WorkFilter filter) {
    state = state.copyWith(filter: filter);
    loadWorks();
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortOption: option);
    _sortWorks(state.works);
  }

  Future<void> deleteWork(String workId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Delete work and related data
      await _workService.deleteWork(workId);

      // Remove from local state
      final updatedWorks = state.works.where((w) => w.id != workId).toList();
      
      state = state.copyWith(
        works: updatedWorks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '删除失败: ${e.toString()}',
      );
      // Re-throw to let UI handle error display
      rethrow;
    }
  }

  void _sortWorks(List<Work> works) {
    final sortOption = state.sortOption;

    // Create a mutable copy of the list
    final List<Work> mutableWorks = List.from(works);

    mutableWorks.sort((a, b) {
      int comparison;
      switch (sortOption.field) {
        case SortField.name:
          comparison = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case SortField.author:
          comparison = (a.author ?? '').compareTo(b.author ?? '');
          break;
        case SortField.createTime:
          comparison = (a.creationDate ?? DateTime(1900)).compareTo(b.creationDate ?? DateTime(1900));
          break;
        case SortField.updateTime:
          comparison = (a.updateTime ??DateTime(1900) ).compareTo(b.updateTime ?? DateTime(1900));
          break;
      }
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
    state = state.copyWith(works: mutableWorks);
  }

  Future<String?> getWorkThumbnail(String workId) async {
    try {
      final thumbnailPath = _paths.getWorkThumbnailPath(workId);
      final file = File(thumbnailPath);
      
      if (await file.exists()) {
        return thumbnailPath;
      }
      
      debugPrint('Thumbnail not found: $thumbnailPath');
      return null;
    } catch (e) {
      debugPrint('Error getting thumbnail: $e');
      return null;
    }
  }
}