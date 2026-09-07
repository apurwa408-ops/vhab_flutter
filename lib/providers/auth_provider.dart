import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

enum UserRole {
  patient,
  therapist,
}

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;

  UserRole? _currentRole;
  String _activePatientId = 'p1';

  AuthProvider(this._storage) {
    _loadState();
  }

  UserRole? get currentRole => _currentRole;
  bool get isPatient => _currentRole == UserRole.patient;
  bool get isTherapist => _currentRole == UserRole.therapist;
  String get activePatientId => _activePatientId;

  void _loadState() {
    final roleStr = _storage.getUserRole();
    if (roleStr == 'therapist') {
      _currentRole = UserRole.therapist;
    } else if (roleStr == 'patient') {
      _currentRole = UserRole.patient;
    } else {
      _currentRole = null; // show welcome screen
    }
    _activePatientId = _storage.getActivePatientId();
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
    await _storage.setUserRole('');
    notifyListeners();
  }

  Future<void> setActivePatientId(String id) async {
    _activePatientId = id;
    await _storage.setActivePatientId(id);
    notifyListeners();
  }
}
