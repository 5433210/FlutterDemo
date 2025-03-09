import 'dart:io';

import '../../domain/services/image_processing_interface.dart';
import '../models/work/work_image.dart';

abstract class IWorkImageProcessing implements IImageProcessing {
  /// 生成作品缩略图（Work专用）
  Future<File> generateWorkThumbnail(File image);

  /// 处理作品图片（Work专用）
  Future<List<WorkImage>> processWorkImages(String workId, List<File> images);
}
