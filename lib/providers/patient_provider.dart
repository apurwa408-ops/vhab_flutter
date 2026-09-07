import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/patient.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class PatientProvider extends ChangeNotifier {
  final StorageService _storage;

  Patient? _currentPatient;
  List<SessionRecord> _sessionHistory = [];
  List<Achievement> _achievements = [];
  int _streakDays = 5;

  PatientProvider(this._storage) {
    refresh();
  }

  Patient? get currentPatient => _currentPatient;
  List<SessionRecord> get sessionHistory => _sessionHistory;
  List<Achievement> get achievements => _achievements;
  int get streakDays => _streakDays;

  int get completedSessionsCount => _sessionHistory.length;

  double get averageAccuracy {
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
          : const Patient(id: 'p1', name: 'Rahul Sharma', age: 48, condition: 'Post-Stroke Recovery'),
    );

    _sessionHistory = _storage.getSessionHistory(patientId: activeId);
    _achievements = _storage.getAchievements();
    _streakDays = _storage.getStreakDays();
    _evaluateAchievements();
    notifyListeners();
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
