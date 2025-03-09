import 'package:freezed_annotation/freezed_annotation.dart';

part 'size.freezed.dart';
part 'size.g.dart';

@freezed
class Size with _$Size {
  const factory Size({
    required int width,
    required int height,
  }) = _Size;

  factory Size.create({
    required int width,
    required int height,
  }) {
    return Size(
      width: width,
      height: height,
    );
  }

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);

  const Size._();
}
