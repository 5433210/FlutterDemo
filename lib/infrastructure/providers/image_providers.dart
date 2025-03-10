import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/image_processing_interface.dart';
import '../../domain/services/work_image_processing_interface.dart';
import '../../domain/services/work_image_storage_interface.dart';
import '../image/base_image_processor.dart';
import '../image/work_image_processor.dart';
import '../storage/local_work_image_storage.dart';

/// 基础图片处理服务
final baseImageProcessorProvider = Provider<IImageProcessing>((ref) {
  return BaseImageProcessor();
});

/// 作品图片处理服务
final workImageProcessorProvider = Provider<IWorkImageProcessing>((ref) {
  return WorkImageProcessor();
});

/// 作品图片存储服务
final workImageStorageProvider = Provider<IWorkImageStorage>((ref) {
  return LocalWorkImageStorage();
});
