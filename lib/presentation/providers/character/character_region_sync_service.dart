import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../viewmodels/states/character_collection_state.dart';
import 'character_collection_provider.dart';
import 'character_save_notifier.dart';

/// 提供Character与Region同步服务
final characterRegionSyncServiceProvider =
    Provider<CharacterRegionSyncService>((ref) {
  return CharacterRegionSyncService(ref);
});

/// Character与Region同步服务
/// 处理Character保存状态与Region保存状态的同步
class CharacterRegionSyncService {
  final Ref _ref;

  CharacterRegionSyncService(this._ref) {
    // 监听Character的保存状态 (注释掉或移除此监听)
    /*
    _ref.listen(characterSaveNotifierProvider, (previous, next) {
      _handleCharacterSaveStateChange(previous, next);
    });
    */

    // 监听Region的修改状态
    _ref.listen(characterCollectionProvider, (previous, next) {
      _handleRegionModificationStateChange(
          previous as CharacterCollectionState?, next);
    });

    AppLogger.debug('CharacterRegionSyncService initialized');
  }

  /// 处理Character保存状态变化
  /* (注释掉或移除此方法)
  void _handleCharacterSaveStateChange(SaveState? previous, SaveState next) {
    if (previous?.isSaving == true &&
        next.isSaving == false &&
        next.error == null) {
      // 保存成功，更新对应的Region状态
      final characterId =
          _ref.read(characterSaveNotifierProvider).lastSavedCharacterId;

      AppLogger.debug('Character保存状态变化', data: {
        'previousIsSaving': previous?.isSaving,
        'nextIsSaving': next.isSaving,
        'lastSavedCharacterId': characterId,
      });

      if (characterId == null) return;

      // 找到对应的Region
      final regionWithCharacter = _findRegionByCharacterId(characterId);
      if (regionWithCharacter != null) {
        AppLogger.debug('找到关联的Region，标记为已保存', data: {
          'regionId': regionWithCharacter.id,
          'characterId': characterId,
          'previousIsSaved': regionWithCharacter.isSaved,
        });

        // 标记为已保存
        _ref
            .read(characterCollectionProvider.notifier)
            .markAsSaved(regionWithCharacter.id);
        
        // 强制刷新UI
        Future.microtask(() {
          // 使用微任务确保在当前构建周期后刷新
          final notifier = _ref.read(characterCollectionProvider.notifier);
          // 通过重新应用当前状态强制触发刷新
          final currentState = _ref.read(characterCollectionProvider);
          notifier.state = currentState.copyWith();
          AppLogger.debug('已触发UI刷新以更新保存状态', data: {
            'regionId': regionWithCharacter.id,
          });
        });
      } else {
        AppLogger.warning('无法找到关联的Region', data: {
          'characterId': characterId,
        });
      }
    }
  }
  */

  /// 处理Region修改状态变化
  void _handleRegionModificationStateChange(
      CharacterCollectionState? previous, CharacterCollectionState next) {
    // 检测新增的修改项
    final previousModifiedIds = previous?.modifiedIds ?? {};
    final currentModifiedIds = next.modifiedIds;

    final newlyModifiedIds = {...currentModifiedIds}
      ..removeAll(previousModifiedIds);

    AppLogger.debug('Region修改状态变化', data: {
      'previousModifiedCount': previousModifiedIds.length,
      'currentModifiedCount': currentModifiedIds.length,
      'newlyModifiedCount': newlyModifiedIds.length,
    });

    if (newlyModifiedIds.isNotEmpty) {
      // 有新的修改区域，需要同步到Character状态
      for (final regionId in newlyModifiedIds) {
        final region = _findRegionById(regionId, next.regions);
        if (region?.characterId != null) {
          AppLogger.debug('Region被修改，需要更新Character状态', data: {
            'regionId': regionId,
            'characterId': region!.characterId,
          });

          // 通知Character需要重新保存
          _markCharacterAsModified(region.characterId!);
        }
      }
    }
  }

  /// 根据ID查找Region
  CharacterRegion? _findRegionById(
      String regionId, List<CharacterRegion> regions) {
    try {
      return regions.firstWhere((r) => r.id == regionId);
    } catch (e) {
      return null;
    }
  }

  /// 根据CharacterId查找Region
  CharacterRegion? _findRegionByCharacterId(String characterId) {
    final regions = _ref.read(characterCollectionProvider).regions;
    try {
      return regions.firstWhere((r) => r.characterId == characterId);
    } catch (e) {
      return null;
    }
  }

  /// 将Character标记为已修改需要保存
  void _markCharacterAsModified(String characterId) {
    // 这里需要实际调用Character相关的Provider
    // 示例：ref.read(characterEditProvider.notifier).markAsModified(characterId);
    AppLogger.debug('Character被标记为已修改', data: {
      'characterId': characterId,
    });
  }
}
