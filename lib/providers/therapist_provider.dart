import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class TherapistProvider extends ChangeNotifier {
  final StorageService _storage;

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  List<SessionRecord> _selectedPatientSessions = [];
  String _searchQuery = '';
  String _statusFilter = 'All';

  TherapistProvider(this._storage) {
    refresh();
  }

  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  List<SessionRecord> get selectedPatientSessions => _selectedPatientSessions;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // Clinic Metrics
  int get totalPatientsCount => _patients.length;
  int get activePatientsCount =>
      _patients.where((p) => p.status != 'Discharged').length;
  int get sessionsTodayCount => 14;
  double get averageClinicAccuracy {
    if (_patients.isEmpty) return 84.2;
    final total = _patients.fold<double>(0.0, (acc, p) => acc + p.overallAccuracy);
    return double.parse((total / _patients.length).toStringAsFixed(1));
  }

  List<Patient> get filteredPatients {
    return _patients.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.condition.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'All' || p.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void refresh() {
    _patients = _storage.getPatients();
    if (_patients.isNotEmpty) {
      _selectedPatient ??= _patients.first;
      _loadSelectedPatientSessions();
    }
    notifyListeners();
  }

  void selectPatient(Patient patient) {
    _selectedPatient = patient;
    _loadSelectedPatientSessions();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void _loadSelectedPatientSessions() {
    if (_selectedPatient == null) {
      _selectedPatientSessions = [];
    } else {
      _selectedPatientSessions =
          _storage.getSessionHistory(patientId: _selectedPatient!.id);
    }
  }

  Future<void> updateClinicalNotes(String newNotes) async {
    if (_selectedPatient == null) return;
    final updated = _selectedPatient!.copyWith(clinicalNotes: newNotes);
    _selectedPatient = updated;
    await _storage.updatePatient(updated);
    _patients = _storage.getPatients();
    notifyListeners();
  }

  Future<void> toggleAssignedExercise(String exerciseId) async {
    if (_selectedPatient == null) return;
    final assigned = List<String>.from(_selectedPatient!.assignedExerciseIds);
    if (assigned.contains(exerciseId)) {
      assigned.remove(exerciseId);
    } else {
      assigned.add(exerciseId);
    }
    final updated = _selectedPatient!.copyWith(assignedExerciseIds: assigned);
    _selectedPatient = updated;
    await _storage.updatePatient(updated);
    _patients = _storage.getPatients();
    notifyListeners();
  }
}
