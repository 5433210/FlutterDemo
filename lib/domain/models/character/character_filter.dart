import 'package:equatable/equatable.dart';

class CharacterFilter extends Equatable {
  final String? searchQuery;
  final List<String> styles;
  final List<String> tools;
  final SortOption sortOption;

  const CharacterFilter({
    this.searchQuery,
    this.styles = const [],
    this.tools = const [],
    this.sortOption = SortOption.createTime,
  });

  @override
  List<Object?> get props => [searchQuery, styles, tools, sortOption];

  CharacterFilter copyWith({
    String? searchQuery,
    List<String>? styles,
    List<String>? tools,
    SortOption? sortOption,
  }) {
    return CharacterFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      styles: styles ?? this.styles,
      tools: tools ?? this.tools,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

enum SortOption { createTime, character }
