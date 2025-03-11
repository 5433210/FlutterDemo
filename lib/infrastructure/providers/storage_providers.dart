import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/work_image_storage_interface.dart';
import '../storage/local_storage_impl.dart';
import '../storage/local_work_image_storage.dart';
import '../storage/storage_interface.dart';

/// 基础存储服务提供者
final storageProvider = Provider<IStorage>((ref) {
  return LocalStorageImpl();
});

/// Work图片存储服务提供者
final workImageStorageProvider = Provider<IWorkImageStorage>((ref) {
  final storage = ref.watch(storageProvider);
  return LocalWorkImageStorage(storage);
});
