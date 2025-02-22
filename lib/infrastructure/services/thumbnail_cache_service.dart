import 'dart:io';
import 'package:riverpod/riverpod.dart';

import '../../utils/path_helper.dart';


class ThumbnailCacheService extends StateNotifier<Map<String, String>> {
  ThumbnailCacheService() : super({});

  Future<String?> getThumbnailPath(String workId) async {
    if (state.containsKey(workId)) {
      return state[workId];
    }

    final path = await PathHelper.getWorkThumbnailPath(workId);
    if (File(path).existsSync()) {
      state = {...state, workId: path};
      return path;
    }
    return null;
  }

  void clearCache() {
    state = {};
  }
}

final thumbnailCacheProvider = StateNotifierProvider<ThumbnailCacheService, Map<String, String>>((ref) {
  return ThumbnailCacheService();
});