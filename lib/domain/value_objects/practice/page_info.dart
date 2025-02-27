import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'practice_item.dart';

/// A page in a practice session
class PracticePageInfo extends Equatable {
  final String id;
  final String title;
  final List<PracticeItem> items;
  final DateTime createdAt;

  const PracticePageInfo({
    required this.id,
    required this.title,
    required this.items,
    required this.createdAt,
  });

  /// Create from JSON map (alias for fromMap for JSON deserialization)
  factory PracticePageInfo.fromJson(Map<String, dynamic> json) =>
      PracticePageInfo.fromMap(json);

  /// Create an instance from a JSON string
  factory PracticePageInfo.fromJsonString(String jsonString) {
    return PracticePageInfo.fromMap(
        json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Create an instance from a map
  factory PracticePageInfo.fromMap(Map<String, dynamic> map) {
    return PracticePageInfo(
      id: map['id'] as String,
      title: map['title'] as String,
      items: (map['items'] as List)
          .map((item) => PracticeItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  @override
  List<Object?> get props => [id, title, items, createdAt];

  PracticePageInfo copyWith({
    String? id,
    String? title,
    List<PracticeItem>? items,
    DateTime? createdAt,
  }) {
    return PracticePageInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON map (alias for toMap for JSON serialization)
  Map<String, dynamic> toJson() => toMap();

  /// Convert to a JSON string
  String toJsonString() => json.encode(toMap());

  /// Convert to a map for persistence
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
