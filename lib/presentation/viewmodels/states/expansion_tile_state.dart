import 'package:freezed_annotation/freezed_annotation.dart';

part 'expansion_tile_state.freezed.dart';

/// ExpansionTile 状态模型
/// 用于管理应用中所有 ExpansionTile 的展开/折叠状态
@freezed
class ExpansionTileState with _$ExpansionTileState {
  const factory ExpansionTileState({
    /// 所有 ExpansionTile 的状态映射
    /// key: 唯一标识符，value: 是否展开
    @Default(<String, bool>{}) Map<String, bool> tileStates,
  }) = _ExpansionTileState;

  /// 初始状态
  factory ExpansionTileState.initial() => const ExpansionTileState();
}
