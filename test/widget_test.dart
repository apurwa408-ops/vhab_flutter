import 'package:flutter_test/flutter_test.dart';
import 'package:vhab_flutter/models/performance.dart';
import 'package:vhab_flutter/services/adaptive_difficulty_service.dart';
import 'package:vhab_flutter/services/feedback_service.dart';

void main() {
  group('AdaptiveDifficultyService Tests', () {
    test('High accuracy (>=90%) unlocks next level and increases difficulty', () {
      final metric = PerformanceMetric(
        accuracy: 94.0,
        completionPercentage: 100.0,
        timeTakenSeconds: 30,
        successfulAttempts: 10,
        failedAttempts: 1,
        timestamp: DateTime.now(),
      );

      final result = AdaptiveDifficultyService.evaluateProgression(
        currentLevel: 1,
        maxLevels: 5,
        performance: metric,
      );

      expect(result.shouldUnlockNext, isTrue);
      expect(result.adjustment, equals(DifficultyAdjustment.increase));
      expect(result.recommendedLevel, equals(2));
      expect(result.recommendationMessage, contains('Level 2 is now unlocked'));
    });

    test('Low accuracy (<60%) recommends practicing or repeating', () {
      final metric = PerformanceMetric(
        accuracy: 52.0,
        completionPercentage: 60.0,
        timeTakenSeconds: 45,
        successfulAttempts: 5,
        failedAttempts: 5,
        timestamp: DateTime.now(),
      );

      final result = AdaptiveDifficultyService.evaluateProgression(
        currentLevel: 3,
        maxLevels: 5,
        performance: metric,
      );

      expect(result.shouldUnlockNext, isFalse);
      expect(result.adjustment, equals(DifficultyAdjustment.repeatPrevious));
      expect(result.recommendedLevel, equals(2));
    });
  });

  group('FeedbackService Tests', () {
    test('Generates excellent feedback for >= 90% accuracy', () {
      final current = PerformanceMetric(
        accuracy: 92.0,
        completionPercentage: 100.0,
        timeTakenSeconds: 25,
        successfulAttempts: 10,
        failedAttempts: 1,
        stabilityScore: 92.0,
        timestamp: DateTime.now(),
      );

      final msg = FeedbackService.generatePerformanceFeedback(current: current);
      expect(msg, contains('accuracy'));
    });

    test('Exercise specific tips are returned', () {
      expect(FeedbackService.getExerciseSpecificTip('pinch_master'),
          contains('thumb-index'));
      expect(FeedbackService.getExerciseSpecificTip('steady_hold'),
          contains('hand steady'));
      expect(FeedbackService.getExerciseSpecificTip('path_trace'),
          contains('centerline'));
    });
  });
}
