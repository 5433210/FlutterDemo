import 'package:freezed_annotation/freezed_annotation.dart';

import 'char_element.dart';
import 'image_element.dart';
import 'text_element.dart';

part 'element_content.freezed.dart';
part 'element_content.g.dart';

/// 元素内容基类
@freezed
class ElementContent with _$ElementContent {
  /// 字符内容
  @FreezedUnionValue('chars')
  const factory ElementContent.chars({
    /// 字符列表
    @Default([]) List<CharElement> chars,
  }) = CharsContent;

  /// 从JSON创建实例
  factory ElementContent.fromJson(Map<String, dynamic> json) =>
      _$ElementContentFromJson(json);

  /// 图片内容
  @FreezedUnionValue('image')
  const factory ElementContent.image({
    /// 图片对象
    required ImageElement image,
  }) = ImageContent;

  /// 文本内容
  @FreezedUnionValue('text')
  const factory ElementContent.text({
    /// 文本对象
    required TextElement text,
  }) = TextContent;

  const ElementContent._();

  /// 获取内容类型
  String get type => map(
        chars: (_) => 'chars',
        image: (_) => 'image',
        text: (_) => 'text',
      );

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...map(
        chars: (content) => {
          'chars': content.chars.map((e) => e.toJson()).toList(),
        },
        image: (content) => {
          'image': content.image.toJson(),
        },
        text: (content) => {
          'text': content.text.toJson(),
        },
      ),
    };
  }
}

/// CharsContent 扩展方法
extension CharsContentX on CharsContent {
  /// 添加字符
  CharsContent addChar(CharElement char) {
    return copyWith(chars: [...chars, char]);
  }

  /// 清空字符
  CharsContent clearChars() {
    return copyWith(chars: const []);
  }

  /// 移除字符
  CharsContent removeChar(String id) {
    return copyWith(
      chars: chars.where((c) => c.charId != id).toList(),
    );
  }

  /// 更新字符
  CharsContent updateChar(CharElement char) {
    return copyWith(
      chars: chars.map((c) => c.charId == char.charId ? char : c).toList(),
    );
  }
}
