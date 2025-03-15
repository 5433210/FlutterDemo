import "package:equatable/equatable.dart";

class ProcessingOptions extends Equatable {
  final bool inverted;
  final bool showContour;
  final double threshold;
  final double noiseReduction;
  final bool removeBg;

  const ProcessingOptions({
    this.inverted = false,
    this.showContour = false,
    this.threshold = 0.5,
    this.noiseReduction = 0.5,
    this.removeBg = true,
  });

  factory ProcessingOptions.fromJson(Map<String, dynamic> json) {
    return ProcessingOptions(
      inverted: json["inverted"] as bool? ?? false,
      showContour: json["showContour"] as bool? ?? false,
      threshold: (json["threshold"] as num?)?.toDouble() ?? 0.5,
      noiseReduction: (json["noiseReduction"] as num?)?.toDouble() ?? 0.5,
      removeBg: json["removeBg"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "inverted": inverted,
      "showContour": showContour,
      "threshold": threshold,
      "noiseReduction": noiseReduction,
      "removeBg": removeBg,
    };
  }

  ProcessingOptions copyWith({
    bool? inverted,
    bool? showContour,
    double? threshold,
    double? noiseReduction,
    bool? removeBg,
  }) {
    return ProcessingOptions(
      inverted: inverted ?? this.inverted,
      showContour: showContour ?? this.showContour,
      threshold: threshold ?? this.threshold,
      noiseReduction: noiseReduction ?? this.noiseReduction,
      removeBg: removeBg ?? this.removeBg,
    );
  }

  @override
  List<Object?> get props => [inverted, showContour, threshold, noiseReduction, removeBg];
}
