import 'dart:io';

import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/value_objects/work/work_entity.dart';
import '../../domain/value_objects/work/work_image.dart';
import '../services/work/work_image_service.dart';

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

  RotateImageCommand({
    required this.imageIndex,
    required this.angle,
    required this.imageService, // 添加图片服务依赖
  });

  @override
  String get description => '旋转图片';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    if (imageIndex < 0 || imageIndex >= updatedImages.length) {
      return work; // 索引无效，不做更改
    }

    // 获取当前图片
    final currentImage = updatedImages[imageIndex];
    final importedPath = currentImage.imported?.path;

    if (importedPath == null) {
      return work; // 没有图片路径，不做更改
    }

    // 保存原始路径，用于撤销
    _originalPath = importedPath;

    // 执行实际的旋转操作
    final rotatedFile = await imageService.rotateImage(
      File(importedPath),
      angle,
    );

    // 保存旋转后的路径
    _rotatedPath = rotatedFile.path;

    // 更新图片信息
    final updatedImage = currentImage.copyWith(
      imported: ImageDetail(
        path: rotatedFile.path,
        width: currentImage.imported?.height ?? 0, // 旋转90度时宽高互换
        height: currentImage.imported?.width ?? 0,
        format: currentImage.imported?.format ?? '',
        size: currentImage.imported?.size ?? 0,
      ),
    );

    updatedImages[imageIndex] = updatedImage;

    // 返回更新后的 WorkEntity
    return work.copyWith(
      images: updatedImages,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    final List<WorkImage> updatedImages = List.from(work.images);

    if (imageIndex < 0 ||
        imageIndex >= updatedImages.length ||
        _originalPath == null) {
      return work; // 索引无效或无原始路径，不做更改
    }

    // 获取当前图片
    final currentImage = updatedImages[imageIndex];

    // 恢复原始图片
    final updatedImage = currentImage.copyWith(
      imported: ImageDetail(
        path: _originalPath!,
        width: currentImage.imported?.height ?? 0, // 反向旋转，宽高再次互换
        height: currentImage.imported?.width ?? 0,
        format: currentImage.imported?.format ?? '',
        size: currentImage.imported?.size ?? 0,
      ),
    );

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
      name: newName ?? work.name,
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
      name: oldName ?? work.name,
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
