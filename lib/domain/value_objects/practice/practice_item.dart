import 'dart:convert';

import 'package:equatable/equatable.dart';

/// An item in a practice page
class PracticeItem extends Equatable {
  final String id;
  final PracticeItemType type;
  final Map<String, dynamic> properties;

  const PracticeItem({
    required this.id,
    required this.type,
    required this.properties,
  });

  /// Create a character practice item
  factory PracticeItem.character({
    required String id,
    required String characterId,
    required String char,
    String? imagePath,
  }) {
    return PracticeItem(
      id: id,
      type: PracticeItemType.character,
      properties: {
        'characterId': characterId,
        'char': char,
        'imagePath': imagePath,
      },
    );
  }

  /// Create from JSON map (alias for fromMap for JSON deserialization)
  factory PracticeItem.fromJson(Map<String, dynamic> json) =>
      PracticeItem.fromMap(json);

  /// Create an instance from a JSON string
  factory PracticeItem.fromJsonString(String jsonString) {
    return PracticeItem.fromMap(
        json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Create an instance from a map
  factory PracticeItem.fromMap(Map<String, dynamic> map) {
    return PracticeItem(
      id: map['id'] as String,
      type: PracticeItemType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => PracticeItemType.text,
      ),
      properties: Map<String, dynamic>.from(map['properties'] as Map),
    );
  }

  /// Create an image practice item
  factory PracticeItem.image({
    required String id,
    required String imagePath,
    double? width,
    double? height,
  }) {
    return PracticeItem(
      id: id,
      type: PracticeItemType.image,
      properties: {
        'imagePath': imagePath,
        'width': width,
        'height': height,
      },
    );
  }

  /// Create a text practice item
  factory PracticeItem.text({
    required String id,
    required String text,
    String? style,
  }) {
    return PracticeItem(
      id: id,
      type: PracticeItemType.text,
      properties: {
        'text': text,
        'style': style,
      },
    );
  }

  @override
  List<Object?> get props => [id, type, properties];

  PracticeItem copyWith({
    String? id,
    PracticeItemType? type,
    Map<String, dynamic>? properties,
  }) {
    return PracticeItem(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
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
      'type': type.toString().split('.').last,
      'properties': properties,
    };
  }
}

/// Item type in a practice session
enum PracticeItemType {
  character,
  image,
  text,
}
