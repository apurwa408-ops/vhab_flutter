import 'performance.dart';

class SessionRecord {
  final String id;
  final String patientId;
  final String exerciseId;
  final String exerciseTitle;
  final int levelNumber;
  final PerformanceMetric performance;
  final String feedbackMessage;
  final String exerciseTip;
  final String clinicalNotes;
  final DateTime createdAt;

  const SessionRecord({
    required this.id,
    required this.patientId,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.levelNumber,
    required this.performance,
    required this.feedbackMessage,
    required this.exerciseTip,
    this.clinicalNotes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'exerciseId': exerciseId,
        'exerciseTitle': exerciseTitle,
        'levelNumber': levelNumber,
        'performance': performance.toJson(),
        'feedbackMessage': feedbackMessage,
        'exerciseTip': exerciseTip,
        'clinicalNotes': clinicalNotes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      exerciseTitle: json['exerciseTitle'] as String? ?? '',
      levelNumber: (json['levelNumber'] as num?)?.toInt() ?? 1,
      performance: PerformanceMetric.fromJson(
        json['performance'] as Map<String, dynamic>? ?? {},
      ),
      feedbackMessage: json['feedbackMessage'] as String? ?? '',
      exerciseTip: json['exerciseTip'] as String? ?? '',
      clinicalNotes: json['clinicalNotes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
