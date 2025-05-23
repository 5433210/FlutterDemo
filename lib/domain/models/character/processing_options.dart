import 'package:freezed_annotation/freezed_annotation.dart';

part 'processing_options.freezed.dart';
part 'processing_options.g.dart';

@freezed
class ProcessingOptions with _$ProcessingOptions {
  const factory ProcessingOptions({
    @Default(false) bool inverted,
    @Default(false) bool showContour,
    @Default(128.0) double threshold,
    @Default(0.0) double noiseReduction,
    @Default(10.0) double brushSize,
    @Default(1.0) double contrast,
    @Default(0.0) double brightness,
  }) = _ProcessingOptions;

  factory ProcessingOptions.fromJson(Map<String, dynamic> json) =>
      _$ProcessingOptionsFromJson(json);
}
