import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../domain/models/character/character_entity.dart';

/// 角色详情提供者
final characterDetailProvider =
    FutureProvider.family<CharacterEntity?, String>((ref, id) async {
  final repository = ref.watch(characterRepositoryProvider);
  return repository.get(id);
});

/// 角色服务提供者
// final characterServiceProvider = Provider<CharacterService>((ref) {
//   return CharacterService(
//     repository: ref.watch(characterRepositoryProvider),
//   );
// });
