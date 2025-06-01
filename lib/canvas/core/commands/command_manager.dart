// filepath: lib/canvas/core/commands/command_manager.dart

import 'dart:collection';

import '../interfaces/command.dart';

/// 空回调类型定义
typedef VoidCallback = void Function();

/// 命令管理器，实现撤销/重做功能
class CommandManager {
  final Queue<Command> _undoStack = Queue<Command>();
  final Queue<Command> _redoStack = Queue<Command>();

  /// 最大撤销步数
  final int maxUndoSteps;

  /// 状态变更回调
  final VoidCallback? onStateChanged;

  CommandManager({
    this.maxUndoSteps = 100,
    this.onStateChanged,
  });

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 重做栈大小
  int get redoStackSize => _redoStack.length;

  /// 撤销栈大小
  int get undoStackSize => _undoStack.length;

  /// 清空所有历史记录
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyStateChanged();
  }

  /// 执行命令
  bool execute(Command command) {
    try {
      if (command.execute()) {
        // 成功执行，添加到撤销栈
        _addToUndoStack(command);
        // 清空重做栈
        _redoStack.clear();
        _notifyStateChanged();
        return true;
      }
      return false;
    } catch (e) {
      // 记录错误但不抛出，保持系统稳定
      _logError('Failed to execute command: ${command.description}', e);
      return false;
    }
  }

  /// 重做操作
  bool redo() {
    if (!canRedo) return false;

    try {
      final command = _redoStack.removeLast();
      if (command.execute()) {
        _undoStack.addLast(command);
        _notifyStateChanged();
        return true;
      } else {
        // 重做失败，重新加入重做栈
        _redoStack.addLast(command);
        return false;
      }
    } catch (e) {
      _logError('Failed to redo command', e);
      return false;
    }
  }

  /// 撤销操作
  bool undo() {
    if (!canUndo) return false;

    try {
      final command = _undoStack.removeLast();
      if (command.undo()) {
        _redoStack.addLast(command);
        _notifyStateChanged();
        return true;
      } else {
        // 撤销失败，重新加入撤销栈
        _undoStack.addLast(command);
        return false;
      }
    } catch (e) {
      _logError('Failed to undo command', e);
      return false;
    }
  }

  /// 将命令添加到撤销栈
  void _addToUndoStack(Command command) {
    // 尝试与最后一个命令合并
    if (_undoStack.isNotEmpty) {
      final lastCommand = _undoStack.last;
      if (lastCommand.canMergeWith(command)) {
        final mergedCommand = lastCommand.mergeWith(command);
        if (mergedCommand != null) {
          _undoStack.removeLast();
          _undoStack.addLast(mergedCommand);
          return;
        }
      }
    }

    _undoStack.addLast(command);

    // 限制撤销栈大小
    while (_undoStack.length > maxUndoSteps) {
      _undoStack.removeFirst();
    }
  }
  /// 记录错误（简单实现，实际项目中应该使用日志框架）
  void _logError(String message, Object error) {
    // TODO: 实际项目中应该使用日志框架记录错误
    // print('CommandManager Error: $message - $error');
  }

  /// 通知状态变更
  void _notifyStateChanged() {
    onStateChanged?.call();
  }
}
