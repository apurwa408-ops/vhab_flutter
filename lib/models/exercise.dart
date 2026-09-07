import 'package:flutter/material.dart';

class ExerciseLevel {
  final int levelNumber;
  final String name;
  final String difficulty;
  final int stars;
  final bool isUnlocked;
  final bool isCompleted;
  final double bestAccuracy;
  final int targetCount;
  final int durationSeconds;
  final double tolerance;

  const ExerciseLevel({
    required this.levelNumber,
    required this.name,
    required this.difficulty,
    this.stars = 0,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestAccuracy = 0.0,
    this.targetCount = 5,
    this.durationSeconds = 30,
    this.tolerance = 1.0,
  });

  ExerciseLevel copyWith({
    int? levelNumber,
    String? name,
    String? difficulty,
    int? stars,
    bool? isUnlocked,
    bool? isCompleted,
    double? bestAccuracy,
    int? targetCount,
    int? durationSeconds,
    double? tolerance,
  }) {
    return ExerciseLevel(
      levelNumber: levelNumber ?? this.levelNumber,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      stars: stars ?? this.stars,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      targetCount: targetCount ?? this.targetCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      tolerance: tolerance ?? this.tolerance,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'name': name,
        'difficulty': difficulty,
        'stars': stars,
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
        'bestAccuracy': bestAccuracy,
        'targetCount': targetCount,
        'durationSeconds': durationSeconds,
        'tolerance': tolerance,
      };

  factory ExerciseLevel.fromJson(Map<String, dynamic> json) {
    return ExerciseLevel(
      levelNumber: (json['levelNumber'] as num?)?.toInt() ?? 1,
      name: (json['name'] as String?) ?? 'Level 1',
      difficulty: (json['difficulty'] as String?) ?? 'Beginner',
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      isUnlocked: (json['isUnlocked'] as bool?) ?? false,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0.0,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 5,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 30,
      tolerance: (json['tolerance'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ExerciseModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String category;
  final List<ExerciseLevel> levels;
  final List<String> tutorialSteps;
  final String therapeuticGoal;

  const ExerciseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.category,
    required this.levels,
    required this.tutorialSteps,
    required this.therapeuticGoal,
  });

  int get currentLevelNumber {
    final unlocked = levels.where((l) => l.isUnlocked).toList();
    if (unlocked.isEmpty) return 1;
    return unlocked.last.levelNumber;
  }

  double get overallCompletionRate {
    final completed = levels.where((l) => l.isCompleted).length;
    return (completed / levels.length) * 100.0;
  }

  double get averageAccuracy {
    final completed = levels.where((l) => l.isCompleted).toList();
    if (completed.isEmpty) return 0.0;
    final sum = completed.fold<double>(0.0, (acc, l) => acc + l.bestAccuracy);
    return sum / completed.length;
  }
}
