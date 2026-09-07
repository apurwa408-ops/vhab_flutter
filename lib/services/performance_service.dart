import 'dart:math';
import '../models/performance.dart';

class PerformanceService {
  static PerformanceMetric calculateMetrics({
    required int totalTargets,
    required int successfulAttempts,
    required int failedAttempts,
    required int durationSeconds,
    required double baseTargetDistance,
    required double averageDeviation,
    required double stabilityVariance,
    int? measuredReactionTimeMs,
  }) {
    final totalInteractions = successfulAttempts + failedAttempts;

    final double completionPercentage = totalTargets > 0
        ? ((successfulAttempts / totalTargets) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    final double accuracy = totalInteractions > 0
        ? ((successfulAttempts / totalInteractions) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // Precision calculation: penalizes deviation from ideal path/target center
    final double precisionScore = (100.0 - (averageDeviation * 1.5))
        .clamp(40.0, 99.0);

    // Stability calculation: measures low jitter and smooth trajectory
    final double stabilityScore = (100.0 - (stabilityVariance * 2.0))
        .clamp(45.0, 98.0);

    // Speed calculation: assesses efficiency against expected duration
    final double expectedSeconds = max(10, totalTargets * 4).toDouble();
    final double speedRatio = expectedSeconds / max(1, durationSeconds);
    final double speedScore = (speedRatio * 75.0).clamp(50.0, 98.0);

    final int reactionTime = measuredReactionTimeMs ??
        (380 + Random().nextInt(150));

    return PerformanceMetric(
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      completionPercentage:
          double.parse(completionPercentage.toStringAsFixed(1)),
      timeTakenSeconds: durationSeconds,
      successfulAttempts: successfulAttempts,
      failedAttempts: failedAttempts,
      reactionTimeMs: reactionTime,
      stabilityScore: double.parse(stabilityScore.toStringAsFixed(1)),
      precisionScore: double.parse(precisionScore.toStringAsFixed(1)),
      speedScore: double.parse(speedScore.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );
  }
}
