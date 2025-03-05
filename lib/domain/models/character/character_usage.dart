import 'package:equatable/equatable.dart';

class CharacterUsage extends Equatable {
  final String practiceId;

  const CharacterUsage({
    required this.practiceId,
  });

  factory CharacterUsage.fromJson(Map<String, dynamic> json) {
    return CharacterUsage(
      practiceId: json['practiceId'] as String,
    );
  }

  @override
  List<Object?> get props => [practiceId];

  CharacterUsage copyWith({
    String? practiceId,
  }) {
    return CharacterUsage(
      practiceId: practiceId ?? this.practiceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
    };
  }
}
