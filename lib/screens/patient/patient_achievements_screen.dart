import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/achievement.dart';
import '../../providers/patient_provider.dart';

class PatientAchievementsScreen extends StatelessWidget {
  const PatientAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final achievements = patientProvider.achievements;
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Achievements & Badges',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Earn badges as you hit key milestones in your recovery journey.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Milestone Summary Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanPurpleGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unlockedCount of ${achievements.length} Badges Unlocked',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Maintain your daily exercise routine to unlock the remaining badges.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievements.isNotEmpty
                                  ? unlockedCount / achievements.length
                                  : 0,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Achievements Grid
              ...achievements.map((ach) => _buildAchievementCard(ach)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement ach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ach.isUnlocked ? AppColors.surface : AppColors.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ach.isUnlocked
              ? AppColors.border
              : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: ach.isUnlocked
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ach.isUnlocked
                  ? AppColors.warning.withOpacity(0.12)
                  : AppColors.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              ach.iconEmoji,
              style: TextStyle(
                fontSize: 28,
                color: ach.isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ach.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ach.isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    if (ach.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'UNLOCKED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${ach.progress}/${ach.maxProgress}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ach.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ach.isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
                if (ach.isUnlocked && ach.unlockedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Unlocked ${DateFormat('MMM d, y').format(ach.unlockedAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else if (!ach.isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ach.progressPercentage,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.cyan,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
