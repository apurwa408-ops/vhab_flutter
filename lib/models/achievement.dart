class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    required this.maxProgress,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconEmoji,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? maxProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
    );
  }

  double get progressPercentage {
    if (maxProgress <= 0) return 1.0;
    return (progress / maxProgress).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconEmoji': iconEmoji,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'progress': progress,
        'maxProgress': maxProgress,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconEmoji: json['iconEmoji'] as String? ?? '🏆',
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      maxProgress: (json['maxProgress'] as num?)?.toInt() ?? 1,
    );
  }
}
