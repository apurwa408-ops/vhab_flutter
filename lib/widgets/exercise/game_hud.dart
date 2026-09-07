import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_feedback_service.dart';

class GameHud extends StatefulWidget {
  final String exerciseTitle;
  final int levelNumber;
  final int score;
  final double liveAccuracy;
  final int elapsedSeconds;
  final int currentProgress;
  final int totalProgress;
  final String progressLabel;
  final VoidCallback onExit;
  final VoidCallback? onRetry;
  final VoidCallback? onNextLevel;
  final void Function(int)? onSelectLevel;
  final List<int>? availableLevels;

  const GameHud({
    super.key,
    required this.exerciseTitle,
    required this.levelNumber,
    required this.score,
    required this.liveAccuracy,
    required this.elapsedSeconds,
    required this.currentProgress,
    required this.totalProgress,
    this.progressLabel = 'Objects',
    required this.onExit,
    this.onRetry,
    this.onNextLevel,
    this.onSelectLevel,
    this.availableLevels,
  });

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  String get _formattedTimer {
    final m = (widget.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (widget.elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = widget.totalProgress > 0
      ? (widget.currentProgress / widget.totalProgress).clamp(0.0, 1.0)
        : 0.0;

    final levels = widget.availableLevels ?? [1, 2, 3, 4, 5];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top HUD Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Exit button
              IconButton(
                onPressed: widget.onExit,
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Exit Exercise',
                color: AppColors.textSecondary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Current Level Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.exerciseTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'LEVEL ${widget.levelNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0891B2),
                          ),
                        ),
                      ),
                      if (widget.onSelectLevel != null) ...[
                        const SizedBox(width: 8),
                        ...levels.map((lvl) {
                            final isCurrent = lvl == widget.levelNumber;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: InkWell(
                              onTap: () => widget.onSelectLevel!(lvl),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFF06B6D4)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF06B6D4)
                                        : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$lvl',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Quick Action: Retry Button
              IconButton(
                onPressed: () {
                  setState(AudioFeedbackService.toggleMuted);
                },
                icon: Icon(AudioFeedbackService.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 20),
                tooltip: AudioFeedbackService.isMuted ? 'Play audio' : 'Mute audio',
                color: AppColors.purple,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.purple.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              if (widget.onRetry != null)
                IconButton(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Retry Level',
                  color: AppColors.cyan,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.cyan.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),

              // Quick Action: Next Level Button
              if (widget.onNextLevel != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: widget.onNextLevel,
                  icon: const Icon(Icons.skip_next_rounded, size: 20),
                  tooltip: 'Next Level',
                  color: const Color(0xFF10B981),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],

              const SizedBox(width: 14),

              // Telemetry indicators
              _buildHudItem(
                label: 'SCORE',
                value: '${widget.score}',
                color: AppColors.purple,
                icon: Icons.star_rounded,
              ),
              const SizedBox(width: 16),
              _buildHudItem(
                label: 'ACCURACY',
                value: '${widget.liveAccuracy.toStringAsFixed(0)}%',
                color: AppColors.cyan,
                icon: Icons.track_changes_rounded,
              ),
              const SizedBox(width: 16),
              _buildHudItem(
                label: 'TIME',
                value: _formattedTimer,
                color: AppColors.textPrimary,
                icon: Icons.timer_outlined,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Sub-bar: Stage Progress Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                '${widget.progressLabel}: ${widget.currentProgress}/${widget.totalProgress}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.cyan,
                    ),
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progressFraction * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHudItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
