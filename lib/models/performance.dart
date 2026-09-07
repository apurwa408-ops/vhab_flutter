class PerformanceMetric {
  final double accuracy;
  final double completionPercentage;
  final int timeTakenSeconds;
  final int successfulAttempts;
  final int failedAttempts;
  final int reactionTimeMs;
  final double stabilityScore;
  final double precisionScore;
  final double speedScore;
  final DateTime timestamp;

  const PerformanceMetric({
    required this.accuracy,
    required this.completionPercentage,
    required this.timeTakenSeconds,
    required this.successfulAttempts,
    required this.failedAttempts,
    this.reactionTimeMs = 450,
    this.stabilityScore = 85.0,
    this.precisionScore = 85.0,
    this.speedScore = 80.0,
    required this.timestamp,
  });

  int get stars {
    if (accuracy >= 90 && completionPercentage >= 90) return 5;
    if (accuracy >= 80) return 4;
    if (accuracy >= 70) return 3;
    if (accuracy >= 50) return 2;
    return 1;
  }

  String get formattedTime {
    final minutes = (timeTakenSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeTakenSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'completionPercentage': completionPercentage,
        'timeTakenSeconds': timeTakenSeconds,
        'successfulAttempts': successfulAttempts,
        'failedAttempts': failedAttempts,
        'reactionTimeMs': reactionTimeMs,
        'stabilityScore': stabilityScore,
        'precisionScore': precisionScore,
        'speedScore': speedScore,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      completionPercentage:
          (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      successfulAttempts: (json['successfulAttempts'] as num?)?.toInt() ?? 0,
      failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
      reactionTimeMs: (json['reactionTimeMs'] as num?)?.toInt() ?? 450,
      stabilityScore: (json['stabilityScore'] as num?)?.toDouble() ?? 85.0,
      precisionScore: (json['precisionScore'] as num?)?.toDouble() ?? 85.0,
      speedScore: (json['speedScore'] as num?)?.toDouble() ?? 80.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
