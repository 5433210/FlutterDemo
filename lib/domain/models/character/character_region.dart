import 'dart:ui';

class CharacterRegion {
  final int pageIndex;
  Rect rect;
  String imagePath;
  String? label;
  Color? color;
  double rotation;
  bool isSaved; // Add this field to track saved state

  CharacterRegion({
    required this.pageIndex,
    required this.rect,
    required this.imagePath,
    this.label,
    this.color,
    this.rotation = 0,
    this.isSaved = false, // Default to false
  });

  CharacterRegion copyWith({
    int? pageIndex,
    Rect? rect,
    String? imagePath,
    String? label,
    Color? color,
    double? rotation,
    bool? isSaved,
  }) {
    return CharacterRegion(
      pageIndex: pageIndex ?? this.pageIndex,
      rect: rect ?? this.rect,
      imagePath: imagePath ?? this.imagePath,
      label: label ?? this.label,
      color: color ?? this.color,
      rotation: rotation ?? this.rotation,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  void toMap() {}
}
