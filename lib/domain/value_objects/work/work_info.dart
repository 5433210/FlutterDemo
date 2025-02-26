import '../../enums/work_style.dart';
import '../../enums/work_tool.dart';
import 'image_info.dart';

class WorkInfo {
  String? id;
  String? author;
  WorkStyle? style;
  WorkTool? tool;
  DateTime? creationDate;
  DateTime? createTime;
  DateTime? updateTime;
  List<String> tags;
  List<WorkImageInfo> images;
  WorkImageInfo? coverImage;
  String? remarks;
  int imageCount;
  String? name;

  WorkInfo({
    this.id,
    this.name,
    this.author,
    this.style,
    this.tool,
    this.creationDate,
    this.createTime,
    this.updateTime,
    this.tags = const [],
    this.images = const [],
    this.coverImage,
    this.remarks,
    this.imageCount = 0,
  });

  factory WorkInfo.fromJson(Map<String, dynamic> json) => WorkInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        author: json['author'] as String?,
        style: json['style'] != null
            ? WorkStyle.values
                .firstWhere((e) => e.toString() == 'WorkStyle.${json['style']}')
            : null,
        tool: json['tool'] != null
            ? WorkTool.values
                .firstWhere((e) => e.toString() == 'WorkTool.${json['tool']}')
            : null,
        creationDate: json['creationDate'] != null
            ? DateTime.parse(json['creationDate'] as String)
            : null,
        createTime: DateTime.parse(json['createTime'] as String),
        updateTime: DateTime.parse(json['updateTime'] as String),
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        images: (json['images'] as List?)
                ?.map((e) => WorkImageInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        coverImage: json['coverImage'] != null
            ? WorkImageInfo.fromJson(json['coverImage'] as Map<String, dynamic>)
            : null,
        remarks: json['remarks'] as String?,
        imageCount: json['imageCount'] as int? ?? 0,
      );

  WorkInfo copyWith({
    String? id,
    String? name,
    String? author,
    WorkStyle? style,
    WorkTool? tool,
    DateTime? creationDate,
    DateTime? createTime,
    DateTime? updateTime,
    List<String>? tags,
    List<WorkImageInfo>? images,
    WorkImageInfo? coverImage,
    String? remarks,
    int? imageCount,
  }) =>
      WorkInfo(
        id: id ?? this.id,
        name: name ?? this.name,
        author: author ?? this.author,
        style: style ?? this.style,
        tool: tool ?? this.tool,
        creationDate: creationDate ?? this.creationDate,
        createTime: createTime ?? this.createTime,
        updateTime: updateTime ?? this.updateTime,
        tags: tags ?? this.tags,
        images: images ?? this.images,
        coverImage: coverImage ?? this.coverImage,
        remarks: remarks ?? this.remarks,
        imageCount: imageCount ?? this.imageCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'author': author,
        'style': style,
        'tool': tool,
        'creationDate': creationDate?.toIso8601String(),
        'createTime': createTime?.toIso8601String(),
        'updateTime': updateTime?.toIso8601String(),
        'tags': tags,
        'images': images.map((i) => i.toJson()).toList(),
        'coverImage': coverImage?.toJson(),
        'remarks': remarks,
        'imageCount': imageCount,
      }..removeWhere((_, value) => value == null);
}
