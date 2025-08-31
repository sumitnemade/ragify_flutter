import 'package:json_annotation/json_annotation.dart';

part 'relevance_score.g.dart';

/// Represents a relevance score with confidence interval
@JsonSerializable()
class RelevanceScore {
  /// Relevance score between 0.0 and 1.0
  final double score;

  /// Lower bound of confidence interval
  @JsonKey(name: 'confidence_lower')
  final double? confidenceLower;

  /// Upper bound of confidence interval
  @JsonKey(name: 'confidence_upper')
  final double? confidenceUpper;

  /// Confidence level (0.0 to 1.0)
  @JsonKey(name: 'confidence_level')
  final double confidenceLevel;

  const RelevanceScore({
    required this.score,
    this.confidenceLower,
    this.confidenceUpper,
    this.confidenceLevel = 0.95,
  }) : assert(
         score >= 0.0 && score <= 1.0,
         'Score must be between 0.0 and 1.0',
       );

  /// Create from JSON
  factory RelevanceScore.fromJson(Map<String, dynamic> json) =>
      _$RelevanceScoreFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RelevanceScoreToJson(this);

  /// Create a copy with updated fields
  RelevanceScore copyWith({
    double? score,
    double? confidenceLower,
    double? confidenceUpper,
    double? confidenceLevel,
  }) {
    return RelevanceScore(
      score: score ?? this.score,
      confidenceLower: confidenceLower ?? this.confidenceLower,
      confidenceUpper: confidenceUpper ?? this.confidenceUpper,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    );
  }

  /// Check if the score is above a threshold
  bool isAboveThreshold(double threshold) => score >= threshold;

  /// Get the confidence interval width
  double? get confidenceIntervalWidth {
    if (confidenceLower != null && confidenceUpper != null) {
      return confidenceUpper! - confidenceLower!;
    }
    return null;
  }

  /// Get a string representation of the confidence interval
  String get confidenceIntervalString {
    if (confidenceLower != null && confidenceUpper != null) {
      return '${confidenceLower!.toStringAsFixed(3)} - ${confidenceUpper!.toStringAsFixed(3)}';
    }
    return 'N/A';
  }

  @override
  String toString() {
    return 'RelevanceScore(score: ${score.toStringAsFixed(3)}, confidence: $confidenceIntervalString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelevanceScore &&
        other.score == score &&
        other.confidenceLower == confidenceLower &&
        other.confidenceUpper == confidenceUpper &&
        other.confidenceLevel == confidenceLevel;
  }

  @override
  int get hashCode =>
      Object.hash(score, confidenceLower, confidenceUpper, confidenceLevel);
}
