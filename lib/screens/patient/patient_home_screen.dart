import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/stat_badge.dart';
import 'exercise/level_selection_screen.dart';
import 'exercise/tutorial_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const PatientHomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();

    final patient = patientProvider.currentPatient;
    final exercises = exerciseProvider.exercises;
    final completedLevels = exerciseProvider.getTotalCompletedLevels();
    final avgAccuracy = exerciseProvider.getOverallAccuracy();
    final streak = patientProvider.streakDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning 👋',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ready for today's hand training?",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.cyan.withOpacity(0.15),
                    child: Text(
                      patient?.name.isNotEmpty == true
                          ? patient!.name[0]
                          : 'R',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hero Card: TODAY'S REHABILITATION SESSION
              CustomCard(
                gradient: AppColors.heroGradient,
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "TODAY'S REHABILITATION SESSION",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '~15 minutes',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Target: 4 upper-limb motor challenges',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pinching, Steady Holding, Path Tracing, and Gesture matching.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Routine Progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '60% (3/5)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Color(0xFF334155),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (exercises.isNotEmpty) {
                            final firstEx = exercises.first;
                            exerciseProvider.selectExercise(firstEx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LevelSelectionScreen(
                                  exercise: firstEx,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Start Daily Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // KPI Stats Row: Accuracy 87%, Sessions 12, Current Level 8, Streak 5 days
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  final double width = isNarrow
                      ? (constraints.maxWidth - 12) / 2
                      : (constraints.maxWidth - 36) / 4;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Accuracy',
                          value: '${avgAccuracy.toStringAsFixed(0)}%',
                          icon: Icons.track_changes_rounded,
                          iconColor: AppColors.cyan,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Sessions',
                          value: '${patientProvider.completedSessionsCount}',
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.purple,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Current Level',
                          value: 'Level $completedLevels',
                          icon: Icons.military_tech_rounded,
                          iconColor: AppColors.deepNavy,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Streak',
                          value: '$streak Days 🔥',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Section: Recommended For You
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended For You',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onNavigateTab?.call(1); // Switch to Exercises tab
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Exercise Cards List
              ...exercises.take(4).map((exercise) {
                return _buildHomeExerciseCard(
                    context, exercise, exerciseProvider);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeExerciseCard(
    BuildContext context,
    ExerciseModel exercise,
    ExerciseProvider provider,
  ) {
    final lvl = exercise.currentLevelNumber;
    final completion = exercise.overallCompletionRate;
    final currentLevelObj = exercise.levels.firstWhere(
      (l) => l.levelNumber == lvl,
      orElse: () => exercise.levels.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(exercise.icon, color: AppColors.deepNavy, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level $lvl • ${currentLevelObj.difficulty}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completion / 100.0,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.cyan,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            onPressed: () {
              provider.selectExercise(exercise);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TutorialScreen(
                    exercise: exercise,
                    level: currentLevelObj,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_filled_rounded),
            color: AppColors.cyan,
            iconSize: 42,
            tooltip: 'Play Exercise',
          ),
        ],
      ),
    );
  }
}
