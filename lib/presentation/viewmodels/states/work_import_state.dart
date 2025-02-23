import 'dart:io';
import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';

class WorkImportState {
  final List<File> images;
  final int selectedImageIndex;
  final Map<String, double> imageRotations;
  final double scale;
  final String name;
  final String? author;
  final WorkStyle? style;
  final WorkTool? tool;
  final DateTime? creationDate;
  final String? remarks;
  final bool optimizeImages;
  final bool keepOriginals;
  final bool isLoading;
  final String? error;
  final double? zoomLevel;
  final double? rotation;

  const WorkImportState({
    this.images = const [],
    this.selectedImageIndex = -1,
    this.imageRotations = const {},
    this.scale = 1.0,
    this.name = '',
    this.author,
    this.style,
    this.tool,
    this.creationDate,
    this.remarks,
    this.optimizeImages = true,
    this.keepOriginals = false,
    this.isLoading = false,
    this.error,
    this.zoomLevel = 1.0,
    this.rotation = 0.0,
  });

  bool get isDirty => images.isNotEmpty || name.isNotEmpty;

  bool get isValid => name.isNotEmpty && images.isNotEmpty;

  double getRotation(String imagePath) => imageRotations[imagePath] ?? 0.0;

  // 添加验证方法
  bool validateImage(File file) {
    try {
      final path = file.path.toLowerCase();
      return path.endsWith('.jpg') || 
             path.endsWith('.jpeg') || 
             path.endsWith('.png') || 
             path.endsWith('.webp');
    } catch (e) {
      return false;
    }
  }

  WorkImportState copyWith({
    List<File>? images,
    int? selectedImageIndex,
    Map<String, double>? imageRotations,
    double? scale,
    String? name,
    String? author,
    WorkStyle? style,
    WorkTool? tool,
    DateTime? creationDate,
    String? remarks,
    bool? optimizeImages,
    bool? keepOriginals,
    bool? isLoading,
    String? error,
    double? zoomLevel,
    double? rotation,
  }) {
    return WorkImportState(
      images: images ?? this.images,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      imageRotations: imageRotations ?? this.imageRotations,
      scale: scale ?? this.scale,
      name: name ?? this.name,
      author: author ?? this.author,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      creationDate: creationDate ?? this.creationDate,
      remarks: remarks ?? this.remarks,
      optimizeImages: optimizeImages ?? this.optimizeImages,
      keepOriginals: keepOriginals ?? this.keepOriginals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      rotation: rotation ?? this.rotation,
    );
  }

  // 添加初始状态工厂方法
  factory WorkImportState.initial() {
    return const WorkImportState();
  }
}