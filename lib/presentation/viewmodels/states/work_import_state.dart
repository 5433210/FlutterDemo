import 'dart:io';

class WorkImportState {
  final List<File> images;
  final int selectedImageIndex;
  final bool isLoading;
  final String? error;
  final String name;
  final String? author;
  final DateTime? creationDate;
  final String? style;
  final String? tool;
  final String? remarks;
  final bool optimizeImages;
  final bool keepOriginals;
  final double zoomLevel;
  final double rotation;

  const WorkImportState({
    this.images = const [],
    this.selectedImageIndex = 0,
    this.isLoading = false,
    this.error,
    this.name = '',
    this.author,
    this.creationDate,
    this.style,
    this.tool,
    this.remarks,
    this.optimizeImages = true,
    this.keepOriginals = true,
    this.zoomLevel = 1.0,
    this.rotation = 0.0,
  });

  bool get isValid => name.isNotEmpty && images.isNotEmpty;

  WorkImportState copyWith({
    List<File>? images,
    int? selectedImageIndex,
    bool? isLoading,
    String? error,
    String? name,
    String? author,
    DateTime? creationDate,
    String? style,
    String? tool,
    String? remarks,
    bool? optimizeImages,
    bool? keepOriginals,
    double? zoomLevel,
    double? rotation,
  }) {
    return WorkImportState(
      images: images ?? this.images,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      name: name ?? this.name,
      author: author ?? this.author,
      creationDate: creationDate ?? this.creationDate,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      remarks: remarks ?? this.remarks,
      optimizeImages: optimizeImages ?? this.optimizeImages,
      keepOriginals: keepOriginals ?? this.keepOriginals,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      rotation: rotation ?? this.rotation,
    );
  }
}