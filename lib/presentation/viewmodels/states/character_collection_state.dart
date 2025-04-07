import 'package:equatable/equatable.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/undo_action.dart';
import '../../providers/character/tool_mode_provider.dart';

// 集字功能状态
class CharacterCollectionState extends Equatable {
  final String? workId;
  final String? pageId;
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final Set<String> modifiedIds;
  final String? currentId;
  final Tool currentTool;
  final ProcessingOptions defaultOptions;
  final List<UndoAction> undoStack;
  final List<UndoAction> redoStack;
  final bool loading;
  final bool processing;
  final String? error;
  final bool isAdjusting;

  const CharacterCollectionState({
    this.workId,
    this.pageId,
    required this.regions,
    required this.selectedIds,
    required this.modifiedIds,
    this.currentId,
    required this.currentTool,
    required this.defaultOptions,
    required this.undoStack,
    required this.redoStack,
    required this.loading,
    required this.processing,
    this.error,
    this.isAdjusting = false,
  });

  // 初始状态
  factory CharacterCollectionState.initial() {
    return const CharacterCollectionState(
      regions: [],
      selectedIds: {},
      modifiedIds: {},
      currentTool: Tool.pan,
      defaultOptions: ProcessingOptions(),
      undoStack: [],
      redoStack: [],
      loading: false,
      processing: false,
      isAdjusting: false,
    );
  }

  // 是否有重做操作
  bool get canRedo => redoStack.isNotEmpty;

  // 是否有撤销操作
  bool get canUndo => undoStack.isNotEmpty;

  // 是否有多选区域
  bool get hasMultiSelection => selectedIds.isNotEmpty;

  // 是否有选中的区域
  bool get hasSelection => currentId != null;

  // 是否有未保存的修改区域
  bool get hasUnsavedChanges => modifiedIds.isNotEmpty;

  @override
  List<Object?> get props => [
        workId,
        pageId,
        regions,
        selectedIds,
        modifiedIds,
        currentId,
        currentTool,
        defaultOptions,
        undoStack,
        redoStack,
        loading,
        processing,
        error,
        isAdjusting,
      ];

  // 当前选中的区域
  CharacterRegion? get selectedRegion {
    if (currentId == null) return null;
    try {
      return regions.firstWhere((r) => r.id == currentId);
    } catch (e) {
      return null;
    }
  }

  // 创建副本并更新部分属性
  CharacterCollectionState copyWith({
    String? workId,
    String? pageId,
    List<CharacterRegion>? regions,
    Set<String>? selectedIds,
    Set<String>? modifiedIds,
    String? currentId,
    Tool? currentTool,
    ProcessingOptions? defaultOptions,
    List<UndoAction>? undoStack,
    List<UndoAction>? redoStack,
    bool? loading,
    bool? processing,
    String? error,
    bool? isAdjusting,
  }) {
    return CharacterCollectionState(
      workId: workId ?? this.workId,
      pageId: pageId ?? this.pageId,
      regions: regions ?? this.regions,
      selectedIds: selectedIds ?? this.selectedIds,
      modifiedIds: modifiedIds ?? this.modifiedIds,
      currentId: currentId ?? this.currentId,
      currentTool: currentTool ?? this.currentTool,
      defaultOptions: defaultOptions ?? this.defaultOptions,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      error: error,
      isAdjusting: isAdjusting ?? this.isAdjusting,
    );
  }
}
