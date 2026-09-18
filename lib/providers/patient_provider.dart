import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/patient.dart';
import '../models/performance.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class PatientProvider extends ChangeNotifier {
  final StorageService _storage;

  Patient? _currentPatient;
  List<SessionRecord> _sessionHistory = [];
  List<Achievement> _achievements = [];
  int _streakDays = 5;
  Map<String, dynamic>? _supabaseStats;

  PatientProvider(this._storage) {
    refresh();
  }

  Patient? get currentPatient => _currentPatient;
  List<SessionRecord> get sessionHistory => _sessionHistory;
  List<Achievement> get achievements => _achievements;
  int get streakDays => _streakDays;
  Map<String, dynamic>? get supabaseStats => _supabaseStats;

  int get completedSessionsCount =>
      _supabaseStats != null && _supabaseStats!['totalCompleted'] != null
          ? (_supabaseStats!['totalCompleted'] as num).toInt()
          : _sessionHistory.length;

  int get totalAttemptsCount =>
      _supabaseStats != null && _supabaseStats!['totalAttempts'] != null
          ? (_supabaseStats!['totalAttempts'] as num).toInt()
          : _sessionHistory.length;

  int get bestScore =>
      _supabaseStats != null && _supabaseStats!['bestScore'] != null
          ? (_supabaseStats!['bestScore'] as num).toInt()
          : (_sessionHistory.isNotEmpty
              ? _sessionHistory
                  .map((s) => (s.performance.accuracy * 10).round())
                  .reduce((a, b) => a > b ? a : b)
              : 0);

  double get averageAccuracy {
    if (_supabaseStats != null && _supabaseStats!['averageAccuracy'] != null) {
      final acc = (_supabaseStats!['averageAccuracy'] as num).toDouble();
      if (acc > 0) return acc;
    }
    if (_sessionHistory.isEmpty) return 87.0;
    final sum = _sessionHistory.fold<double>(
        0.0, (acc, s) => acc + s.performance.accuracy);
    return double.parse((sum / _sessionHistory.length).toStringAsFixed(1));
  }

  void refresh() {
    final activeId = _storage.getActivePatientId();
    final patients = _storage.getPatients();
    _currentPatient = patients.firstWhere(
      (p) => p.id == activeId,
      orElse: () => patients.isNotEmpty
          ? patients.first
          : const Patient(
              id: 'new-patient',
              name: 'Your profile',
              age: 0,
              condition: 'Rehabilitation program',
            ),
    );

    _sessionHistory = _storage.getSessionHistory(patientId: activeId);
    _achievements = _storage.getAchievements();
    _streakDays = _storage.getStreakDays();
    _evaluateAchievements();
    notifyListeners();

    // Asynchronously load live stats from Supabase
    _loadSupabaseDashboardStats(activeId);
  }

  Future<void> _loadSupabaseDashboardStats(String activeId) async {
    final supa = SupabaseService.instance;
    final userId = supa.currentUserId ?? activeId;
    if (!supa.isConfigured || userId.isEmpty) return;

    try {
      final stats = await supa.getDashboardStats(userId);
      if (stats != null) {
        _supabaseStats = stats;

        // If Supabase has recent sessions, sync any missing records into sessionHistory
        final recent = stats['recentSessions'] as List<dynamic>? ?? [];
        if (recent.isNotEmpty) {
          final existingIds = _sessionHistory.map((s) => s.id).toSet();
          final List<SessionRecord> supaSessions = [];

          for (final raw in recent) {
            final map = raw as Map<String, dynamic>;
            final id = map['id']?.toString() ?? '';
            if (existingIds.contains(id)) continue;

            final acc = (map['accuracy'] as num?)?.toDouble() ?? 0.0;
            final dur = (map['duration_seconds'] as num?)?.toInt() ?? 0;
            final isComp = map['completed'] as bool? ?? false;
            final createdAtStr = map['created_at'] as String?;
            final createdAt = createdAtStr != null
                ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                : DateTime.now();

            supaSessions.add(SessionRecord(
              id: id,
              patientId: map['user_id']?.toString() ?? userId,
              exerciseId: map['exercise_type']?.toString() ?? 'exercise',
              exerciseTitle: map['exercise_name']?.toString() ?? 'Exercise',
              levelNumber: 1,
              performance: PerformanceMetric(
                accuracy: acc,
                completionPercentage: isComp ? 100.0 : 50.0,
                timeTakenSeconds: dur,
                successfulAttempts: (acc / 10).round(),
                failedAttempts: 0,
                timestamp: createdAt,
              ),
              feedbackMessage: 'Completed in V-Hab Rehabilitation.',
              exerciseTip: 'Consistency is key to neuroplastic motor recovery.',
              createdAt: createdAt,
            ));
          }

          if (supaSessions.isNotEmpty) {
            _sessionHistory = [...supaSessions, ..._sessionHistory];
            _sessionHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PatientProvider] Failed loading Supabase stats: $e');
    }
  }


  void _evaluateAchievements() {
    bool updated = false;
    final currentList = [..._achievements];

    for (int i = 0; i < currentList.length; i++) {
      final ach = currentList[i];
      if (ach.isUnlocked) continue;

      if (ach.id == 'ach_streak') {
        if (_streakDays >= 7) {
          currentList[i] = ach.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            progress: 7,
          );
          updated = true;
        } else {
          currentList[i] = ach.copyWith(progress: _streakDays);
        }
      } else if (ach.id == 'ach_consistency') {
        if (_sessionHistory.length >= 5) {
          currentList[i] = ach.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            progress: 5,
          );
          updated = true;
        } else {
          currentList[i] = ach.copyWith(progress: _sessionHistory.length);
        }
      }
    }

    if (updated) {
      _achievements = currentList;
      _storage.saveAchievements(_achievements);
    }
  }

  Future<void> updateActivePatient(Patient patient) async {
    _currentPatient = patient;
    await _storage.updatePatient(patient);
    notifyListeners();
  }
}
