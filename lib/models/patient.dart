class Patient {
  final String id;
  final String name;
  final int age;
  final String condition;
  final double overallAccuracy;
  final int totalSessions;
  final int currentLevel;
  final int streakDays;
  final String status; // 'Good', 'Improving', 'Needs Practice'
  final List<String> assignedExerciseIds;
  final String clinicalNotes;
  final int totalExerciseMinutes;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.condition,
    this.overallAccuracy = 85.0,
    this.totalSessions = 12,
    this.currentLevel = 8,
    this.streakDays = 5,
    this.status = 'Good',
    this.assignedExerciseIds = const [
      'pinch_master',
      'steady_hold',
      'path_trace',
      'shape_drag',
      'gesture_match',
    ],
    this.clinicalNotes =
        'Patient shows steady progress in distal motor control. Hand grip endurance improved.',
    this.totalExerciseMinutes = 185,
  });

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? condition,
    double? overallAccuracy,
    int? totalSessions,
    int? currentLevel,
    int? streakDays,
    String? status,
    List<String>? assignedExerciseIds,
    String? clinicalNotes,
    int? totalExerciseMinutes,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      condition: condition ?? this.condition,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      totalSessions: totalSessions ?? this.totalSessions,
      currentLevel: currentLevel ?? this.currentLevel,
      streakDays: streakDays ?? this.streakDays,
      status: status ?? this.status,
      assignedExerciseIds: assignedExerciseIds ?? this.assignedExerciseIds,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      totalExerciseMinutes:
          totalExerciseMinutes ?? this.totalExerciseMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'condition': condition,
        'overallAccuracy': overallAccuracy,
        'totalSessions': totalSessions,
        'currentLevel': currentLevel,
        'streakDays': streakDays,
        'status': status,
        'assignedExerciseIds': assignedExerciseIds,
        'clinicalNotes': clinicalNotes,
        'totalExerciseMinutes': totalExerciseMinutes,
      };

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? 'p1',
      name: json['name'] as String? ?? 'Patient',
      age: (json['age'] as num?)?.toInt() ?? 45,
      condition: json['condition'] as String? ?? 'Post-Stroke Recovery',
      overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 85.0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 10,
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 5,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 3,
      status: json['status'] as String? ?? 'Good',
      assignedExerciseIds: (json['assignedExerciseIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      clinicalNotes: json['clinicalNotes'] as String? ?? '',
      totalExerciseMinutes:
          (json['totalExerciseMinutes'] as num?)?.toInt() ?? 120,
    );
  }
}
