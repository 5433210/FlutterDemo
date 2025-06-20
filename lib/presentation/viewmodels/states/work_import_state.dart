import 'dart:io';

// Note: style and tool are now String types instead of enums

/// 作品导入状态
class WorkImportState {
  final List<File> images;
  final File? selectedImage;
  final String title;
  final String? author;
  final String? style;
  final String? tool;
  final String? remark;
  final bool isProcessing;
  final String? error;
  final bool optimizeImages;
  final bool keepOriginals;
  final Map<String, double> imageRotations;
  final double scale;
  final double rotation;
  final int selectedImageIndex;

  /// 跟踪图片来源：如果为true表示来自图库，false表示来自本地文件
  final List<bool> imageFromGallery;

  /// 当前处理状态消息（用于向用户显示进度）
  final String? statusMessage;
  const WorkImportState({
    this.images = const [],
    this.selectedImage,
    this.title = '',
    this.author = '',
    this.style,
    this.tool,
    this.remark = '',
    this.isProcessing = false,
    this.error,
    this.optimizeImages = true,
    this.keepOriginals = false,
    this.imageRotations = const {},
    this.scale = 1.0,
    this.rotation = 0.0,
    this.selectedImageIndex = 0,
    this.imageFromGallery = const [],
    this.statusMessage,
  });

  /// 获取干净的初始状态
  factory WorkImportState.clean() {
    return WorkImportState.initial().copyWith(
      images: const [],
      selectedImage: null,
      title: '',
      error: null,
      imageRotations: const {},
      imageFromGallery: const [],
    );
  }
  factory WorkImportState.initial() {
    return const WorkImportState(
      // 设置默认值
      style: 'regular',
      tool: 'brush',
      author: '', // 提供空字符串而不是 null
      remark: '', // 提供空字符串而不是 null
      optimizeImages: true,
      keepOriginals: false,
      scale: 1.0,
      rotation: 0.0,
      selectedImageIndex: 0,
    );
  }
  bool get canSubmit => hasImages && !isProcessing;
  bool get hasError => error != null;
  bool get hasImages => images.isNotEmpty;

  bool get isDirty =>
      hasImages || title.isNotEmpty || author?.isNotEmpty == true;
  WorkImportState copyWith({
    List<File>? images,
    File? selectedImage,
    String? title,
    String? author,
    String? style,
    String? tool,
    String? remark,
    bool? isProcessing,
    String? error,
    bool? optimizeImages,
    bool? keepOriginals,
    Map<String, double>? imageRotations,
    double? scale,
    double? rotation,
    int? selectedImageIndex,
    List<bool>? imageFromGallery,
    String? statusMessage,
  }) {
    return WorkImportState(
      images: images ?? this.images,
      selectedImage: selectedImage ?? this.selectedImage,
      title: title ?? this.title,
      author: author ?? this.author,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      remark: remark ?? this.remark,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      optimizeImages: optimizeImages ?? this.optimizeImages,
      keepOriginals: keepOriginals ?? this.keepOriginals,
      imageRotations: imageRotations ?? this.imageRotations,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      imageFromGallery: imageFromGallery ?? this.imageFromGallery,
      statusMessage: statusMessage,
    );
  }
}
