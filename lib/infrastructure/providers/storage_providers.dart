import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/work_image_storage_interface.dart';
import '../storage/local_work_image_storage.dart';

/// 图片存储服务提供者
final workImageStorageProvider = Provider<IWorkImageStorage>((ref) {
  return LocalWorkImageStorage();
});
