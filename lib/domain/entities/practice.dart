import 'dart:convert';

class Practice {
  final String id;
  final String title;
  final List<Map<String, dynamic>> pages;
  final Map<String, dynamic>? metadata;
  final DateTime createTime;
  final DateTime updateTime;

  Practice({
    required this.id,
    required this.title,
    required this.pages,
    this.metadata,
    required this.createTime,
    required this.updateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pages': jsonEncode(pages),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'create_time': createTime.millisecondsSinceEpoch,
      'update_time': updateTime.millisecondsSinceEpoch,
    };
  }

  static Practice fromMap(Map<String, dynamic> map) {
    return Practice(
      id: map['id'],
      title: map['title'],
      pages: List<Map<String, dynamic>>.from(
        jsonDecode(map['pages']).map((x) => Map<String, dynamic>.from(x))
      ),
      metadata: map['metadata'] != null 
          ? jsonDecode(map['metadata']) 
          : null,
      createTime: DateTime.fromMillisecondsSinceEpoch(map['create_time']),
      updateTime: DateTime.fromMillisecondsSinceEpoch(map['update_time']),
    );
  }
}

