import 'dart:ui';

class UndoAction {
  final UndoActionType type;
  final dynamic data;
  final DateTime timestamp;

  UndoAction({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // 创建批量操作记录
  factory UndoAction.batch(List<UndoAction> actions) {
    return UndoAction(
      type: UndoActionType.batch,
      data: actions,
    );
  }

  // 创建新建操作记录
  factory UndoAction.create(String characterId) {
    return UndoAction(
      type: UndoActionType.create,
      data: characterId,
    );
  }

  // 创建删除操作记录
  factory UndoAction.delete(String characterId, dynamic deletedState) {
    return UndoAction(
      type: UndoActionType.delete,
      data: {
        'id': characterId,
        'deletedState': deletedState,
      },
    );
  }

  // 创建擦除操作记录
  factory UndoAction.erase(String characterId, List<List<Offset>> erasePaths) {
    return UndoAction(
      type: UndoActionType.erase,
      data: {
        'id': characterId,
        'erasePaths': erasePaths,
      },
    );
  }

  // 创建更新操作记录
  factory UndoAction.update(String characterId, dynamic originalState) {
    return UndoAction(
      type: UndoActionType.update,
      data: {
        'id': characterId,
        'originalState': originalState,
      },
    );
  }
}

enum UndoActionType {
  create, // 创建新字符
  update, // 更新字符
  delete, // 删除字符
  erase, // 擦除操作
  batch // 批量操作
}
