import 'package:equatable/equatable.dart';

import '../entities/character.dart';

/// 表示已采集的汉字
class CollectedCharacter extends Equatable {
  final String id;
  final String character; // 汉字
  final String style; // 书法风格
  final String tool; // 书写工具
  final String workId; // 来源作品ID
  final String workName; // 来源作品名称
  final String image; // 汉字图片路径
  final Map<String, dynamic> region; // 在原作中的区域信息
  final DateTime createTime;

  const CollectedCharacter({
    required this.id,
    required this.character,
    required this.style,
    required this.tool,
    required this.workId,
    required this.workName,
    required this.image,
    required this.region,
    required this.createTime,
  });

  /// 从Character实体创建CollectedCharacter
  factory CollectedCharacter.fromCharacter(Character character) {
    final metadata = character.metadata ?? {};
    return CollectedCharacter(
      id: character.id!,
      character: character.char,
      style: metadata['style'] ?? '',
      tool: metadata['tool'] ?? '',
      workId: character.workId ?? '',
      workName: character.workName ?? '',
      image: character.image ?? '',
      region: character.sourceRegion ?? {},
      createTime: character.createTime ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        character,
        style,
        tool,
        workId,
        workName,
        image,
        region,
        createTime,
      ];

  // 将CollectedCharacter转换为Character实体
  Character toCharacter() {
    return Character(
      id: id,
      char: character,
      workId: workId,
      workName: workName,
      image: image,
      sourceRegion: region,
      createTime: createTime,
      metadata: {
        'style': style,
        'tool': tool,
      },
    );
  }
}
