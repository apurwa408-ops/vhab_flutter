import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/exercise.dart';
import 'games/gesture_match_game.dart';
import 'games/path_trace_game.dart';
import 'games/pinch_master_game.dart';
import 'games/shape_drag_game.dart';
import 'games/steady_hold_game.dart';
import '../../../services/hand_tracking_input_service.dart';
import '../../../widgets/exercise/webcam_pip_view.dart';

class CalibrationScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const CalibrationScreen({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _calibrationProgress = 0.0;
  bool _isCalibrated = false;
  Timer? _simTimer;
  bool _isPointerInside = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    HandTrackingInputService.instance.addListener(_onHandInputUpdate);
    HandTrackingInputService.instance.startWebcamTracking();
  }

  void _onHandInputUpdate() {
    if (!mounted || _isCalibrated) return;
    final service = HandTrackingInputService.instance;
    if (service.isHandDetected) {
      final pos = service.normalizedPosition;
      final inCenter =
          (pos.dx >= 0.20 && pos.dx <= 0.80 && pos.dy >= 0.20 && pos.dy <= 0.80);
      if (inCenter) {
        setState(() {
          _isPointerInside = true;
          _calibrationProgress = (_calibrationProgress + 0.04).clamp(0.0, 1.0);
          if (_calibrationProgress >= 1.0) {
            _isCalibrated = true;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    HandTrackingInputService.instance.removeListener(_onHandInputUpdate);
    _pulseController.dispose();
    _simTimer?.cancel();
    super.dispose();
  }

  void _onEnterArea() {
    setState(() => _isPointerInside = true);
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;
      setState(() {
        _calibrationProgress += 0.04;
        if (_calibrationProgress >= 1.0) {
          _calibrationProgress = 1.0;
          _isCalibrated = true;
          timer.cancel();
        }
      });
    });
  }

  void _onExitArea() {
    setState(() => _isPointerInside = false);
    _simTimer?.cancel();
  }

  void _launchExercise() {
    Widget gameWidget;
    switch (widget.exercise.id) {
      case AppConstants.exercisePinching:
        gameWidget = PinchMasterGame(
          exercise: widget.exercise,
          level: widget.level,
        );
        break;
      case AppConstants.exerciseHolding:
        gameWidget = SteadyHoldGame(
          exercise: widget.exercise,
          level: widget.level,
        );
        break;
      case AppConstants.exerciseTracing:
        gameWidget = PathTraceGame(
          exercise: widget.exercise,
          level: widget.level,
        );
        break;
      case AppConstants.exerciseDragging:
        gameWidget = ShapeDragGame(
          exercise: widget.exercise,
          level: widget.level,
        );
        break;
      case AppConstants.exerciseGesture:
        gameWidget = GestureMatchGame(
          exercise: widget.exercise,
          level: widget.level,
        );
        break;
      default:
        gameWidget = PinchMasterGame(
          exercise: widget.exercise,
          level: widget.level,
        );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => gameWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hand Calibration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: WebcamPipView()),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isCalibrated
                      ? 'Calibration Complete! ✅'
                      : "Let's calibrate your hand",
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isCalibrated
                      ? 'Sensors aligned and ready. Proceed to the exercise.'
                      : 'Place your hand or pointer inside the target area and hold steady.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Radar target area
                MouseRegion(
                  onEnter: (_) => _onEnterArea(),
                  onExit: (_) => _onExitArea(),
                  child: GestureDetector(
                    onTapDown: (_) => _onEnterArea(),
                    onTapUp: (_) => _onExitArea(),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.05);
                        return Transform.scale(
                          scale: _isCalibrated ? 1.0 : scale,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCalibrated
                                  ? AppColors.success.withOpacity(0.12)
                                  : (_isPointerInside
                                      ? AppColors.cyan.withOpacity(0.15)
                                      : AppColors.surface),
                              border: Border.all(
                                color: _isCalibrated
                                    ? AppColors.success
                                    : (_isPointerInside
                                        ? AppColors.cyan
                                        : AppColors.border),
                                width: _isCalibrated ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isCalibrated
                                          ? AppColors.success
                                          : AppColors.cyan)
                                      .withOpacity(0.15),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Circular Hand Icon
                                Icon(
                                  _isCalibrated
                                      ? Icons.check_circle_rounded
                                      : Icons.front_hand_rounded,
                                  size: 72,
                                  color: _isCalibrated
                                      ? AppColors.success
                                      : (_isPointerInside
                                          ? AppColors.cyan
                                          : AppColors.textMuted),
                                ),
                                // Radar rings
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (_isCalibrated
                                              ? AppColors.success
                                              : AppColors.cyan)
                                          .withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Calibration Progress
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isCalibrated
                                ? 'Calibration Complete'
                                : 'Calibration progress',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(_calibrationProgress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isCalibrated
                                  ? AppColors.success
                                  : AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _calibrationProgress,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isCalibrated
                                ? AppColors.success
                                : AppColors.cyan,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Start button
                SizedBox(
                  width: 320,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isCalibrated ? _launchExercise : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCalibrated
                          ? AppColors.cyan
                          : AppColors.border,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Start Exercise',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isCalibrated ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
