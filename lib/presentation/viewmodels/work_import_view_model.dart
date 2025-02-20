import 'dart:convert';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../application/config/app_config.dart';
import '../../application/services/work_service.dart';
import '../../application/services/image_service.dart';
import 'states/work_import_state.dart';

class WorkImportViewModel extends StateNotifier<WorkImportState> {
  final WorkService _workService;
  final ImageService _imageService;

  WorkImportViewModel(this._workService, this._imageService) 
      : super(const WorkImportState());

  Future<void> addImages(List<File> files) async {
    try {
      // Check max count
      if (state.images.length + files.length > AppConfig.maxImagesPerWork) {
        throw Exception('最多只能添加${AppConfig.maxImagesPerWork}张图片');
      }

      state = state.copyWith(isLoading: true, error: null);

      for (final file in files) {
        // Check file size
        final size = await file.length();
        if (size > AppConfig.maxImageSize) {
          throw Exception('图片大小不能超过${AppConfig.maxImageSize ~/ 1024 ~/ 1024}MB');
        }

        // Check file format
        final ext = path.extension(file.path).toLowerCase().replaceAll('.', '');
        if (!AppConfig.supportedImageFormats.contains(ext)) {
          throw Exception('不支持的图片格式: $ext');
        }

        // Verify image can be decoded
        final bytes = await file.readAsBytes();
        final image = await decodeImageFromList(bytes);
        
        // Check dimensions
        if (image.width > AppConfig.maxImageWidth || 
            image.height > AppConfig.maxImageHeight) {
          throw Exception('图片尺寸不能超过 ${AppConfig.maxImageWidth}x'
              '${AppConfig.maxImageHeight}');
        }
      }

      // Add validated files
      final updatedImages = [...state.images, ...files];
      state = state.copyWith(
        images: updatedImages,
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
    final updatedIndex = state.selectedImageIndex >= updatedImages.length 
        ? updatedImages.isEmpty ? 0 : updatedImages.length - 1
        : state.selectedImageIndex;

    state = state.copyWith(
      images: updatedImages,
      selectedImageIndex: updatedIndex,
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

  void updateStyle(String? style) {
    state = state.copyWith(style: style);
  }

  void updateTool(String? tool) {
    state = state.copyWith(tool: tool);
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

  Future<bool> importWork() async {
    if (!state.isValid) {
      state = state.copyWith(
        error: '请填写作品名称并至少添加一张图片',
      );
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Process images
      final processedImages = await _imageService.processWorkImages(
        state.images,
        optimize: state.optimizeImages,
        keepOriginals: state.keepOriginals,
      );

      // Create work
      final workData = {
        'name': state.name,
        'author': state.author,
        'style': state.style,
        'tool': state.tool,
        'creationDate': state.creationDate?.toIso8601String(),
        'remarks': state.remarks,
        'images': processedImages,
      };
      await _workService.createWork(jsonEncode(workData));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}