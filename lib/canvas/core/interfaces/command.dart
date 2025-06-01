// filepath: lib/canvas/core/interfaces/command.dart

/// 命令接口，实现命令模式以支持撤销/重做功能
abstract class Command {
  /// 命令描述，用于调试和日志
  String get description;

  /// 命令的唯一标识符
  String get id;

  /// 是否可以与其他命令合并（用于优化撤销栈）
  bool canMergeWith(Command other) => false;

  /// 执行命令
  bool execute();

  /// 与其他命令合并
  Command? mergeWith(Command other) => null;

  /// 撤销命令
  bool undo();
}
