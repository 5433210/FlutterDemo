import '../../domain/value_objects/work/work_entity.dart';
import 'work_edit_commands.dart';

/// 命令：添加标签
class AddTagCommand implements WorkEditCommand {
  final String tag;

  AddTagCommand(this.tag);

  @override
  String get description => '添加标签 "$tag"';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    // 获取当前标签列表
    final currentTags = work.metadata?.tags ?? [];

    // 检查标签是否已存在
    if (currentTags.contains(tag)) {
      return work; // 标签已存在，不做更改
    }

    // 添加新标签
    final updatedTags = List<String>.from(currentTags)..add(tag);

    // 更新作品元数据
    final updatedMetadata = WorkMetadata(tags: updatedTags);

    // 返回更新后的作品实体
    return work.copyWith(
      metadata: updatedMetadata,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    // 获取当前标签列表
    final currentTags = work.metadata?.tags ?? [];

    // 移除添加的标签
    final updatedTags = List<String>.from(currentTags)
      ..removeWhere((t) => t == tag);

    // 更新作品元数据
    final updatedMetadata = WorkMetadata(tags: updatedTags);

    // 返回更新后的作品实体
    return work.copyWith(
      metadata: updatedMetadata,
      updateTime: DateTime.now(),
    );
  }
}

/// 命令：删除标签
class RemoveTagCommand implements WorkEditCommand {
  final String tag;

  RemoveTagCommand(this.tag);

  @override
  String get description => '删除标签 "$tag"';

  @override
  Future<WorkEntity> execute(WorkEntity work) async {
    // 获取当前标签列表
    final currentTags = work.metadata?.tags ?? [];

    // 移除指定标签
    final updatedTags = List<String>.from(currentTags)
      ..removeWhere((t) => t == tag);

    // 更新作品元数据
    final updatedMetadata = WorkMetadata(tags: updatedTags);

    // 返回更新后的作品实体
    return work.copyWith(
      metadata: updatedMetadata,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<WorkEntity> undo(WorkEntity work) async {
    // 获取当前标签列表
    final currentTags = work.metadata?.tags ?? [];

    // 检查标签是否已存在
    if (currentTags.contains(tag)) {
      return work; // 标签已存在，不做更改
    }

    // 重新添加被删除的标签
    final updatedTags = List<String>.from(currentTags)..add(tag);

    // 更新作品元数据
    final updatedMetadata = WorkMetadata(tags: updatedTags);

    // 返回更新后的作品实体
    return work.copyWith(
      metadata: updatedMetadata,
      updateTime: DateTime.now(),
    );
  }
}
