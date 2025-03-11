import 'dart:io';

import 'package:demo/application/services/work/work_image_service.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;

import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_image.dart';

Future<ImageMetadata> _getImageMetadata(File file) async {
  final image = await decodeImageFromList(await file.readAsBytes());
  final size = await file.length();
  final format = path.extension(file.path).toLowerCase().replaceAll('.', '');

  return ImageMetadata(
    width: image.width,
    height: image.height,
    format: format,
    size: size,
  );
}

/// 命令：添加图片
class AddImageCommand implements WorkEditCommand {
  final WorkImage newImage;
  final int position;

  AddImageCommand({
    required this.newImage,
    required this.position,
  });

  @override
  String get description => '添加图片';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    // 在指定位置插入新图片
    if (position >= 0 && position <= updatedImages.length) {
      updatedImages.insert(position, newImage);
    } else {
      updatedImages.add(newImage);
    }

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      imageCount: updatedImages.length,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    // 移除添加的图片
    if (position >= 0 && position < updatedImages.length) {
      updatedImages.removeAt(position);
    }

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      imageCount: updatedImages.length,
      updateTime: DateTime.now(),
    );
  }
}

/// Class to store metadata about an image
class ImageMetadata {
  final int width;
  final int height;
  final String format;
  final int size;

  ImageMetadata({
    required this.width,
    required this.height,
    required this.format,
    required this.size,
  });
}

/// 命令：删除图片
class RemoveImageCommand implements WorkEditCommand {
  final WorkImage removedImage;
  final int position;

  RemoveImageCommand({
    required this.removedImage,
    required this.position,
  });

  @override
  String get description => '删除图片';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    // 删除指定位置的图片
    if (position >= 0 && position < updatedImages.length) {
      updatedImages.removeAt(position);
    }

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      imageCount: updatedImages.length,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    // 恢复被删除的图片
    if (position >= 0 && position <= updatedImages.length) {
      updatedImages.insert(position, removedImage);
    }

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      imageCount: updatedImages.length,
      updateTime: DateTime.now(),
    );
  }
}

/// 命令：重排图片顺序
class ReorderImagesCommand implements WorkEditCommand {
  final int oldIndex;
  final int newIndex;

  ReorderImagesCommand({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  String get description => '重排图片顺序';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    // 重排序图片
    if (oldIndex < updatedImages.length && newIndex <= updatedImages.length) {
      final item = updatedImages.removeAt(oldIndex);

      // 调整新索引以适应移除
      final effectiveNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      updatedImages.insert(effectiveNewIndex, item);
    }

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    // 撤销重排序就是反向再做一次
    final List<WorkImage> updatedImages = List.from(work.images);

    // 计算恢复位置
    final effectiveOldIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    if (effectiveOldIndex < updatedImages.length) {
      final item = updatedImages.removeAt(effectiveOldIndex);
      updatedImages.insert(oldIndex, item);
    }

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      updateTime: DateTime.now(),
    );
  }
}

/// 命令：旋转图片
class RotateImageCommand implements WorkEditCommand {
  final int imageIndex;
  final int angle; // 角度，通常是90的倍数
  final WorkImageService imageService; // 添加图片服务依赖

  // 保存原始和旋转后的文件信息，用于撤销
  String? _originalPath;
  String? _rotatedPath;

  // 保存旧图片和新图片用于执行和撤销
  WorkImage? _oldImage;

  WorkImage? _newImage;

  RotateImageCommand({
    required this.imageIndex,
    required this.angle,
    required this.imageService, // 添加图片服务依赖
  });

  @override
  String get description => '旋转图片';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    // 确保imageIndex有效
    if (imageIndex < 0 || imageIndex >= work.images.length) {
      throw ArgumentError('无效的图片索引: $imageIndex');
    }

    // 保存旧图片信息用于撤销
    _oldImage = work.images[imageIndex];

    // 确保图片和服务都不为空
    if (_oldImage?.path == null) {
      throw StateError('图片路径无效');
    }

    try {
      // 1. 获取原始图片的文件
      final originalFile = File(_oldImage!.path);
      if (!await originalFile.exists()) {
        throw FileSystemException('原始图片不存在', _oldImage!.path);
      }

      // 2. 旋转图片
      final rotatedFile = await imageService.rotateImage(originalFile, angle,
          preserveSize: true);

      // 3. 确保旋转后的图片被写入到原路径 (覆盖原文件)
      await rotatedFile.copy(_oldImage!.path);

      // 4. 重新生成缩略图
      final thumbnailFile = await imageService.createThumbnail(rotatedFile);

      // 覆盖原有缩略图
      await thumbnailFile.copy(_oldImage!.thumbnailPath);

      // 获取图片元数据
      final metadata = await _getImageMetadata(rotatedFile);

      // 6. 创建新的 WorkImage 对象
      _newImage = WorkImage(
        id: _oldImage!.id,
        workId: work.id,
        originalPath: _oldImage!.originalPath,
        path: _oldImage!.path,
        index: _oldImage!.index,
        thumbnailPath: _oldImage!.thumbnailPath,
        width: metadata.width,
        height: metadata.height,
        format: metadata.format,
        size: metadata.size,
        createTime: _oldImage!.createTime ?? DateTime.now(),
        updateTime: DateTime.now(),
      );

      // 7. 更新图片列表
      final updatedImages = List<WorkImage>.from(work.images);
      updatedImages[imageIndex] = _newImage!;
      return work.copyWith(
        images: updatedImages,
        updateTime: DateTime.now(),
      );
    } catch (e, stack) {
      // Import logger if needed: import '../../utils/app_logger.dart';
      debugPrint('旋转图片失败: $e\n$stack');
      throw Exception('旋转图片失败: $e');
    }
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);
    if (imageIndex < 0 ||
        imageIndex >= updatedImages.length ||
        _oldImage == null) {
      return work; // 索引无效或无原始图片，不做更改
    }

    // 获取当前图片
    final currentImage = updatedImages[imageIndex];
    // 恢复原始图片
    final updatedImage = _oldImage!;

    updatedImages[imageIndex] = updatedImage;

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      updateTime: DateTime.now(),
    );
  }
}

/// 命令：更新作品基本信息
class UpdateInfoCommand implements WorkEditCommand {
  final String? newName;
  final String? newAuthor;
  final WorkStyle? newStyle;
  final WorkTool? newTool;
  final DateTime? newCreationDate;
  final String? newRemark;

  // 存储旧值用于撤销
  final String? oldName;
  final String? oldAuthor;
  final WorkStyle? oldStyle;
  final WorkTool? oldTool;
  final DateTime? oldCreationDate;
  final String? oldRemark;

  UpdateInfoCommand({
    this.newName,
    this.newAuthor,
    this.newStyle,
    this.newTool,
    this.newCreationDate,
    this.newRemark,
    this.oldName,
    this.oldAuthor,
    this.oldStyle,
    this.oldTool,
    this.oldCreationDate,
    this.oldRemark,
  });

  @override
  String get description => '更新基本信息';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    // 确保 ID 被保留
    return work.copyWith(
      id: work.id, // 明确保留原有 ID
      title: newName ?? work.title,
      author: newAuthor ?? work.author,
      style: newStyle ?? work.style,
      tool: newTool ?? work.tool,
      creationDate: newCreationDate ?? work.creationDate,
      remark: newRemark ?? work.remark,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    // 返回恢复后的 WorkEntity
    return work.copyWith(
      title: oldName ?? work.title,
      author: oldAuthor ?? work.author,
      style: oldStyle ?? work.style,
      tool: oldTool ?? work.tool,
      creationDate: oldCreationDate ?? work.creationDate,
      remark: oldRemark ?? work.remark,
      updateTime: DateTime.now(),
    );
  }
}

/// 编辑命令基类，用于实现撤销/重做功能
abstract class WorkEditCommand {
  /// 命令描述，用于UI显示
  String get description;

  /// 执行命令
  Future<WorkEntity> execute(WorkEntity work);

  /// 撤销命令
  Future<WorkEntity> undo(WorkEntity work);
}
