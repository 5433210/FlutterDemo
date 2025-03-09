/// 命令接口
abstract class CommandInterface<T> {
  /// 执行命令
  Future<T?> execute();

  /// 撤销命令
  Future<T?> undo();
}
