import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_card.dart';

class TherapistSettingsScreen extends StatelessWidget {
  const TherapistSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Settings & Configuration',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure upper-limb rehabilitation parameters and account credentials.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Thresholds Configuration
              CustomCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADAPTIVE PROGRESSION THRESHOLDS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _settingRow(
                      'Minimum Accuracy for Level Unlock',
                      '80% (Clinical Standard)',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _settingRow(
                      'Minimum Completion Rate for Level Unlock',
                      '70%',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _settingRow(
                      'High Performance Threshold',
                      '≥ 90% (Triggers Difficulty Increase)',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _settingRow(
                      'Tremor Stability Window',
                      '150ms dynamic moving average',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Hardware Simulation Settings
              CustomCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INPUT & HARDWARE EMULATION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _settingRow(
                      'Input Mode',
                      'Simulated Pointer (Mouse / Touch / Gestures)',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _settingRow(
                      'VR / Hand-Tracking Driver',
                      'Ready for MediaPipe / OpenXR Integration',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Role Switcher & Account
              CustomCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROLE MANAGEMENT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Switch to the Patient Experience to preview interactive rehabilitation exercises directly.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            authProvider.selectRole(UserRole.patient);
                          },
                          icon: const Icon(Icons.sports_esports_rounded, size: 20),
                          label: const Text('Switch to Patient Portal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            authProvider.logout();
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.deepNavy.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.deepNavy,
            ),
          ),
        ),
      ],
    );
  }
}
