import 'package:demo/application/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/storage_paths.dart';
import 'package:path/path.dart' as path;

/// Application storage paths provider
final storagePathsProvider = Provider<StoragePaths>((ref)  {
  final basePath = path.join(AppConfig.dataPath, 'storage');
  return StoragePaths(basePath);
});