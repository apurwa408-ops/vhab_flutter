import '../core/constants/app_constants.dart';
import '../models/performance.dart';

enum DifficultyAdjustment {
  increase,
  maintain,
  practiceCurrent,
  repeatPrevious,
}

class AdaptiveProgressionResult {
  final bool shouldUnlockNext;
  final DifficultyAdjustment adjustment;
  final String recommendationMessage;
  final int recommendedLevel;

  const AdaptiveProgressionResult({
    required this.shouldUnlockNext,
    required this.adjustment,
    required this.recommendationMessage,
    required this.recommendedLevel,
  });
}

class AdaptiveDifficultyService {
  static AdaptiveProgressionResult evaluateProgression({
    required int currentLevel,
    required int maxLevels,
    required PerformanceMetric performance,
  }) {
    final accuracy = performance.accuracy;
    final completion = performance.completionPercentage;

    final qualifiesForUnlock = accuracy >= AppConstants.unlockAccuracyMin &&
        completion >= AppConstants.unlockCompletionMin;

    if (accuracy >= AppConstants.highAccuracyThreshold) {
      final nextLevel = (currentLevel + 1).clamp(1, maxLevels);
      return AdaptiveProgressionResult(
        shouldUnlockNext: true,
        adjustment: DifficultyAdjustment.increase,
        recommendationMessage:
            'Excellent performance! Level $nextLevel is now unlocked.',
        recommendedLevel: nextLevel,
      );
    } else if (accuracy >= AppConstants.moderateAccuracyThreshold) {
      final nextLevel = qualifiesForUnlock
          ? (currentLevel + 1).clamp(1, maxLevels)
          : currentLevel;
      return AdaptiveProgressionResult(
        shouldUnlockNext: qualifiesForUnlock,
        adjustment: DifficultyAdjustment.maintain,
        recommendationMessage: qualifiesForUnlock
            ? 'Great job! Level $nextLevel is unlocked. Maintain this steady pace.'
            : 'Good effort! Reach 70% completion to unlock the next level.',
        recommendedLevel: nextLevel,
      );
    } else if (accuracy >= AppConstants.lowAccuracyThreshold) {
      return AdaptiveProgressionResult(
        shouldUnlockNext: false,
        adjustment: DifficultyAdjustment.practiceCurrent,
        recommendationMessage:
            'Your accuracy was ${accuracy.toStringAsFixed(0)}%. We recommend practicing Level $currentLevel again to build consistency.',
        recommendedLevel: currentLevel,
      );
    } else {
      final prevLevel = (currentLevel - 1).clamp(1, maxLevels);
      return AdaptiveProgressionResult(
        shouldUnlockNext: false,
        adjustment: DifficultyAdjustment.repeatPrevious,
        recommendationMessage: currentLevel > 1
            ? 'Your accuracy was ${accuracy.toStringAsFixed(0)}%. We recommend revisiting Level $prevLevel to re-establish control.'
            : 'Keep practicing Level 1 slowly to build your foundation.',
        recommendedLevel: prevLevel,
      );
    }
  }
}
