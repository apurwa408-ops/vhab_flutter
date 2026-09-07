import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/exercise.dart';
import '../../../providers/exercise_provider.dart';
import 'tutorial_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  final ExerciseModel exercise;

  const LevelSelectionScreen({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    // Get latest state of this exercise from provider
    final currentExercise = provider.exercises.firstWhere(
      (e) => e.id == exercise.id,
      orElse: () => exercise,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${currentExercise.title} Levels'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // Header description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        currentExercise.icon,
                        color: AppColors.cyan,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level Progression',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Score ≥ 80% accuracy and ≥ 70% completion to unlock the next level.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ladder of 5 Levels
              ...currentExercise.levels.map((level) {
                final isCurrent = level.isUnlocked && !level.isCompleted;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: level.isUnlocked
                          ? () {
                              provider.selectLevel(level);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TutorialScreen(
                                    exercise: currentExercise,
                                    level: level,
                                  ),
                                ),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.cyan.withOpacity(0.06)
                              : (level.isUnlocked
                                  ? AppColors.surface
                                  : AppColors.surface.withOpacity(0.6)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.cyan
                                : (level.isCompleted
                                    ? AppColors.success.withOpacity(0.4)
                                    : AppColors.border),
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Status Badge or Level Number
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: level.isCompleted
                                    ? AppColors.success.withOpacity(0.15)
                                    : (level.isUnlocked
                                        ? AppColors.deepNavy.withOpacity(0.08)
                                        : AppColors.border),
                              ),
                              child: level.isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.success,
                                      size: 26,
                                    )
                                  : (level.isUnlocked
                                      ? Text(
                                          'L${level.levelNumber}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.deepNavy,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.lock_rounded,
                                          color: AppColors.textMuted,
                                          size: 22,
                                        )),
                            ),

                            const SizedBox(width: 16),

                            // Level Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        level.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: level.isUnlocked
                                              ? AppColors.textPrimary
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.cyan,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'CURRENT',
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Difficulty: ${level.difficulty} • Targets: ${level.targetCount}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (level.isCompleted) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Best Accuracy: ${level.bestAccuracy.toStringAsFixed(0)}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Star rating
                            if (level.isUnlocked)
                              Row(
                                children: List.generate(level.stars, (i) {
                                  return const Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: AppColors.warning,
                                  );
                                }),
                              ),

                            const SizedBox(width: 10),
                            Icon(
                              level.isUnlocked
                                  ? Icons.chevron_right_rounded
                                  : Icons.lock_outline_rounded,
                              color: level.isUnlocked
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
