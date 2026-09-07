class AppConstants {
  static const String appName = 'VR REHAB';
  static const String appTagline = 'Train. Improve. Recover.';
  static const String appSubtitle = 'Gamified Upper-Limb Rehabilitation Platform';

  // Storage Keys
  static const String keyUserRole = 'vhab_user_role';
  static const String keyActivePatientId = 'vhab_active_patient_id';
  static const String keyExerciseProgression = 'vhab_exercise_progression';
  static const String keySessionHistory = 'vhab_session_history';
  static const String keyAchievements = 'vhab_achievements';
  static const String keyPatientRoster = 'vhab_patient_roster';
  static const String keyDailyStreak = 'vhab_daily_streak';
  static const String keyLastSessionDate = 'vhab_last_session_date';

  // Progression Thresholds
  static const double unlockAccuracyMin = 80.0;
  static const double unlockCompletionMin = 70.0;
  static const double highAccuracyThreshold = 90.0;
  static const double moderateAccuracyThreshold = 80.0;
  static const double lowAccuracyThreshold = 60.0;

  // Exercise IDs
  static const String exercisePinching = 'pinch_master';
  static const String exerciseHolding = 'steady_hold';
  static const String exerciseTracing = 'path_trace';
  static const String exerciseDragging = 'shape_drag';
  static const String exerciseGesture = 'gesture_match';
}
