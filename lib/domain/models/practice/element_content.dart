import 'package:freezed_annotation/freezed_annotation.dart';

import 'char_element.dart';
import 'image_element.dart';
import 'text_element.dart';

part 'element_content.freezed.dart';
part 'element_content.g.dart';

/// 元素内容基类
@unfreezed
class ElementContent with _$ElementContent {
  /// 字符内容
  @FreezedUnionValue('chars')
  factory ElementContent.chars({
    /// 字符列表
    @Default([]) List<CharElement> chars,
  }) = CharsContent;

  /// 从JSON创建实例
  factory ElementContent.fromJson(Map<String, dynamic> json) =>
      _$ElementContentFromJson(json);

  /// 图片内容
  @FreezedUnionValue('image')
  factory ElementContent.image({
    /// 图片对象
    required ImageElement image,
  }) = ImageContent;

  /// 文本内容
  @FreezedUnionValue('text')
  factory ElementContent.text({
    /// 文本对象
    required TextElement text,
  }) = TextContent;

  const ElementContent._();
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
