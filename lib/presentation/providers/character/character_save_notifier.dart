import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/services/character/character_persistence_service.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../domain/models/common/result.dart';

final characterSaveNotifierProvider =
    StateNotifierProvider<CharacterSaveNotifier, SaveState>((ref) {
  final persistenceService = ref.watch(characterPersistenceServiceProvider);
  return CharacterSaveNotifier(persistenceService);
});

class CharacterSaveNotifier extends StateNotifier<SaveState> {
  final CharacterPersistenceService _persistenceService;

  CharacterSaveNotifier(this._persistenceService) : super(const SaveState());

  Future<Result<String>> save(
      CharacterRegion region, ProcessingResult result, String workId) async {
    try {
      // 开始保存，更新状态
      state = state.copyWith(isSaving: true, error: null);

      // 调用持久化服务保存
      // 设置workId
      final savedEntity = await _persistenceService.saveCharacter(
        region,
        result,
        workId,
      );

      // 保存成功，更新状态
      state = state.copyWith(isSaving: false);
      return Result.success(savedEntity.id);
    } catch (e) {
      // 保存失败，更新错误状态
      state = state.copyWith(
        isSaving: false,
        error: _getErrorMessage(e),
      );
      return Result.failure(e);
    }
  }

  String _getErrorMessage(Object error) {
    if (error is ValidationError) {
      return '输入验证失败：${error.message}';
    } else if (error is StorageError) {
      return '保存失败：${error.message}';
    } else {
      return '保存失败，请重试';
    }
  }
}

class SaveState {
  final bool isSaving;
  final String? error;

  const SaveState({
    this.isSaving = false,
    this.error,
  });

  SaveState copyWith({
    bool? isSaving,
    String? error,
  }) {
    return SaveState(
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
    );
  }
}
