import 'package:demo/domain/models/practice/practice_element.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_layer.freezed.dart';
part 'practice_layer.g.dart';

@freezed
class PracticeLayer with _$PracticeLayer {
  const factory PracticeLayer({
    required String id,
    required String name,
    required int order,
    @Default(true) bool isVisible,
    @Default(false) bool isLocked,
    @Default(<PracticeElement>[]) List<PracticeElement> elements,
    @Default(1.0) double opacity,
    String? backgroundImage,
  }) = _PracticeLayer;

  factory PracticeLayer.fromJson(Map<String, dynamic> json) =>
      _$PracticeLayerFromJson(json);
}
