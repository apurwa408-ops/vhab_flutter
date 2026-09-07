import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_card.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Glowing Brand Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepNavy.withOpacity(0.3),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.vrpano_rounded,
                      size: 52,
                      color: AppColors.cyan,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Title & Subtitle
                Text(
                  'VR REHAB',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppColors.deepNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Train. Improve. Recover.',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'Gamified upper-limb and hand rehabilitation platform combining interactive motor training, progressive challenges, and real-time clinical analytics.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Visual Rehabilitation Feature Highlights
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureBadge(
                        icon: Icons.pinch_rounded,
                        label: '5 Motor Games',
                        color: AppColors.cyan,
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      _buildFeatureBadge(
                        icon: Icons.tune_rounded,
                        label: 'Adaptive Levels',
                        color: AppColors.purple,
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      _buildFeatureBadge(
                        icon: Icons.analytics_rounded,
                        label: 'Clinical SaaS',
                        color: AppColors.deepNavy,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons: Continue as Patient & Continue as Therapist
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      authProvider.selectRole(UserRole.patient);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      elevation: 4,
                      shadowColor: AppColors.deepNavy.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sports_esports_rounded,
                          color: AppColors.cyan,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue as Patient',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      authProvider.selectRole(UserRole.therapist);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.deepNavy, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.deepNavy,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue as Therapist',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Medical/Prototype Disclaimer
                Text(
                  'VR Rehabilitation Training Prototype • Non-diagnostic training system',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
