import 'dart:io';
import 'package:demo/domain/value_objects/work/work_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../application/config/app_config.dart';
import '../../application/services/work_service.dart';
import '../../application/services/image_service.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import 'states/work_import_state.dart';

class WorkImportViewModel extends StateNotifier<WorkImportState> {
  final WorkService _workService;
  final ImageService _imageService;

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setAuthor(String author) {
    state = state.copyWith(author: author);
  }

  void setStyle(String style) {
    state = state.copyWith(
      style: WorkStyle.values.firstWhere((e) => e.toString() == 'WorkStyle.$style')
    );
  } 

  void setTool(String tool) {
    state = state.copyWith(
      tool: WorkTool.values.firstWhere((e) => e.toString() == 'WorkTool.$tool')
    );
  } 

  void setCreationDate(DateTime? date) {
    state = state.copyWith(creationDate: date);
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  WorkImportViewModel(this._workService, this._imageService) 
      : super(const WorkImportState());

  Future<void> addImages(List<File> files) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // 验证文件类型
      for (final file in files) {
        final ext = path.extension(file.path).toLowerCase();
        if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
          throw Exception('不支持的文件类型: $ext');
        }
      }

      // 添加到现有图片列表
      final updatedImages = List<File>.from(state.images)..addAll(files);
      
      state = state.copyWith(
        images: updatedImages,
        selectedImageIndex: state.images.isEmpty ? 0 : state.selectedImageIndex,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= state.images.length) return;

    final updatedImages = List<File>.from(state.images)..removeAt(index);
    final newSelectedIndex = updatedImages.isEmpty 
        ? -1 
        : index >= updatedImages.length 
            ? updatedImages.length - 1 
            : index;

    state = state.copyWith(
      images: updatedImages,
      selectedImageIndex: newSelectedIndex,
    );
  }

  void clearImages() {
    state = state.copyWith(
      images: [],
      selectedImageIndex: 0,
    );
  }

  void selectImage(int index) {
    if (index < 0 || index >= state.images.length) return;
    
    state = state.copyWith(selectedImageIndex: index);
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAuthor(String? author) {
    state = state.copyWith(author: author);
  }

  void updateCreationDate(DateTime? date) {
    state = state.copyWith(creationDate: date);
  }

  void updateTool(WorkTool? value) {
    state = state.copyWith(tool: value);
  } 

  void updateStyle(WorkStyle? value) {
    state = state.copyWith(style: value);
  }


  void updateRemarks(String? remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void toggleOptimizeImages() {
    state = state.copyWith(optimizeImages: !state.optimizeImages);
  }

  void toggleKeepOriginals() {
    state = state.copyWith(keepOriginals: !state.keepOriginals);
  }

  void updateZoom(double level) {
    state = state.copyWith(zoomLevel: level.clamp(0.1, 5.0));
  }

  void updateRotation(double angle) {
    state = state.copyWith(rotation: angle % 360);
  }

  Future<void> rotateImage(bool clockwise) async {
    if (state.selectedImageIndex < 0 || state.selectedImageIndex >= state.images.length) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final angle = clockwise ? 90.0 : -90.0;
      final selectedFile = state.images[state.selectedImageIndex];
      
      // Process image rotation
      final rotatedImage = await _imageService.rotateImage(
        selectedFile,
        angle.toInt(),
      );
      
      // Update image list with rotated image
      final updatedImages = List<File>.from(state.images);
      updatedImages[state.selectedImageIndex] = rotatedImage;
      
      state = state.copyWith(
        images: updatedImages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '图片旋转失败: ${e.toString()}',
      );
    }
  }

  Future<void> processImages() async {
    if (!state.optimizeImages || state.images.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final processedImages = <File>[];
      for (var i = 0; i < state.images.length; i++) {
        final file = state.images[i];
        
        // Backup original if needed
        if (state.keepOriginals) {
          await _imageService.backupOriginal(file);
        }

        // Optimize image
        final optimized = await _imageService.optimizeImage(
          file,
          maxWidth: AppConfig.optimizedImageWidth,
          maxHeight: AppConfig.optimizedImageHeight,
          quality: AppConfig.optimizedImageQuality,
        );
        
        processedImages.add(optimized);
      }

      state = state.copyWith(
        images: processedImages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '图片处理失败: ${e.toString()}',
      );
    }
  }

  void resetZoom() {
    state = state.copyWith(zoomLevel: 1.0);
  }

  void resetRotation() {
    state = state.copyWith(rotation: 0.0);
  }

  Future<void> rotateSelectedImage(bool clockwise) async {
    if (state.selectedImageIndex < 0 || state.selectedImageIndex >= state.images.length) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final angle = clockwise ? 90.0 : -90.0;
      final selectedFile = state.images[state.selectedImageIndex];
      final rotatedFile = await _imageService.rotateImage(
        selectedFile,
        angle.toInt(),
      );
      
      final updatedImages = List<File>.from(state.images);
      updatedImages[state.selectedImageIndex] = rotatedFile;
      
      state = state.copyWith(
        images: updatedImages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '旋转图片失败: ${e.toString()}',
      );
    }
  }

  Future<List<File>> _processImages() async {
    if (!state.optimizeImages || state.images.isEmpty) {
      return state.images;
    }

    final processedImages = <File>[];
    
    for (final file in state.images) {
      if (state.keepOriginals) {
        await _imageService.backupOriginal(file);
      }

      final optimized = await _imageService.optimizeImage(
        file,
        maxWidth: AppConfig.optimizedImageWidth,
        maxHeight: AppConfig.optimizedImageHeight,
        quality: AppConfig.optimizedImageQuality,
      );
      
      processedImages.add(optimized);
    }

    return processedImages;
  }

  Future<bool> importWork() async {
    if (!state.isValid) {
      state = state.copyWith(error: '请填写作品名称并至少添加一张图片');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Process images if needed
      final finalImages = await _processImages();

      // Create work info
      final workInfo = WorkInfo(
        id: "",
        name: state.name,
        author: state.author,
        style: state.style,  // 直接使用，已经是 WorkStyle 类型
        tool: state.tool,    // 直接使用，已经是 WorkTool 类型
        creationDate: state.creationDate,
        remarks: state.remarks,
      );

      // Import work with processed images
      await _workService.importWork(finalImages, workInfo);
      
      // Clear state after successful import
      reset();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '导入失败: ${e.toString()}',
      );
      return false;
    }
  }

  void resetView() {
    state = state.copyWith(
      scale: 1.0,
      rotation: 0.0,
    );
  }

  void moveImage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || 
        oldIndex >= state.images.length ||
        newIndex < 0 || 
        newIndex >= state.images.length) {
      return;
    }

    final updatedImages = List<File>.from(state.images);
    final image = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, image);

    state = state.copyWith(
      images: updatedImages,
      selectedImageIndex: newIndex,
    );
  }

  void reorderImages(int oldIndex, int newIndex) {
    final updatedImages = List<File>.from(state.images);
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);

    state = state.copyWith(
      images: updatedImages,
      selectedImageIndex: newIndex,
    );
  }

  void updateScale(double scale) {
    state = state.copyWith(scale: scale);
  }

  void setScale(double scale) {
    if (scale < 0.5 || scale > 5.0) return;
    state = state.copyWith(scale: scale);
  }

  void reset() {
    state = WorkImportState();
  }
}