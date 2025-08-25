import 'package:flutter/material.dart';
import 'undo_operations.dart';

/// 自定义操作
class CustomOperation implements UndoableOperation {
  final VoidCallback _executeCallback;
  final VoidCallback _undoCallback;
  final int? _pageIndex;
  final String? _pageId;
  
  @override
  final String description;
  
  @override
  int? get associatedPageIndex => _pageIndex;
  
  @override
  String? get associatedPageId => _pageId;

  CustomOperation({
    required VoidCallback execute,
    required VoidCallback undo,
    required this.description,
    int? pageIndex,
    String? pageId,
  })  : _executeCallback = execute,
        _undoCallback = undo,
        _pageIndex = pageIndex,
        _pageId = pageId;

  @override
  void execute() {
    _executeCallback();
  }

  @override
  void undo() {
    _undoCallback();
  }
}
