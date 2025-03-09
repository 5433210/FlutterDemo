import 'package:equatable/equatable.dart';

import '../../../domain/models/character/character_entity.dart';
import '../../../domain/models/character/character_filter.dart';

/// 集字管理页面状态
class CharacterCollectionState extends Equatable {
  /// 字形列表
  final List<CharacterEntity> characters;

  /// 视图模式
  final ViewMode viewMode;

  /// 选中的字形ID集合
  final Set<String> selectedCharacters;

  /// 过滤条件
  final CharacterFilter filter;

  /// 是否正在加载
  final bool isLoading;

  /// 侧边栏是否打开
  final bool isSidebarOpen;

  /// 是否批量操作模式
  final bool batchMode;

  /// 错误信息
  final String? error;

  /// 当前选中的字形ID
  final String? selectedCharacterId;

  /// 统计信息
  final Map<String, int> stats;

  const CharacterCollectionState({
    this.characters = const [],
    this.viewMode = ViewMode.grid,
    this.selectedCharacters = const {},
    this.filter = const CharacterFilter(),
    this.isLoading = false,
    this.isSidebarOpen = false,
    this.batchMode = false,
    this.error,
    this.selectedCharacterId,
    this.stats = const {},
  });

  /// 获取草书字数
  int get cursiveCount => stats['cursive'] ?? 0;

  @override
  List<Object?> get props => [
        characters,
        viewMode,
        selectedCharacters,
        filter,
        isLoading,
        isSidebarOpen,
        batchMode,
        error,
        selectedCharacterId,
        stats,
      ];

  /// 获取楷书字数
  int get regularCount => stats['regular'] ?? 0;

  /// 获取篆书字数
  int get sealCount => stats['seal'] ?? 0;

  /// 获取当前选中的字形
  CharacterEntity? get selectedCharacter => selectedCharacterId != null
      ? characters.firstWhere(
          (char) => char.id == selectedCharacterId,
          orElse: () => characters.first,
        )
      : null;

  /// 获取总字数
  int get totalCount => stats['total'] ?? 0;

  CharacterCollectionState copyWith({
    List<CharacterEntity>? characters,
    ViewMode? viewMode,
    Set<String>? selectedCharacters,
    CharacterFilter? filter,
    bool? isLoading,
    bool? isSidebarOpen,
    bool? batchMode,
    String? error,
    String? selectedCharacterId,
    Map<String, int>? stats,
  }) {
    return CharacterCollectionState(
      characters: characters ?? this.characters,
      viewMode: viewMode ?? this.viewMode,
      selectedCharacters: selectedCharacters ?? this.selectedCharacters,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      batchMode: batchMode ?? this.batchMode,
      error: error ?? this.error,
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
      stats: stats ?? this.stats,
    );
  }
}

/// 视图模式
enum ViewMode {
  /// 网格视图
  grid,

  /// 列表视图
  list,
}
