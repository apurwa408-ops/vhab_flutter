import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/patient.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

enum UserRole { patient, therapist }

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;

  UserRole? _currentRole;
  String _activePatientId = 'p1';
  AppUser? _currentUser;
  String? _errorMessage;
  bool _isBusy = false;
  // True when a PASSWORD_RECOVERY auth event has been received
  bool _passwordRecoveryMode = false;

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
  bool get passwordRecoveryMode => _passwordRecoveryMode;

  Future<void> _loadState() async {
    // 1. Check if Supabase session is active
    final supa = SupabaseService.instance;
    if (supa.isConfigured && supa.currentUser != null) {
      final supaUser = supa.currentUser!;
      final meta = supaUser.userMetadata ?? {};
      final roleStr = meta['role'] as String? ?? 'patient';
      final name = meta['name'] as String? ??
          meta['full_name'] as String? ??
          supaUser.email?.split('@').first ??
          'Patient';

      final role = roleStr == 'therapist' ? UserRole.therapist : UserRole.patient;
      _currentRole = role;
      _activePatientId = supaUser.id;

      _currentUser = AppUser(
        id: supaUser.id,
        email: supaUser.email ?? '',
        password: '',
        displayName: name,
        role: role == UserRole.patient ? AppUserRole.patient : AppUserRole.therapist,
        patientId: supaUser.id,
      );

      await _storage.setCurrentUserId(supaUser.id);
      await _storage.setUserRole(_currentRole!.name);
      await _storage.setActivePatientId(supaUser.id);
      notifyListeners();
      return;
    }

    // 2. Fall back to local storage
    final currentId = _storage.getCurrentUserId();
    if (currentId != null && currentId.isNotEmpty) {
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
    final normalizedEmail = email.trim().toLowerCase();
    final supa = SupabaseService.instance;

    // 1. Try Supabase Auth if configured
    if (supa.isConfigured) {
      try {
        final res = await supa.signIn(
          email: normalizedEmail,
          password: password,
        );

        if (res != null && res.user != null) {
          final supaUser = res.user!;
          final meta = supaUser.userMetadata ?? {};
          final roleStr = meta['role'] as String? ?? 'patient';
          final name = meta['name'] as String? ??
              meta['full_name'] as String? ??
              normalizedEmail.split('@').first;
          final role =
              roleStr == 'therapist' ? UserRole.therapist : UserRole.patient;

          _currentUser = AppUser(
            id: supaUser.id,
            email: normalizedEmail,
            password: '',
            displayName: name,
            role: role == UserRole.patient
                ? AppUserRole.patient
                : AppUserRole.therapist,
            patientId: supaUser.id,
          );
          _currentRole = role;
          _activePatientId = supaUser.id;

          await _storage.setCurrentUserId(supaUser.id);
          await _storage.setUserRole(role.name);
          await _storage.setActivePatientId(supaUser.id);

          // Ensure local patient roster has this profile
          _ensureLocalPatientExists(supaUser.id, name, normalizedEmail);

          // Flush any offline sessions
          supa.syncOfflineQueue(_storage).ignore();

          _errorMessage = null;
          _setBusy(false);
          return true;
        }
      } catch (e) {
        debugPrint('[AuthProvider] Supabase login error: $e');
        // If it was an invalid credential, show it
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('invalid login credentials') ||
            errorMsg.contains('invalid_grant')) {
          _errorMessage = 'The email or password is incorrect.';
          _setBusy(false);
          return false;
        }
        // If network error, attempt local fallback below
      }
    }

    // 2. Local Storage Fallback
    final user = _storage.findUserByEmail(normalizedEmail);
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
    final supa = SupabaseService.instance;

    // 1. Try Supabase Auth if configured
    if (supa.isConfigured) {
      try {
        final res = await supa.signUp(
          email: normalizedEmail,
          password: password,
          name: name.trim(),
          role: role.name,
        );

        if (res != null && res.user != null) {
          final supaUser = res.user!;
          final user = AppUser(
            id: supaUser.id,
            email: normalizedEmail,
            password: '',
            displayName: name.trim(),
            role: role == UserRole.patient
                ? AppUserRole.patient
                : AppUserRole.therapist,
            patientId: supaUser.id,
          );

          _currentUser = user;
          _currentRole = role;
          _activePatientId = supaUser.id;

          await _storage.setCurrentUserId(user.id);
          await _storage.setUserRole(role.name);
          await _storage.setActivePatientId(supaUser.id);

          _ensureLocalPatientExists(supaUser.id, name.trim(), normalizedEmail);

          _errorMessage = null;
          _setBusy(false);
          return true;
        }
      } catch (e) {
        debugPrint('[AuthProvider] Supabase registration error: $e');
        final err = e.toString().toLowerCase();
        if (err.contains('already registered') || err.contains('user_already_exists')) {
          _errorMessage = 'An account with this email already exists.';
          _setBusy(false);
          return false;
        }
        _errorMessage = 'Registration error: ${e.toString()}';
        _setBusy(false);
        return false;
      }
    }

    // 2. Local Storage Fallback
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
      _ensureLocalPatientExists(patientId, name.trim(), normalizedEmail);
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

  void _ensureLocalPatientExists(String patientId, String name, String email) {
    final patients = _storage.getPatients();
    final index = patients.indexWhere((p) => p.id == patientId);
    if (index == -1) {
      patients.add(Patient(
        id: patientId,
        email: email,
        name: name,
        age: 0,
        condition: 'New rehabilitation program',
        overallAccuracy: 0,
        totalSessions: 0,
        currentLevel: 1,
        streakDays: 1,
        status: 'New',
        clinicalNotes: 'Newly registered patient. Assessment pending.',
        totalExerciseMinutes: 0,
      ));
      _storage.savePatients(patients);
    }
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
    final supa = SupabaseService.instance;
    if (supa.isConfigured) {
      await supa.signOut();
    }
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

  /// Called by main.dart when Supabase emits a PASSWORD_RECOVERY event.
  void enterPasswordRecoveryMode() {
    _passwordRecoveryMode = true;
    notifyListeners();
  }

  /// Called after successful password update, or on cancel.
  void exitPasswordRecoveryMode() {
    _passwordRecoveryMode = false;
    notifyListeners();
  }

  /// Request a password-reset email via Supabase.
  /// [redirectTo] is the deployed app URL Supabase sends users back to.
  Future<String?> resetPassword(String email, {String? redirectTo}) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      return 'Please enter a valid email address.';
    }
    final supa = SupabaseService.instance;
    if (!supa.isConfigured) {
      return 'Cloud account required for password reset. If you use a local account, please contact your administrator.';
    }
    // Use current page URL if redirect not provided
    final effectiveRedirect = redirectTo ?? Uri.base.toString();
    _setBusy(true);
    try {
      await supa.sendPasswordResetEmail(
        email: email.trim(),
        redirectTo: effectiveRedirect,
      );
      _setBusy(false);
      return null; // null = success
    } catch (e) {
      _setBusy(false);
      debugPrint('[AuthProvider] resetPassword error: $e');
      return 'Failed to send reset email. Please try again.';
    }
  }

  /// Set a new password using the active PASSWORD_RECOVERY session.
  Future<String?> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    final supa = SupabaseService.instance;
    if (!supa.isConfigured) return 'Supabase is not configured.';
    _setBusy(true);
    try {
      await supa.updatePassword(newPassword);
      _passwordRecoveryMode = false;
      _setBusy(false);
      return null; // null = success
    } catch (e) {
      _setBusy(false);
      debugPrint('[AuthProvider] updatePassword error: $e');
      return 'Failed to update password. The reset link may have expired.';
    }
  }
}
