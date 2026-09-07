import '../core/constants/app_constants.dart';
import '../models/performance.dart';

class FeedbackService {
  static String generatePerformanceFeedback({
    required PerformanceMetric current,
    PerformanceMetric? previous,
  }) {
    final acc = current.accuracy;

    // Check comparative improvement if previous session exists
    if (previous != null && acc > previous.accuracy + 4.0) {
      return 'You are improving compared with your previous session! Keep up the great focus.';
    }

    if (acc >= AppConstants.highAccuracyThreshold) {
      if (current.stabilityScore >= 90.0) {
        return 'Outstanding control! Excellent accuracy and rock-solid stability.';
      }
      return 'Excellent accuracy! Your hand control is noticeably improving.';
    } else if (acc >= AppConstants.moderateAccuracyThreshold) {
      if (current.precisionScore < 75.0) {
        return 'Good work! Your accuracy is solid, but your precision needs minor improvement.';
      }
      return 'Good work! Your accuracy is improving. Keep practicing for greater consistency.';
    } else if (acc >= AppConstants.lowAccuracyThreshold) {
      return "You're making progress. Focus on slower, more controlled movements.";
    } else {
      return 'Keep practicing. Try reducing your movement speed and focus on following the target carefully.';
    }
  }

  static String getExerciseSpecificTip(String exerciseId) {
    switch (exerciseId) {
      case AppConstants.exercisePinching:
        return 'Focus on thumb-index coordination and gentle pressure release.';
      case AppConstants.exerciseHolding:
        return 'Try to keep your hand steady and avoid unnecessary twitching or sudden movements.';
      case AppConstants.exerciseTracing:
        return 'Move slowly and stay close to the illuminated centerline path.';
      case AppConstants.exerciseDragging:
        return 'Focus on controlled movement and accurate placement within the target boundaries.';
      case AppConstants.exerciseGesture:
        return 'Hold the correct finger position for a moment longer to confirm pose recognition.';
      default:
        return 'Maintain smooth, steady hand movements throughout the challenge.';
    }
  }

  static String getClinicalRecommendation({
    required String exerciseId,
    required double averageAccuracy,
  }) {
    if (averageAccuracy >= 88.0) {
      return 'Patient demonstrates excellent motor control in this task. Ready for higher velocity challenges.';
    } else if (averageAccuracy >= 75.0) {
      return 'Patient shows consistent motor response. Additional sessions will solidify muscle memory.';
    } else {
      return 'Patient exhibits motor fatigue or tremors. Recommend shorter, paced practice intervals.';
    }
  }
}
