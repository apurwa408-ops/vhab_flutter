import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/therapist_provider.dart';
import '../../widgets/common/custom_card.dart';

class TherapistReportsScreen extends StatefulWidget {
  const TherapistReportsScreen({super.key});

  @override
  State<TherapistReportsScreen> createState() => _TherapistReportsScreenState();
}

class _TherapistReportsScreenState extends State<TherapistReportsScreen> {
  String _selectedDateRange = 'Last 30 Days';

  @override
  Widget build(BuildContext context) {
    final therapistProvider = context.watch<TherapistProvider>();
    final patients = therapistProvider.patients;
    final selectedPatient = therapistProvider.selectedPatient ??
        (patients.isNotEmpty ? patients.first : null);

    if (selectedPatient == null) {
      return const Scaffold(
        body: Center(child: Text('No patient selected')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Export Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Rehabilitation Report',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Formal upper-limb motor recovery evaluation summary.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Report exported: ${selectedPatient.name}_Rehab_Report.pdf',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.deepNavy,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export Report (PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Controls: Patient Selector & Date Range Filter
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      'Target Patient:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: selectedPatient.id,
                      underline: const SizedBox.shrink(),
                      items: patients.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(
                            '${p.name} (#${p.id.toUpperCase()})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          final p = patients.firstWhere((item) => item.id == id);
                          therapistProvider.selectPatient(p);
                        }
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Evaluation Range:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedDateRange,
                      underline: const SizedBox.shrink(),
                      items: ['Last 7 Days', 'Last 30 Days', 'All Time']
                          .map((range) {
                        return DropdownMenuItem<String>(
                          value: range,
                          child: Text(
                            range,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDateRange = val);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Report Document Card
              CustomCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VR UPPER-LIMB REHABILITATION REPORT',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Clinical Telemetry & Progress Assessment',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Generated on: ${DateFormat('MMMM d, y').format(DateTime.now())}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              'Protocol: VR-FineMotor-v2.1',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),

                    // Patient Details Section
                    Text(
                      '1. PATIENT DEMOGRAPHICS & CLINICAL PROFILE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _reportCol('Full Name', selectedPatient.name),
                        _reportCol('Age', '${selectedPatient.age} years old'),
                        _reportCol('Primary Diagnosis', selectedPatient.condition),
                        _reportCol('Clinical Status', selectedPatient.status),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),

                    // Aggregate Metrics Section
                    Text(
                      '2. REHABILITATION METRICS SUMMARY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _reportCol('Total Sessions', '${selectedPatient.totalSessions} sessions logged'),
                        _reportCol('Overall Accuracy', '${selectedPatient.overallAccuracy.toStringAsFixed(1)}%'),
                        _reportCol('Max Level Reached', 'Level ${selectedPatient.currentLevel}'),
                        _reportCol('Exercise Minutes', '${selectedPatient.totalExerciseMinutes} min total'),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),

                    // Exercise Performance Breakdown
                    Text(
                      '3. EXERCISE-SPECIFIC MOTOR PERFORMANCE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _reportExerciseRow('Pinch Master (Opposition)', '92.4%', 'Excellent thumb-index opposition control.'),
                    const SizedBox(height: 8),
                    _reportExerciseRow('Steady Hold (Isometric Stability)', '86.1%', 'Satisfactory tremor control, improved isometric endurance.'),
                    const SizedBox(height: 8),
                    _reportExerciseRow('Path Trace (Motor Precision)', '79.2%', 'Exhibits mild trajectory jitter on curved paths.'),
                    const SizedBox(height: 8),
                    _reportExerciseRow('Shape Drag (Spatial Matching)', '84.0%', 'Good coordinate alignment and placement accuracy.'),
                    const SizedBox(height: 8),
                    _reportExerciseRow('Gesture Match (Pose Differentiation)', '88.0%', 'Swift cognitive recognition and posture matching.'),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),

                    // Therapist Evaluation & Recommendations
                    Text(
                      '4. THERAPIST NOTES & CLINICAL RECOMMENDATIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        selectedPatient.clinicalNotes.isNotEmpty
                            ? selectedPatient.clinicalNotes
                            : 'Patient shows consistent motor response. Recommend continued daily training with focus on steady holding and precision tracing.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Signature block
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. Elena Vance, DPT, OCS',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            Text(
                              'Licensed Physical & Neurological Therapist',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'CLINICALLY VERIFIED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              letterSpacing: 0.8,
                            ),
                          ),
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

  Widget _reportCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportExerciseRow(String title, String accuracy, String assessment) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            accuracy,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ),
          ),
        ),
        Expanded(
          child: Text(
            assessment,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
