import 'dart:convert';

class Work {
  final String id;
  final String name;
  final String? author;
  final String? style;
  final String? tool;
  final DateTime? creationDate;
  final DateTime createTime;
  final DateTime updateTime;
  final Map<String, dynamic>? metadata;

  Work({
    required this.id,
    required this.name,
    this.author,
    this.style,
    this.tool,
    this.creationDate,
    required this.createTime,
    required this.updateTime,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'style': style,
      'tool': tool,
      'creation_date': creationDate?.millisecondsSinceEpoch,
      'create_time': createTime.millisecondsSinceEpoch,
      'update_time': updateTime.millisecondsSinceEpoch,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  static Work fromMap(Map<String, dynamic> map) {
    return Work(
      id: map['id'],
      name: map['name'],
      author: map['author'],
      style: map['style'],
      tool: map['tool'],
      creationDate: map['creation_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['creation_date'])
          : null,
      createTime: DateTime.fromMillisecondsSinceEpoch(map['create_time']),
      updateTime: DateTime.fromMillisecondsSinceEpoch(map['update_time']),
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    );
  }

  Work copyWith({
    String? id,
    String? name,
    String? author,
    String? style,
    String? tool,
    DateTime? creationDate,
    DateTime? createTime,
    DateTime? updateTime,
    Map<String, dynamic>? metadata,
  }) {
    return Work(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      creationDate: creationDate ?? this.creationDate,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      metadata: metadata ?? this.metadata,
    );
  }
}