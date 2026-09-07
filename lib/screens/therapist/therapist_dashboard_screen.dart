import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/patient.dart';
import '../../providers/therapist_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/stat_badge.dart';
import 'therapist_patient_detail_screen.dart';

class TherapistDashboardScreen extends StatelessWidget {
  const TherapistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final therapistProvider = context.watch<TherapistProvider>();
    final patients = therapistProvider.filteredPatients;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Rehabilitation Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitor patient recovery milestones, compliance, and exercise telemetry.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_hospital_rounded,
                          size: 18,
                          color: AppColors.deepNavy,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clinic Active',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // KPI Cards: Total Patients, Active Patients, Sessions Today, Average Accuracy
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
                        child: const StatBadge(
                          label: 'Total Patients',
                          value: '28',
                          icon: Icons.people_alt_rounded,
                          iconColor: AppColors.deepNavy,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: const StatBadge(
                          label: 'Active Patients',
                          value: '21',
                          icon: Icons.person_search_rounded,
                          iconColor: AppColors.cyan,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: const StatBadge(
                          label: 'Sessions Today',
                          value: '14',
                          icon: Icons.calendar_today_rounded,
                          iconColor: AppColors.purple,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Average Accuracy',
                          value:
                              '${therapistProvider.averageClinicAccuracy.toStringAsFixed(1)}%',
                          icon: Icons.track_changes_rounded,
                          iconColor: AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Patient Table / Roster Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Patient Rehabilitation Roster',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Filter Chips
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Good', 'Improving', 'Needs Practice']
                        .map((filter) {
                      final isSelected =
                          therapistProvider.statusFilter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) =>
                            therapistProvider.setStatusFilter(filter),
                        selectedColor: AppColors.cyan.withOpacity(0.18),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.deepNavy
                              : AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (val) => therapistProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search patients by name or condition...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),

              // Patients Table Card
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'PATIENT',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ACCURACY',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'SESSIONS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'LEVEL',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'STATUS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                        ],
                      ),
                    ),

                    // Patient Rows
                    ...patients.map((patient) {
                      return _buildPatientRow(
                          context, patient, therapistProvider);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientRow(
    BuildContext context,
    Patient patient,
    TherapistProvider provider,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            provider.selectPatient(patient);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TherapistPatientDetailScreen(patient: patient),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Patient Name & Avatar
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.deepNavy.withOpacity(0.08),
                        child: Text(
                          patient.name.isNotEmpty ? patient.name[0] : 'P',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              patient.condition,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Accuracy
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Text(
                        '${patient.overallAccuracy.toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sessions
                Expanded(
                  flex: 2,
                  child: Text(
                    '${patient.totalSessions} completed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Current Level
                Expanded(
                  flex: 2,
                  child: Text(
                    'Level ${patient.currentLevel}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purple,
                    ),
                  ),
                ),

                // Status Badge
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStatusBadge(patient.status),
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Good':
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        break;
      case 'Improving':
        bg = AppColors.cyan.withOpacity(0.12);
        fg = AppColors.cyan;
        break;
      case 'Needs Practice':
      default:
        bg = AppColors.warning.withOpacity(0.12);
        fg = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
