import 'package:flutter/material.dart';
import 'undo_operations.dart';

/// 自定义操作
class CustomOperation implements UndoableOperation {
  final VoidCallback _executeCallback;
  final VoidCallback _undoCallback;
  @override
  final String description;

  CustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required this.description,
  })  : _executeCallback = execute,
        _undoCallback = undo;

  @override
  void execute() {
    _executeCallback();
  }

  @override
  void undo() {
    _undoCallback();
  }
}
