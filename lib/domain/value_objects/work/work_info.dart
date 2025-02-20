import 'image_info.dart';

class WorkInfo {
  final String? style;
  final String? tool;
  final DateTime? creationDate;
  final List<String> tags;
  final List<WorkImageInfo> images;
  final String? remarks;
  final int imageCount;

  const WorkInfo({
    this.style,
    this.tool,
    this.creationDate,
    this.tags = const [],
    this.images = const [],
    this.remarks,
    this.imageCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'style': style,
    'tool': tool,
    'creationDate': creationDate?.toIso8601String(),
    'tags': tags,
    'images': images.map((i) => i.toJson()).toList(),
    'remarks': remarks,
    'imageCount': imageCount,
  }..removeWhere((_, value) => value == null);

  factory WorkInfo.fromJson(Map<String, dynamic> json) => WorkInfo(
    style: json['style'] as String?,
    tool: json['tool'] as String?,
    creationDate: json['creationDate'] != null 
        ? DateTime.parse(json['creationDate'] as String)
        : null,
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    images: (json['images'] as List?)
        ?.map((e) => WorkImageInfo.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    remarks: json['remarks'] as String?,
    imageCount: json['imageCount'] as int? ?? 0,
  );
}