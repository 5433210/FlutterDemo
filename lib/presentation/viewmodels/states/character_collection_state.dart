import 'package:equatable/equatable.dart';

import '../../../domain/models/character/character_filter.dart';
import '../../../domain/models/character/character_region.dart';

class CharacterCollectionState extends Equatable {
  final List<CharacterRegion> characters;
  final ViewMode viewMode;
  final Set<String> selectedCharacters;
  final CharacterFilter filter;
  final bool isLoading;
  final bool isSidebarOpen;
  final bool batchMode;
  final String? error;
  final String? selectedCharacterId;

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
  });

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
      ];

  CharacterCollectionState copyWith({
    List<CharacterRegion>? characters,
    ViewMode? viewMode,
    Set<String>? selectedCharacters,
    CharacterFilter? filter,
    bool? isLoading,
    bool? isSidebarOpen,
    bool? batchMode,
    String? error,
    String? selectedCharacterId,
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
    );
  }
}

enum ViewMode { grid, list }
