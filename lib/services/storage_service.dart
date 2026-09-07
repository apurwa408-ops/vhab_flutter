import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/achievement.dart';
import '../models/app_user.dart';
import '../models/patient.dart';
import '../models/performance.dart';
import '../models/session.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._seedInitialDataIfEmpty();
    await service._removeLegacyRahulDemo();
    return service;
  }

  Future<void> _removeLegacyRahulDemo() async {
    final patients = getPatients();
    final legacyIds = patients
        .where((patient) =>
            patient.id == 'p1' || patient.name.toLowerCase() == 'rahul sharma')
        .map((patient) => patient.id)
        .toSet();
    if (legacyIds.isEmpty) return;

    await savePatients(
      patients.where((patient) => !legacyIds.contains(patient.id)).toList(),
    );

    final remainingSessions = getSessionHistory()
        .where((session) => !legacyIds.contains(session.patientId))
        .toList();
    await _prefs.setString(
      AppConstants.keySessionHistory,
      jsonEncode(remainingSessions.map((session) => session.toJson()).toList()),
    );

    if (getActivePatientId() == 'p1') {
      await setActivePatientId('');
    }
  }

  // --- Role Management ---
  String? getUserRole() => _prefs.getString(AppConstants.keyUserRole);
  Future<void> setUserRole(String role) =>
      _prefs.setString(AppConstants.keyUserRole, role);

  List<AppUser> getUsers() {
    final raw = _prefs.getString(AppConstants.keyUsers);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUsers(List<AppUser> users) async {
    await _prefs.setString(
      AppConstants.keyUsers,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );
  }

  AppUser? findUserByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in getUsers()) {
      if (user.email.toLowerCase() == normalized) return user;
    }
    return null;
  }

  Future<void> setCurrentUserId(String id) =>
      _prefs.setString(AppConstants.keyCurrentUserId, id);

  String? getCurrentUserId() => _prefs.getString(AppConstants.keyCurrentUserId);

  // --- Active Patient ---
  String getActivePatientId() =>
      _prefs.getString(AppConstants.keyActivePatientId) ?? 'p1';
  Future<void> setActivePatientId(String patientId) =>
      _prefs.setString(AppConstants.keyActivePatientId, patientId);

  // --- Patient Roster ---
  List<Patient> getPatients() {
    final raw = _prefs.getString(AppConstants.keyPatientRoster);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Patient.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePatients(List<Patient> patients) async {
    final raw = jsonEncode(patients.map((p) => p.toJson()).toList());
    await _prefs.setString(AppConstants.keyPatientRoster, raw);
  }

  Future<void> updatePatient(Patient patient) async {
    final list = getPatients();
    final index = list.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      list[index] = patient;
    } else {
      list.add(patient);
    }
    await savePatients(list);
  }

  // --- Session History ---
  List<SessionRecord> getSessionHistory({String? patientId}) {
    final raw = _prefs.getString(AppConstants.keySessionHistory);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final sessions = list
          .map((item) => SessionRecord.fromJson(item as Map<String, dynamic>))
          .toList();
      if (patientId != null) {
        return sessions.where((s) => s.patientId == patientId).toList();
      }
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> addSessionRecord(SessionRecord record) async {
    final list = getSessionHistory();
    list.insert(0, record); // newest first
    final raw = jsonEncode(list.map((s) => s.toJson()).toList());
    await _prefs.setString(AppConstants.keySessionHistory, raw);
    await _updateStreakOnNewSession(record.createdAt);
  }

  // --- Exercise Progression ---
  // Structure: { exerciseId: { '1': { 'isUnlocked': true, 'stars': 3, ... } } }
  Map<String, Map<String, dynamic>> getProgressionMap() {
    final raw = _prefs.getString(AppConstants.keyExerciseProgression);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveProgressionMap(
      Map<String, Map<String, dynamic>> map) async {
    await _prefs.setString(
        AppConstants.keyExerciseProgression, jsonEncode(map));
  }

  // --- Achievements ---
  List<Achievement> getAchievements() {
    final raw = _prefs.getString(AppConstants.keyAchievements);
    if (raw == null) return _defaultAchievements();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultAchievements();
    }
  }

  Future<void> saveAchievements(List<Achievement> achievements) async {
    final raw = jsonEncode(achievements.map((a) => a.toJson()).toList());
    await _prefs.setString(AppConstants.keyAchievements, raw);
  }

  // --- Streak Management ---
  int getStreakDays() => _prefs.getInt(AppConstants.keyDailyStreak) ?? 5;

  Future<void> _updateStreakOnNewSession(DateTime sessionDate) async {
    final lastDateStr = _prefs.getString(AppConstants.keyLastSessionDate);
    final today = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);

    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final lastDay =
            DateTime(lastDate.year, lastDate.month, lastDate.day);
        final difference = today.difference(lastDay).inDays;

        if (difference == 1) {
          final newStreak = getStreakDays() + 1;
          await _prefs.setInt(AppConstants.keyDailyStreak, newStreak);
        } else if (difference > 1) {
          await _prefs.setInt(AppConstants.keyDailyStreak, 1);
        }
      }
    } else {
      await _prefs.setInt(AppConstants.keyDailyStreak, 1);
    }

    await _prefs.setString(
        AppConstants.keyLastSessionDate, sessionDate.toIso8601String());
  }

  // --- Seed Initial Data ---
  Future<void> _seedInitialDataIfEmpty() async {
    if (_prefs.getString(AppConstants.keyPatientRoster) == null) {
      final demoPatients = [
        const Patient(
          id: 'p1',
          email: 'rahul@example.com',
          name: 'Demo Patient',
          age: 48,
          condition: 'Post-Stroke Upper-Limb Recovery',
          overallAccuracy: 91.2,
          totalSessions: 18,
          currentLevel: 12,
          streakDays: 5,
          status: 'Good',
          clinicalNotes:
              'Patient shows strong pinching accuracy. Steady improvement in fine motor dexterity.',
          totalExerciseMinutes: 245,
        ),
        const Patient(
          id: 'p2',
          email: 'priya@example.com',
          name: 'Priya Patel',
          age: 34,
          condition: 'Carpal Tunnel Release Rehab',
          overallAccuracy: 84.0,
          totalSessions: 14,
          currentLevel: 8,
          streakDays: 3,
          status: 'Improving',
          clinicalNotes:
              'Grip strength recovering well. Additional tracing practice may be beneficial for tremor reduction.',
          totalExerciseMinutes: 190,
        ),
        const Patient(
          id: 'p3',
          email: 'aman@example.com',
          name: 'Aman Verma',
          age: 62,
          condition: 'Parkinsonian Tremor Control',
          overallAccuracy: 67.5,
          totalSessions: 10,
          currentLevel: 5,
          streakDays: 2,
          status: 'Needs Practice',
          clinicalNotes:
              'Shows motor fatigue after 8 minutes. Recommend shorter sessions focusing on steady holding.',
          totalExerciseMinutes: 110,
        ),
      ];
      await savePatients(demoPatients);
    }

    if (_prefs.getString(AppConstants.keySessionHistory) == null) {
      final now = DateTime.now();
      final demoSessions = [
        SessionRecord(
          id: 's-01',
          patientId: 'p1',
          exerciseId: AppConstants.exercisePinching,
          exerciseTitle: 'Pinch Master',
          levelNumber: 3,
          performance: PerformanceMetric(
            accuracy: 91.4,
            completionPercentage: 100.0,
            timeTakenSeconds: 114,
            successfulAttempts: 18,
            failedAttempts: 2,
            reactionTimeMs: 410,
            stabilityScore: 91.0,
            precisionScore: 88.0,
            speedScore: 85.0,
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
          feedbackMessage:
              'Excellent accuracy! Your hand control is improving.',
          exerciseTip:
              'Focus on thumb-index coordination and gentle pressure release.',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        SessionRecord(
          id: 's-02',
          patientId: 'p1',
          exerciseId: AppConstants.exerciseTracing,
          exerciseTitle: 'Path Trace',
          levelNumber: 2,
          performance: PerformanceMetric(
            accuracy: 84.0,
            completionPercentage: 92.0,
            timeTakenSeconds: 140,
            successfulAttempts: 14,
            failedAttempts: 3,
            reactionTimeMs: 460,
            stabilityScore: 84.0,
            precisionScore: 82.0,
            speedScore: 78.0,
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          feedbackMessage:
              'Good work! Your accuracy is improving. Keep practicing for greater consistency.',
          exerciseTip:
              'Move slowly and stay close to the illuminated centerline path.',
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        SessionRecord(
          id: 's-03',
          patientId: 'p1',
          exerciseId: AppConstants.exerciseHolding,
          exerciseTitle: 'Steady Hold',
          levelNumber: 2,
          performance: PerformanceMetric(
            accuracy: 88.0,
            completionPercentage: 100.0,
            timeTakenSeconds: 85,
            successfulAttempts: 5,
            failedAttempts: 1,
            reactionTimeMs: 390,
            stabilityScore: 89.0,
            precisionScore: 87.0,
            speedScore: 82.0,
            timestamp: now.subtract(const Duration(days: 2, hours: 4)),
          ),
          feedbackMessage:
              'Good work! Your accuracy is improving. Keep practicing for greater consistency.',
          exerciseTip:
              'Try to keep your hand steady and avoid unnecessary twitching.',
          createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        ),
      ];
      final raw = jsonEncode(demoSessions.map((s) => s.toJson()).toList());
      await _prefs.setString(AppConstants.keySessionHistory, raw);
    }

    if (_prefs.getString(AppConstants.keyAchievements) == null) {
      await saveAchievements(_defaultAchievements());
    }

    if (!_prefs.containsKey(AppConstants.keyDailyStreak)) {
      await _prefs.setInt(AppConstants.keyDailyStreak, 5);
    }
  }

  static List<Achievement> _defaultAchievements() {
    return [
      Achievement(
        id: 'ach_precision',
        title: 'Precision Master',
        description: 'Reach 90% accuracy in any exercise.',
        iconEmoji: '🎯',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
        progress: 91,
        maxProgress: 90,
      ),
      Achievement(
        id: 'ach_streak',
        title: '7 Day Streak',
        description: 'Complete exercises for 7 consecutive days.',
        iconEmoji: '🔥',
        isUnlocked: false,
        progress: 5,
        maxProgress: 7,
      ),
      Achievement(
        id: 'ach_champion',
        title: 'Level Champion',
        description: 'Complete 10 different exercise levels.',
        iconEmoji: '🏆',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 4)),
        progress: 10,
        maxProgress: 10,
      ),
      Achievement(
        id: 'ach_consistency',
        title: 'Consistency',
        description: 'Complete 5 full rehabilitation sessions.',
        iconEmoji: '💪',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 6)),
        progress: 5,
        maxProgress: 5,
      ),
      Achievement(
        id: 'ach_pinch_expert',
        title: 'Pinch Expert',
        description: 'Complete all 5 Pinching exercise levels.',
        iconEmoji: '🤏',
        isUnlocked: false,
        progress: 3,
        maxProgress: 5,
      ),
      Achievement(
        id: 'ach_steady_hand',
        title: 'Steady Hand',
        description: 'Complete all 5 Holding exercise levels.',
        iconEmoji: '✋',
        isUnlocked: false,
        progress: 2,
        maxProgress: 5,
      ),
    ];
  }
}
