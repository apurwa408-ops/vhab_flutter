import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/hand_tracking_input_service.dart';
import 'exercise/exercise_selection_screen.dart';
import 'patient_achievements_screen.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_progress_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    HandTrackingInputService.instance.stopWebcamTracking();
    _pages = [
      PatientHomeScreen(
        onNavigateTab: (index) => _onTabChanged(index),
      ),
      const ExerciseSelectionScreen(),
      const PatientProgressScreen(),
      const PatientAchievementsScreen(),
      const PatientProfileScreen(),
    ];
  }

  void _onTabChanged(int index) {
    HandTrackingInputService.instance.stopWebcamTracking();
    setState(() => _currentIndex = index);
  }

  final _navItems = const [
    (Icons.home_rounded, 'Home'),
    (Icons.sports_esports_rounded, 'Exercises'),
    (Icons.insights_rounded, 'Progress'),
    (Icons.emoji_events_rounded, 'Achievements'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // Mobile Layout: Bottom Navigation Bar
  Widget _buildMobileLayout() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => _onTabChanged(index),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.cyan.withOpacity(0.18),
          elevation: 0,
          destinations: _navItems.map((item) {
            return NavigationDestination(
              icon: Icon(item.$1, color: AppColors.textSecondary),
              selectedIcon: Icon(item.$1, color: AppColors.cyan),
              label: item.$2,
            );
          }).toList(),
        ),
      ),
    );
  }

  // Tablet Layout: Slim NavigationRail
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => _onTabChanged(index),
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.cyan.withOpacity(0.18),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanPurpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.vrpano_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            destinations: _navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.$1),
                selectedIcon: Icon(item.$1, color: AppColors.cyan),
                label: Text(
                  item.$2,
                  style: GoogleFonts.inter(fontSize: 11),
                ),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout: Permanent Left Sidebar
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Brand
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.cyanPurpleGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.vrpano_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VR REHAB',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Patient Portal',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _currentIndex == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onTabChanged(index),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.cyan.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.$1,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.cyan
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    item.$2,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.deepNavy
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Patient Info Card at bottom
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.cyan.withOpacity(0.2),
                          child: Text(
                            'R',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rahul Sharma',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Level 8 Patient',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
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
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}
