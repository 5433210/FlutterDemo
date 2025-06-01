// filepath: test/canvas/core/command_manager_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:charasgem/canvas/core/commands/command_manager.dart';
import 'package:charasgem/canvas/core/interfaces/command.dart';

/// 测试用的简单命令
class TestCommand implements Command {
  final String _id;
  final String _description;
  bool _executed = false;
  bool _undone = false;
  
  TestCommand(this._id, this._description);
  
  @override
  String get id => _id;
  
  @override
  String get description => _description;
  
  @override
  bool execute() {
    _executed = true;
    _undone = false;
    return true;
  }
  
  @override
  bool undo() {
    _executed = false;
    _undone = true;
    return true;
  }
  
  @override
  bool canMergeWith(Command other) => false;
  
  @override
  Command? mergeWith(Command other) => null;
  
  bool get wasExecuted => _executed;
  bool get wasUndone => _undone;
}

void main() {
  group('CommandManager', () {
    late CommandManager manager;
    
    setUp(() {
      manager = CommandManager();
    });
    
    test('should initialize with empty state', () {
      expect(manager.canUndo, false);
      expect(manager.canRedo, false);
      expect(manager.undoStackSize, 0);
      expect(manager.redoStackSize, 0);
    });
    
    test('should execute command correctly', () {
      final command = TestCommand('test1', 'Test Command 1');
      
      final result = manager.execute(command);
      
      expect(result, true);
      expect(command.wasExecuted, true);
      expect(manager.canUndo, true);
      expect(manager.canRedo, false);
      expect(manager.undoStackSize, 1);
    });
    
    test('should undo command correctly', () {
      final command = TestCommand('test1', 'Test Command 1');
      
      manager.execute(command);
      expect(manager.canUndo, true);
      
      final undoResult = manager.undo();
      
      expect(undoResult, true);
      expect(command.wasUndone, true);
      expect(manager.canUndo, false);
      expect(manager.canRedo, true);
      expect(manager.redoStackSize, 1);
    });
    
    test('should redo command correctly', () {
      final command = TestCommand('test1', 'Test Command 1');
      
      manager.execute(command);
      manager.undo();
      expect(manager.canRedo, true);
      
      final redoResult = manager.redo();
      
      expect(redoResult, true);
      expect(command.wasExecuted, true);
      expect(manager.canUndo, true);
      expect(manager.canRedo, false);
    });
    
    test('should handle multiple commands correctly', () {
      final command1 = TestCommand('test1', 'Test Command 1');
      final command2 = TestCommand('test2', 'Test Command 2');
      
      manager.execute(command1);
      manager.execute(command2);
      
      expect(manager.undoStackSize, 2);
      expect(command1.wasExecuted, true);
      expect(command2.wasExecuted, true);
      
      // 撤销最后一个命令
      manager.undo();
      expect(command2.wasUndone, true);
      expect(command1.wasExecuted, true); // 第一个命令仍然执行状态
      
      // 撤销第一个命令
      manager.undo();
      expect(command1.wasUndone, true);
      expect(manager.canUndo, false);
    });
    
    test('should clear redo stack when new command executed', () {
      final command1 = TestCommand('test1', 'Test Command 1');
      final command2 = TestCommand('test2', 'Test Command 2');
      final command3 = TestCommand('test3', 'Test Command 3');
      
      manager.execute(command1);
      manager.execute(command2);
      manager.undo(); // command2 进入redo栈
      
      expect(manager.canRedo, true);
      expect(manager.redoStackSize, 1);
      
      // 执行新命令应该清空redo栈
      manager.execute(command3);
      
      expect(manager.canRedo, false);
      expect(manager.redoStackSize, 0);
      expect(manager.undoStackSize, 2); // command1 + command3
    });
    
    test('should respect max undo steps limit', () {
      final manager = CommandManager(maxUndoSteps: 3);
      
      // 执行4个命令，超过限制
      for (int i = 0; i < 4; i++) {
        manager.execute(TestCommand('test$i', 'Test Command $i'));
      }
      
      expect(manager.undoStackSize, 3); // 应该只保留最近3个
    });
    
    test('should handle command execution failure gracefully', () {
      final failingCommand = FailingCommand();
      
      final result = manager.execute(failingCommand);
      
      expect(result, false);
      expect(manager.canUndo, false); // 失败的命令不应该进入撤销栈
    });
  });
}

/// 总是失败的测试命令
class FailingCommand implements Command {
  @override
  String get id => 'failing';
  
  @override
  String get description => 'Failing Command';
  
  @override
  bool execute() => false; // 总是失败
  
  @override
  bool undo() => false;
  
  @override
  bool canMergeWith(Command other) => false;
  
  @override
  Command? mergeWith(Command other) => null;
}
