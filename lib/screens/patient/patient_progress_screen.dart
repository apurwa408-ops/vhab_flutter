import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/stat_badge.dart';
import 'session_history_screen.dart';

class PatientProgressScreen extends StatelessWidget {
  const PatientProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();

    final overallAcc = exerciseProvider.getOverallAccuracy();
    final totalSessions = patientProvider.completedSessionsCount;
    final totalLevels = exerciseProvider.getTotalCompletedLevels();
    final streak = patientProvider.streakDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rehabilitation Analytics',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detailed breakdown of your motor recovery progression.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SessionHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Session History'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // KPI Stats Grid
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
                          value: '${overallAcc.toStringAsFixed(0)}%',
                          icon: Icons.track_changes_rounded,
                          iconColor: AppColors.cyan,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Sessions Done',
                          value: '$totalSessions',
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.purple,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Levels Completed',
                          value: '$totalLevels',
                          icon: Icons.military_tech_rounded,
                          iconColor: AppColors.deepNavy,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: StatBadge(
                          label: 'Current Streak',
                          value: '$streak Days 🔥',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Line Chart: Accuracy Over Time
              CustomCard(
                elevated: true,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCURACY OVER TIME',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Session-by-session precision trajectory',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
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
                                getTitlesWidget: (val, meta) {
                                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                  final idx = val.toInt() % days.length;
                                  return Text(
                                    days[idx],
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 40,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 72),
                                FlSpot(1, 76),
                                FlSpot(2, 81),
                                FlSpot(3, 84),
                                FlSpot(4, 88),
                                FlSpot(5, 87),
                                FlSpot(6, 92),
                              ],
                              isCurved: true,
                              color: AppColors.cyan,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.cyan,
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.cyan.withOpacity(0.25),
                                    AppColors.cyan.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
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

              // Bar Chart: Exercise Performance Comparison
              CustomCard(
                elevated: true,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXERCISE MOTOR COMPARISON',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Average accuracy across rehabilitation exercises',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: true),
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
                                interval: 25,
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
                                getTitlesWidget: (val, meta) {
                                  final names = ['Pinch', 'Hold', 'Trace', 'Drag', 'Pose'];
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < names.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        names[idx],
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: [
                            _makeBarGroup(0, 92, AppColors.cyan),
                            _makeBarGroup(1, 86, AppColors.purple),
                            _makeBarGroup(2, 79, AppColors.warning),
                            _makeBarGroup(3, 84, AppColors.success),
                            _makeBarGroup(4, 88, AppColors.deepNavy),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Breakdown Progress Bars
              CustomCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXERCISE PROFICIENCY BREAKDOWN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildExerciseBar('Pinching (Pinch Master)', 92, AppColors.cyan),
                    const SizedBox(height: 14),
                    _buildExerciseBar('Holding (Steady Hold)', 86, AppColors.purple),
                    const SizedBox(height: 14),
                    _buildExerciseBar('Tracing (Path Trace)', 79, AppColors.warning),
                    const SizedBox(height: 14),
                    _buildExerciseBar('Dragging (Shape Drag)', 84, AppColors.success),
                    const SizedBox(height: 14),
                    _buildExerciseBar('Gesture (Gesture Match)', 88, AppColors.deepNavy),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseBar(String title, double score, Color color) {
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
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}
