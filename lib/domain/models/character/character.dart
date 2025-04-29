class Character {
  final String id;
  final String character;
  final String? imageUrl;
  final String workId;
  final String pageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Character({
    required this.id,
    required this.character,
    this.imageUrl,
    required this.workId,
    required this.pageId,
    required this.createdAt,
    required this.updatedAt,
  });

  Character copyWith({
    String? id,
    String? character,
    String? imageUrl,
    String? workId,
    String? pageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Character(
      id: id ?? this.id,
      character: character ?? this.character,
      imageUrl: imageUrl ?? this.imageUrl,
      workId: workId ?? this.workId,
      pageId: pageId ?? this.pageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Character{id: $id, character: $character, workId: $workId, pageId: $pageId}';
  }
}
