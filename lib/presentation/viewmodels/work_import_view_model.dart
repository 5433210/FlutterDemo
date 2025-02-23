import 'dart:io';
import 'package:demo/domain/value_objects/work/work_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  WorkImportViewModel(this._workService, this._imageService) 
      : super(const WorkImportState());

  // 基础信息设置
  void setName(String name) => state = state.copyWith(name: name.trim());
  void setAuthor(String author) => state = state.copyWith(author: author.trim());
  void setRemarks(String remarks) => state = state.copyWith(remarks: remarks.trim());
  void setCreationDate(DateTime? date) => state = state.copyWith(creationDate: date);

  // 枚举值设置
  void setTool(String? value) {
    if (value?.isEmpty ?? true) return;
    
    try {
      final enumValue = value!.trim();
      final tool = WorkTool.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == enumValue.toLowerCase(),
        orElse: () => throw Exception('未知的书写工具: $value'),
      );
      state = state.copyWith(tool: tool);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('Error setting tool: $e');
    }
  }

  void setStyle(String? value) {
    if (value?.isEmpty ?? true) return;
    
    try {
      final enumValue = value!.trim();
      final style = WorkStyle.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == enumValue.toLowerCase(),
        orElse: () => throw Exception('未知的书法风格: $value'),
      );
      state = state.copyWith(style: style);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('Error setting style: $e');
    }
  }

  // 图片操作
  Future<void> addImages(List<File> files) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _validateImages(files);
      final updatedImages = List<File>.from(state.images)..addAll(files);
      
      state = state.copyWith(
        images: updatedImages,
        selectedImageIndex: state.selectedImageIndex < 0 ? 0 : state.selectedImageIndex,
        isLoading: false,
      );
      HapticFeedback.mediumImpact();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _validateImages(List<File> files) async {
    if (files.isEmpty) {
      throw Exception('请选择需要导入的图片');
    }

    for (final file in files) {
      final ext = path.extension(file.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
        throw Exception('不支持的文件类型: $ext\n支持的格式：jpg、jpeg、png、webp');
      }
      
      final size = await file.length();
      if (size > AppConfig.maxImageSize) {
        throw Exception(
          '文件过大：${path.basename(file.path)}\n'
          '大小：${(size / 1024 / 1024).toStringAsFixed(1)}MB\n'
          '限制：${(AppConfig.maxImageSize / 1024 / 1024).toStringAsFixed(0)}MB'
        );
      }
    }
  }

  void removeImage(int index) {
    if (!_isValidIndex(index)) return;

    final updatedImages = List<File>.from(state.images)..removeAt(index);
    final updatedRotations = Map<String, double>.from(state.imageRotations)
      ..remove(state.images[index].path);

    final newSelectedIndex = _calculateNewSelectedIndex(index, updatedImages.length);

    state = state.copyWith(
      images: updatedImages,
      selectedImageIndex: newSelectedIndex,
      imageRotations: updatedRotations,
      error: null,
    );
    HapticFeedback.lightImpact();
  }

  bool _isValidIndex(int index) => index >= 0 && index < state.images.length;

  void selectImage(int index) {
    if (index >= 0 && index < state.images.length) {
      state = state.copyWith(selectedImageIndex: index);
    }
  }

  Future<void> rotateImage(bool clockwise) async {
    if (state.selectedImageIndex < 0) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final angle = clockwise ? 90 : -90;
      final selectedFile = state.images[state.selectedImageIndex];
      final rotatedFile = await _imageService.rotateImage(selectedFile, angle);
      
      final updatedImages = List<File>.from(state.images);
      updatedImages[state.selectedImageIndex] = rotatedFile;

      final updatedRotations = Map<String, double>.from(state.imageRotations);
      updatedRotations[rotatedFile.path] = 
          ((updatedRotations[selectedFile.path] ?? 0 + angle) % 360).toDouble();

      state = state.copyWith(
        images: updatedImages,
        imageRotations: updatedRotations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '旋转图片失败: ${e.toString()}',
      );
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (!_isValidIndex(oldIndex) || !_isValidIndex(newIndex)) return;

    HapticFeedback.selectionClick();

    if (oldIndex < newIndex) newIndex--;

    final updatedImages = List<File>.from(state.images);
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);

    final newSelectedIndex = _calculateNewSelectedIndex(oldIndex, newIndex);

    state = state.copyWith(
      images: updatedImages,
      selectedImageIndex: newSelectedIndex,
      imageRotations: state.imageRotations,
      error: null,
    );
  }

  int _calculateNewSelectedIndex(int oldIndex, int newIndex) {
    if (state.selectedImageIndex == oldIndex) {
      return newIndex;
    }
    if (state.selectedImageIndex > oldIndex && state.selectedImageIndex <= newIndex) {
      return state.selectedImageIndex - 1;
    }
    if (state.selectedImageIndex < oldIndex && state.selectedImageIndex >= newIndex) {
      return state.selectedImageIndex + 1;
    }
    return state.selectedImageIndex;
  }

  // 视图控制
  void setScale(double scale) {
    if (scale >= 0.5 && scale <= 5.0) {
      state = state.copyWith(scale: scale);
    }
  }

  void resetView() {
    state = state.copyWith(scale: 1.0, rotation: 0.0);
  }

  // 优化选项
  void toggleOptimizeImages() {
    state = state.copyWith(optimizeImages: !state.optimizeImages);
  }

  void toggleKeepOriginals() {
    state = state.copyWith(keepOriginals: !state.keepOriginals);
  }

  Future<List<File>> _processImages() async {
    if (!state.optimizeImages || state.images.isEmpty) {
      return state.images;
    }

    try {
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
    } catch (e) {
      throw Exception('图片处理失败: ${e.toString()}');
    }
  }

  // 导入功能
  Future<bool> importWork() async {
    if (state.images.isEmpty ||
        state.name.isEmpty ||
        state.author?.isEmpty != false ||
        state.style == null ||
        state.tool == null ||
        state.creationDate == null) {
      state = state.copyWith(error: '请填写所有必填字段');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final processedImages = await _processImages();
      
      await _workService.importWork(
        processedImages,
        WorkInfo(
          name: state.name,
          author: state.author,
          style: state.style!,
          tool: state.tool!,
          creationDate: state.creationDate!,
          remarks: state.remarks,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = const WorkImportState();
  }

  void removeAllImages() {
    state = state.copyWith(
      images: const [],
      selectedImageIndex: -1,      
    );
  }
}