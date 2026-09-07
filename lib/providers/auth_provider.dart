import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/patient.dart';
import '../services/storage_service.dart';

enum UserRole { patient, therapist }

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;

  UserRole? _currentRole;
  String _activePatientId = 'p1';
  AppUser? _currentUser;
  String? _errorMessage;
  bool _isBusy = false;

  AuthProvider(this._storage) {
    _loadState();
  }

  UserRole? get currentRole => _currentRole;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  bool get isPatient => _currentRole == UserRole.patient;
  bool get isTherapist => _currentRole == UserRole.therapist;
  String get activePatientId => _activePatientId;

  void _loadState() {
    final currentId = _storage.getCurrentUserId();
    if (currentId != null) {
      for (final user in _storage.getUsers()) {
        if (user.id == currentId) _currentUser = user;
      }
    }
    _currentRole = null;
    _activePatientId = _storage.getActivePatientId();
    if (_currentUser != null) {
      _currentRole = _currentUser!.role == AppUserRole.patient
          ? UserRole.patient
          : UserRole.therapist;
      _activePatientId = _currentUser!.patientId ?? _activePatientId;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setBusy(true);
    final user = _storage.findUserByEmail(email);
    if (user == null || user.password != password) {
      _errorMessage = 'The email or password is incorrect.';
      _setBusy(false);
      return false;
    }
    _currentUser = user;
    _currentRole = user.role == AppUserRole.patient
        ? UserRole.patient
        : UserRole.therapist;
    if (user.patientId != null) _activePatientId = user.patientId!;
    await _storage.setCurrentUserId(user.id);
    await _storage.setUserRole(_currentRole!.name);
    _errorMessage = null;
    _setBusy(false);
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _setBusy(true);
    final normalizedEmail = email.trim().toLowerCase();
    if (_storage.findUserByEmail(normalizedEmail) != null) {
      _errorMessage = 'An account with this email already exists.';
      _setBusy(false);
      return false;
    }

    final patientId = role == UserRole.patient
        ? 'patient-${DateTime.now().millisecondsSinceEpoch}'
        : null;
    final user = AppUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      password: password,
      displayName: name.trim(),
      role: role == UserRole.patient
          ? AppUserRole.patient
          : AppUserRole.therapist,
      patientId: patientId,
    );
    final users = _storage.getUsers()..add(user);
    await _storage.saveUsers(users);

    if (patientId != null) {
      final patients = _storage.getPatients()
        ..add(Patient(
          id: patientId,
          email: normalizedEmail,
          name: name.trim(),
          age: 0,
          condition: 'New rehabilitation program',
          overallAccuracy: 0,
          totalSessions: 0,
          currentLevel: 1,
          streakDays: 0,
          status: 'New',
          clinicalNotes: 'Newly registered patient. Initial assessment pending.',
          totalExerciseMinutes: 0,
        ));
      await _storage.savePatients(patients);
    }

    _currentUser = user;
    _currentRole = role;
    _activePatientId = patientId ?? _activePatientId;
    await _storage.setCurrentUserId(user.id);
    await _storage.setUserRole(role.name);
    if (patientId != null) await _storage.setActivePatientId(patientId);
    _errorMessage = null;
    _setBusy(false);
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  Future<void> selectRole(UserRole role) async {
    _currentRole = role;
    await _storage.setUserRole(role.name);
    notifyListeners();
  }

  Future<void> switchRole() async {
    if (_currentRole == UserRole.patient) {
      await selectRole(UserRole.therapist);
    } else {
      await selectRole(UserRole.patient);
    }
  }

  Future<void> logout() async {
    _currentRole = null;
    _currentUser = null;
    _errorMessage = null;
    await _storage.setCurrentUserId('');
    await _storage.setUserRole('');
    notifyListeners();
  }

  Future<void> setActivePatientId(String id) async {
    _activePatientId = id;
    await _storage.setActivePatientId(id);
    notifyListeners();
  }
}
