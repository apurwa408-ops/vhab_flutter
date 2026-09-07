import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/exercise.dart';
import '../../../models/performance.dart';
import '../../../providers/exercise_provider.dart';
import '../../../services/hand_tracking_input_service.dart';
import 'game_launcher.dart';

class LevelCompletionScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;
  final PerformanceMetric performance;

  const LevelCompletionScreen({
    super.key,
    required this.exercise,
    required this.level,
    required this.performance,
  });

  @override
  State<LevelCompletionScreen> createState() => _LevelCompletionScreenState();
}

class _LevelCompletionScreenState extends State<LevelCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Guarantee webcam is stopped and hidden upon level completion
    HandTrackingInputService.instance.stopWebcamTracking();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final session = exerciseProvider.lastCompletedSession;
    final progression = exerciseProvider.lastProgressionResult;
    final stars = widget.performance.stars;
    final isNextUnlocked = progression?.shouldUnlockNext ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Celebration Header
                    Text(
                      'LEVEL COMPLETE! 🎉',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.exercise.title} • ${widget.level.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Star Rating Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final filled = index < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 38,
                            color: filled ? AppColors.warning : AppColors.border,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Unlock Badge (if unlocked)
                    if (isNextUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: AppColors.successGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'NEXT LEVEL UNLOCKED 🔓',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Core Metrics Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildMetricTile(
                                label: 'Accuracy',
                                value: '${widget.performance.accuracy.toStringAsFixed(0)}%',
                                color: AppColors.cyan,
                              ),
                              _buildMetricTile(
                                label: 'Completion',
                                value: '${widget.performance.completionPercentage.toStringAsFixed(0)}%',
                                color: AppColors.purple,
                              ),
                              _buildMetricTile(
                                label: 'Time Taken',
                                value: widget.performance.formattedTime,
                                color: AppColors.deepNavy,
                              ),
                            ],
                          ),
                          const Divider(height: 32, color: AppColors.border),
                          Row(
                            children: [
                              _buildSubMetric(
                                'Successful',
                                '${widget.performance.successfulAttempts}',
                                AppColors.success,
                              ),
                              _buildSubMetric(
                                'Failed Attempts',
                                '${widget.performance.failedAttempts}',
                                AppColors.error,
                              ),
                              _buildSubMetric(
                                'Reaction Time',
                                '${widget.performance.reactionTimeMs}ms',
                                AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Detailed Motor Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOTOR PERFORMANCE BREAKDOWN',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPerformanceBar(
                            'Precision',
                            widget.performance.precisionScore,
                            AppColors.cyan,
                          ),
                          const SizedBox(height: 10),
                          _buildPerformanceBar(
                            'Stability',
                            widget.performance.stabilityScore,
                            AppColors.purple,
                          ),
                          const SizedBox(height: 10),
                          _buildPerformanceBar(
                            'Speed & Fluidity',
                            widget.performance.speedScore,
                            AppColors.deepNavy,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Intelligent Feedback Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.smart_toy_rounded,
                            color: AppColors.cyan,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INTELLIGENT CLINICAL FEEDBACK',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepNavy,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session?.feedbackMessage ??
                                      'Excellent accuracy! Your hand control is improving.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                                if (session?.exerciseTip.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tip: ${session!.exerciseTip}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                if (progression?.recommendationMessage.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    progression!.recommendationMessage,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Action Buttons: Next Level, Retry, Menu
                    Builder(
                      builder: (context) {
                        final allLevels = widget.exercise.levels;
                        final currentIndex = allLevels.indexWhere(
                            (l) => l.levelNumber == widget.level.levelNumber);
                        final hasNextLevel = currentIndex >= 0 &&
                            currentIndex < allLevels.length - 1;
                        final nextLevel =
                            hasNextLevel ? allLevels[currentIndex + 1] : null;

                        return Column(
                          children: [
                            if (hasNextLevel && nextLevel != null) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    GameLauncher.launchGame(
                                        context, widget.exercise, nextLevel);
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 26),
                                  label: Text(
                                    'PLAY NEXT LEVEL (${nextLevel.name})',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor:
                                        const Color(0xFF10B981).withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        GameLauncher.launchGame(
                                            context, widget.exercise, widget.level);
                                      },
                                      icon: const Icon(Icons.replay_rounded,
                                          size: 18),
                                      label: const Text('Retry Level'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst);
                                      },
                                      icon: const Icon(Icons.home_rounded,
                                          size: 18),
                                      label: const Text('Home Menu'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.deepNavy,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(String title, double score, Color color) {
    final fraction = (score / 100.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 38,
          child: Text(
            '${score.toInt()}%',
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
