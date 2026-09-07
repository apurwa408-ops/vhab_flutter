import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/patient.dart';
import '../../providers/therapist_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/stat_badge.dart';

class TherapistPatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const TherapistPatientDetailScreen({
    super.key,
    required this.patient,
  });

  @override
  State<TherapistPatientDetailScreen> createState() =>
      _TherapistPatientDetailScreenState();
}

class _TherapistPatientDetailScreenState
    extends State<TherapistPatientDetailScreen> {
  late TextEditingBar _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingBar(text: widget.patient.clinicalNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final therapistProvider = context.watch<TherapistProvider>();
    final currentPatient = therapistProvider.patients.firstWhere(
      (p) => p.id == widget.patient.id,
      orElse: () => widget.patient,
    );
    final sessions = therapistProvider.selectedPatientSessions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(currentPatient.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.deepNavy.withOpacity(0.08),
                    child: Text(
                      currentPatient.name.isNotEmpty ? currentPatient.name[0] : 'P',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentPatient.name,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatusBadge(currentPatient.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age: ${currentPatient.age} • Condition: ${currentPatient.condition}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Supervising Therapist: Dr. Elena Vance, PT • ID: #${currentPatient.id.toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Top Metrics Row
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
                        label: 'Overall Accuracy',
                        value: '${currentPatient.overallAccuracy.toStringAsFixed(1)}%',
                        icon: Icons.track_changes_rounded,
                        iconColor: AppColors.cyan,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatBadge(
                        label: 'Total Sessions',
                        value: '${currentPatient.totalSessions}',
                        icon: Icons.fitness_center_rounded,
                        iconColor: AppColors.purple,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatBadge(
                        label: 'Current Level',
                        value: 'Level ${currentPatient.currentLevel}',
                        icon: Icons.military_tech_rounded,
                        iconColor: AppColors.deepNavy,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatBadge(
                        label: 'Exercise Time',
                        value: '${currentPatient.totalExerciseMinutes}m',
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.success,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Performance Trend Line Chart
            CustomCard(
              elevated: true,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LONGITUDINAL RECOVERY CURVE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precision trajectory across last therapy sessions',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              reservedSize: 34,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (val, meta) => Text(
                                'S${val.toInt() + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 5,
                        minY: 50,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 68),
                              FlSpot(1, 74),
                              FlSpot(2, 80),
                              FlSpot(3, 85),
                              FlSpot(4, 88),
                              FlSpot(5, 91),
                            ],
                            isCurved: true,
                            color: AppColors.purple,
                            barWidth: 3.5,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.purple.withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Exercise Breakdown & Clinical Recommendations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Breakdown List
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXERCISE BREAKDOWN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBreakdownItem('Pinching', 92, AppColors.cyan),
                        const SizedBox(height: 12),
                        _buildBreakdownItem('Holding', 86, AppColors.purple),
                        const SizedBox(height: 12),
                        _buildBreakdownItem('Tracing', 79, AppColors.warning),
                        const SizedBox(height: 12),
                        _buildBreakdownItem('Dragging', 84, AppColors.success),
                        const SizedBox(height: 12),
                        _buildBreakdownItem('Gesture', 88, AppColors.deepNavy),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Clinical Recommendations & Prescription Card
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CLINICAL RECOMMENDATIONS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cyan.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.thumb_up_rounded,
                                    size: 18,
                                    color: AppColors.cyan,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Strong Pinching Accuracy',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Patient shows strong pinching accuracy and rapid opposition response.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Path Tracing Recommended',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Additional tracing practice may be beneficial to reduce tremor excursions.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Clinical Notes Editor Card
            CustomCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'THERAPIST CLINICAL NOTES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          therapistProvider
                              .updateClinicalNotes(_notesController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Clinical notes updated successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save Notes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepNavy,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter clinical observations or modifications...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Patient Session Log
            CustomCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT RECORDED SESSIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sessions.isEmpty)
                    Text(
                      'No session logs recorded for this patient yet.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    ...sessions.map((sess) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${sess.exerciseTitle} (Level ${sess.levelNumber})',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, y • h:mm a')
                                      .format(sess.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${sess.performance.accuracy.toStringAsFixed(0)}% Acc',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String title, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${score.toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class TextEditingBar extends TextEditingController {
  TextEditingBar({super.text});
}
