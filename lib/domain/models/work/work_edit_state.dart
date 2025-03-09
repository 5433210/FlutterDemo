import 'package:equatable/equatable.dart';

import 'work_entity.dart';

/// 作品编辑状态
class WorkEditState extends Equatable {
  /// 是否处于编辑模式
  final bool isEditing;

  /// 编辑中的作品
  final WorkEntity? editingWork;

  /// 是否有未保存的更改
  final bool hasChanges;

  /// 编辑历史索引
  final int historyIndex;

  /// 编辑历史
  final List<WorkEntity> history;

  const WorkEditState({
    this.isEditing = false,
    this.editingWork,
    this.hasChanges = false,
    this.historyIndex = -1,
    this.history = const [],
  });

  factory WorkEditState.fromJson(Map<String, dynamic> json) {
    return WorkEditState(
      isEditing: json['isEditing'] as bool? ?? false,
      editingWork: json['editingWork'] != null
          ? WorkEntity.fromJson(json['editingWork'] as Map<String, dynamic>)
          : null,
      hasChanges: json['hasChanges'] as bool? ?? false,
      historyIndex: json['historyIndex'] as int? ?? -1,
      history: (json['history'] as List?)
              ?.map((w) => WorkEntity.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// 创建一个新的编辑会话
  factory WorkEditState.startEditing(WorkEntity work) {
    return WorkEditState(
      isEditing: true,
      editingWork: work,
      history: [work],
      historyIndex: 0,
    );
  }

  @override
  List<Object?> get props => [
        isEditing,
        editingWork,
        hasChanges,
        historyIndex,
        history,
      ];

  WorkEditState copyWith({
    bool? isEditing,
    WorkEntity? editingWork,
    bool? hasChanges,
    int? historyIndex,
    List<WorkEntity>? history,
  }) {
    return WorkEditState(
      isEditing: isEditing ?? this.isEditing,
      editingWork: editingWork ?? this.editingWork,
      hasChanges: hasChanges ?? this.hasChanges,
      historyIndex: historyIndex ?? this.historyIndex,
      history: history ?? this.history,
    );
  }

  /// 结束编辑
  WorkEditState endEditing() {
    return const WorkEditState();
  }

  /// 重做编辑
  WorkEditState? redo() {
    if (historyIndex >= history.length - 1) return null;

    return copyWith(
      editingWork: history[historyIndex + 1],
      historyIndex: historyIndex + 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEditing': isEditing,
      'editingWork': editingWork?.toJson(),
      'hasChanges': hasChanges,
      'historyIndex': historyIndex,
      'history': history.map((w) => w.toJson()).toList(),
    };
  }

  /// 撤销编辑
  WorkEditState? undo() {
    if (historyIndex <= 0) return null;

    return copyWith(
      editingWork: history[historyIndex - 1],
      historyIndex: historyIndex - 1,
    );
  }

  /// 更新编辑状态
  WorkEditState updateWork(WorkEntity work) {
    final newHistory =
        List<WorkEntity>.from(history.sublist(0, historyIndex + 1))..add(work);

    return copyWith(
      editingWork: work,
      hasChanges: true,
      history: newHistory,
      historyIndex: newHistory.length - 1,
    );
  }
}
