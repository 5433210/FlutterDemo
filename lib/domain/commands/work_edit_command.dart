import '../models/work/work_image.dart';

/// 删除图片命令
class DeleteImageCommand extends WorkEditCommand {
  final WorkImage image;

  const DeleteImageCommand({
    required super.workId,
    required this.image,
    required super.timestamp,
  }) : super(
          type: WorkEditCommandType.deleteImage,
          canUndo: true,
        );
}

/// 导入图片命令
class ImportImageCommand extends WorkEditCommand {
  final WorkImage image;

  const ImportImageCommand({
    required super.workId,
    required this.image,
    required super.timestamp,
  }) : super(
          type: WorkEditCommandType.importImage,
          canUndo: true,
        );
}

/// 旋转图片命令
class RotateImageCommand extends WorkEditCommand {
  final WorkImage image;
  final int degrees;
  final WorkImage? previousState;

  const RotateImageCommand({
    required super.workId,
    required this.image,
    required this.degrees,
    this.previousState,
    required super.timestamp,
  }) : super(
          type: WorkEditCommandType.rotateImage,
          canUndo: true,
        );
}

/// 更新封面命令
class UpdateCoverCommand extends WorkEditCommand {
  final String imageId;
  final String? previousImageId;

  const UpdateCoverCommand({
    required super.workId,
    required this.imageId,
    this.previousImageId,
    required super.timestamp,
  }) : super(
          type: WorkEditCommandType.updateCover,
          canUndo: previousImageId != null,
        );
}

/// 作品编辑命令基类
abstract class WorkEditCommand {
  final WorkEditCommandType type;
  final DateTime timestamp;
  final bool canUndo;
  final String workId;

  const WorkEditCommand({
    required this.type,
    required this.workId,
    required this.timestamp,
    this.canUndo = true,
  });
}

/// 命令工厂类
class WorkEditCommandFactory {
  static WorkEditCommand createDeleteCommand({
    required String workId,
    required WorkImage image,
  }) {
    return DeleteImageCommand(
      workId: workId,
      image: image,
      timestamp: DateTime.now(),
    );
  }

  static WorkEditCommand createImportCommand({
    required String workId,
    required WorkImage image,
  }) {
    return ImportImageCommand(
      workId: workId,
      image: image,
      timestamp: DateTime.now(),
    );
  }

  static WorkEditCommand createRotateCommand({
    required String workId,
    required WorkImage image,
    required int degrees,
    WorkImage? previousState,
  }) {
    return RotateImageCommand(
      workId: workId,
      image: image,
      degrees: degrees,
      previousState: previousState,
      timestamp: DateTime.now(),
    );
  }

  static WorkEditCommand createUpdateCoverCommand({
    required String workId,
    required String imageId,
    String? previousImageId,
  }) {
    return UpdateCoverCommand(
      workId: workId,
      imageId: imageId,
      previousImageId: previousImageId,
      timestamp: DateTime.now(),
    );
  }
}

/// 作品编辑命令类型
enum WorkEditCommandType {
  importImage, // 导入图片
  rotateImage, // 旋转图片
  deleteImage, // 删除图片
  updateCover, // 更新封面
}
