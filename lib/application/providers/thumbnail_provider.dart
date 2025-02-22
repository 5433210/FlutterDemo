import 'package:riverpod/riverpod.dart';
import '../../utils/path_helper.dart';

final thumbnailProvider = FutureProvider.family<String?, String>((ref, workId) async {
  try {
    final path = await PathHelper.getWorkThumbnailPath(workId);
    return path;
  } catch (e) {
    return null;
  }
});