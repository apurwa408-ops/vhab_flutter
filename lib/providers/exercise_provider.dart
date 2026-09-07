import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/performance.dart';
import '../models/session.dart';
import '../services/adaptive_difficulty_service.dart';
import '../services/exercise_service.dart';
import '../services/feedback_service.dart';
import '../services/storage_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final StorageService _storage;

  List<ExerciseModel> _exercises = [];
  ExerciseModel? _activeExercise;
  ExerciseLevel? _activeLevel;
  SessionRecord? _lastCompletedSession;
  AdaptiveProgressionResult? _lastProgressionResult;

  ExerciseProvider(this._storage) {
    _loadExercises();
  }

  List<ExerciseModel> get exercises => _exercises;
  ExerciseModel? get activeExercise => _activeExercise;
  ExerciseLevel? get activeLevel => _activeLevel;
  SessionRecord? get lastCompletedSession => _lastCompletedSession;
  AdaptiveProgressionResult? get lastProgressionResult => _lastProgressionResult;

  void _loadExercises() {
    final all = ExerciseService.getAllExercises();
    final savedProgression = _storage.getProgressionMap();

    _exercises = all.map((exercise) {
      final exProg = savedProgression[exercise.id];
      if (exProg == null) return exercise;

      final updatedLevels = exercise.levels.map((level) {
        final lvlKey = level.levelNumber.toString();
        if (exProg.containsKey(lvlKey)) {
          final data = exProg[lvlKey] as Map<String, dynamic>;
          return level.copyWith(
            isUnlocked: data['isUnlocked'] as bool? ?? level.isUnlocked,
            isCompleted: data['isCompleted'] as bool? ?? level.isCompleted,
            stars: (data['stars'] as num?)?.toInt() ?? level.stars,
            bestAccuracy:
                (data['bestAccuracy'] as num?)?.toDouble() ?? level.bestAccuracy,
          );
        }
        return level;
      }).toList();

      return ExerciseModel(
        id: exercise.id,
        title: exercise.title,
        subtitle: exercise.subtitle,
        description: exercise.description,
        icon: exercise.icon,
        category: exercise.category,
        levels: updatedLevels,
        tutorialSteps: exercise.tutorialSteps,
        therapeuticGoal: exercise.therapeuticGoal,
      );
    }).toList();

    notifyListeners();
  }

  void selectExercise(ExerciseModel exercise) {
    _activeExercise = exercise;
    // Default to the highest unlocked level or level 1
    final unlocked = exercise.levels.where((l) => l.isUnlocked).toList();
    _activeLevel = unlocked.isNotEmpty ? unlocked.last : exercise.levels.first;
    notifyListeners();
  }

  void selectLevel(ExerciseLevel level) {
    _activeLevel = level;
    notifyListeners();
  }

  Future<void> completeExerciseSession({
    required String patientId,
    required PerformanceMetric performance,
  }) async {
    if (_activeExercise == null || _activeLevel == null) return;

    final ex = _activeExercise!;
    final lvl = _activeLevel!;

    // 1. Evaluate adaptive difficulty & unlock rules
    final adaptiveResult = AdaptiveDifficultyService.evaluateProgression(
      currentLevel: lvl.levelNumber,
      maxLevels: ex.levels.length,
      performance: performance,
    );
    _lastProgressionResult = adaptiveResult;

    // 2. Generate clinical feedback & tips
    final feedback = FeedbackService.generatePerformanceFeedback(
      current: performance,
    );
    final tip = FeedbackService.getExerciseSpecificTip(ex.id);

    // 3. Create session record
    final session = SessionRecord(
      id: 'sess-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      exerciseId: ex.id,
      exerciseTitle: ex.title,
      levelNumber: lvl.levelNumber,
      performance: performance,
      feedbackMessage: feedback,
      exerciseTip: tip,
      createdAt: DateTime.now(),
    );
    _lastCompletedSession = session;

    // Save session in storage
    await _storage.addSessionRecord(session);

    final patients = _storage.getPatients();
    final patientIndex = patients.indexWhere((item) => item.id == patientId);
    if (patientIndex != -1) {
      final patient = patients[patientIndex];
      final patientSessions = _storage.getSessionHistory(patientId: patientId);
      final totalAccuracy = patientSessions.fold<double>(
        0.0, (sum, item) => sum + item.performance.accuracy);
      final averageAccuracy = patientSessions.isEmpty
        ? patient.overallAccuracy
        : totalAccuracy / patientSessions.length;
      final updatedPatient = patient.copyWith(
      overallAccuracy: double.parse(averageAccuracy.toStringAsFixed(1)),
      totalSessions: patientSessions.length,
      currentLevel: patient.currentLevel > lvl.levelNumber
        ? patient.currentLevel
        : lvl.levelNumber,
      streakDays: _storage.getStreakDays(),
      status: averageAccuracy >= 85
        ? 'Good'
        : (averageAccuracy >= 70 ? 'Improving' : 'Needs Practice'),
      totalExerciseMinutes: patient.totalExerciseMinutes +
        (performance.timeTakenSeconds / 60).ceil(),
      );
      await _storage.updatePatient(updatedPatient);
    }

    // 4. Update level status & progression in memory and storage
    final updatedProgression = _storage.getProgressionMap();
    final exerciseMap = updatedProgression[ex.id] ?? {};

    // Current level is now completed
    final newStars = performance.stars;
    final bestAcc = performance.accuracy > lvl.bestAccuracy
        ? performance.accuracy
        : lvl.bestAccuracy;

    exerciseMap[lvl.levelNumber.toString()] = {
      'isUnlocked': true,
      'isCompleted': true,
      'stars': newStars > lvl.stars ? newStars : lvl.stars,
      'bestAccuracy': bestAcc,
    };

    // Unlock next level if criteria met
    if (adaptiveResult.shouldUnlockNext && lvl.levelNumber < ex.levels.length) {
      final nextLvlNum = (lvl.levelNumber + 1).toString();
      final currentNext =
          exerciseMap[nextLvlNum] as Map<String, dynamic>? ?? {};
      exerciseMap[nextLvlNum] = {
        ...currentNext,
        'isUnlocked': true,
      };
    }

    updatedProgression[ex.id] = exerciseMap;
    await _storage.saveProgressionMap(updatedProgression);

    // Reload exercises to update UI state
    _loadExercises();

    // Re-bind active exercise and level with updated states
    _activeExercise = _exercises.firstWhere((e) => e.id == ex.id);
    _activeLevel = _activeExercise!.levels.firstWhere(
      (l) => l.levelNumber == lvl.levelNumber,
    );

    notifyListeners();
  }

  double getOverallAccuracy() {
    final sessions = _storage.getSessionHistory();
    if (sessions.isEmpty) return 87.0;
    final total = sessions.fold<double>(
        0.0, (acc, s) => acc + s.performance.accuracy);
    return double.parse((total / sessions.length).toStringAsFixed(1));
  }

  int getTotalCompletedLevels() {
    int total = 0;
    for (final ex in _exercises) {
      total += ex.levels.where((l) => l.isCompleted).length;
    }
    return total;
  }
}
