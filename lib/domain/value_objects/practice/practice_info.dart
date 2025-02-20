import 'page_info.dart';

class PracticeInfo {
  final String id;
  final String title;
  final String status;
  final List<PageInfo> pages;
  final List<String> tags;
  final DateTime createTime;
  final DateTime updateTime;

   PracticeInfo({
    required this.id,
    required this.title,
    required this.status,
    required this.pages,
    required this.createTime,
    required this.updateTime,
    this.tags = const [],
  }) {
    if (title.isEmpty || title.length > 100) {
      throw ArgumentError('Title must be between 1 and 100 characters');
    }
    if (!['draft', 'completed'].contains(status)) {
      throw ArgumentError('Status must be draft or completed');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'pages': pages.map((p) => p.toJson()).toList(),
    'tags': tags,
    'createTime': createTime.toIso8601String(),
    'updateTime': updateTime.toIso8601String(),
  };

  factory PracticeInfo.fromJson(Map<String, dynamic> json) => PracticeInfo(
    id: json['id'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    pages: (json['pages'] as List)
        .map((p) => PageInfo.fromJson(p as Map<String, dynamic>))
        .toList(),
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    createTime: DateTime.parse(json['createTime'] as String),
    updateTime: DateTime.parse(json['updateTime'] as String),
  );
}
