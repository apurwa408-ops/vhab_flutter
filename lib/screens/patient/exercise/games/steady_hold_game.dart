import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/exercise.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/exercise_provider.dart';
import '../../../../services/audio_feedback_service.dart';
import '../../../../services/hand_tracking_input_service.dart';
import '../../../../services/performance_service.dart';
import '../../../../widgets/exercise/game_hud.dart';
import '../../../../widgets/exercise/virtual_hand_cursor.dart';
import '../../../../widgets/exercise/webcam_pip_view.dart';
import '../game_launcher.dart';
import '../level_completion_screen.dart';

class SteadyHoldGame extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const SteadyHoldGame({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<SteadyHoldGame> createState() => _SteadyHoldGameState();
}

class _SteadyHoldGameState extends State<SteadyHoldGame>
    with SingleTickerProviderStateMixin {
  final HandTrackingInputService _inputService = HandTrackingInputService.instance;
  late AnimationController _pulseController;

  late int _targetHoldSeconds;
  static const int _requiredAttempts = 3;

  int _successfulAttempts = 0;
  int _failedAttempts = 0;
  int _score = 0;
  int _elapsedGameSeconds = 0;
  Timer? _gameTimer;
  Timer? _holdTickTimer;

  bool _isHolding = false;
  double _currentHoldMilliseconds = 0;
  final ValueNotifier<double> _holdProgressNotifier = ValueNotifier(0.0);
  bool _isGameOver = false;

  double _accumulatedTremorVariance = 0.0;
  int _holdSampleCount = 0;
  Size _cachedBounds = const Size(800, 600);

  @override
  void initState() {
    super.initState();
    _targetHoldSeconds = widget.level.durationSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startGameTimer();
    _inputService.addListener(_onCameraFrame);
    _inputService.startWebcamTracking();
  }

  void _onCameraFrame() {
    if (!mounted || _isGameOver || !_inputService.isHandDetected) return;
    final pos = _inputService.normalizedPosition;
    final localPos = Offset(
      pos.dx * _cachedBounds.width,
      pos.dy * _cachedBounds.height,
    );

    final center = Offset(_cachedBounds.width * 0.5, _cachedBounds.height * 0.5);
    final dist = (localPos - center).distance;
    final maxRadius = 90.0 * widget.level.tolerance;

    if (dist <= maxRadius) {
      if (!_isHolding) {
        _startHolding();
      } else {
        // Inline stability tracking (was in _onPointerMove)
        _accumulatedTremorVariance += dist;
        _holdSampleCount++;
      }
    } else {
      if (_isHolding) {
        _failHold();
      }
    }
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsedGameSeconds++);
    });
  }

  @override
  void dispose() {
    _inputService.stopWebcamTracking();
    _inputService.removeListener(_onCameraFrame);
    _pulseController.dispose();
    _gameTimer?.cancel();
    _holdTickTimer?.cancel();
    _holdProgressNotifier.dispose();
    super.dispose();
  }

  double get _currentAccuracy {
    final total = _successfulAttempts + _failedAttempts;
    if (total == 0) return 100.0;
    return (_successfulAttempts / total) * 100.0;
  }

  void _startHolding() {
    AudioFeedbackService.playPinch();
    setState(() {
      _isHolding = true;
      _currentHoldMilliseconds = 0;
      _holdProgressNotifier.value = 0.0;
    });

    int tickCount = 0;
    _holdTickTimer?.cancel();
    _holdTickTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_isHolding) {
        timer.cancel();
        return;
      }
      _currentHoldMilliseconds += 50;
      final totalTargetMs = _targetHoldSeconds * 1000;
      final p = (_currentHoldMilliseconds / totalTargetMs).clamp(0.0, 1.0);
      _holdProgressNotifier.value = p;

      tickCount++;
      if (tickCount % 5 == 0) {
        AudioFeedbackService.playHoldTick(p);
      }

      if (p >= 1.0) {
        _completeHold();
        timer.cancel();
      }
    });
  }

  void _completeHold() {
    _holdTickTimer?.cancel();
    AudioFeedbackService.playSuccess();
    setState(() {
      _isHolding = false;
      _successfulAttempts++;
      _score += (150 * widget.level.levelNumber);
      _holdProgressNotifier.value = 0.0;
      _currentHoldMilliseconds = 0;
    });

    if (_successfulAttempts >= _requiredAttempts) {
      _finishGame();
    }
  }

  void _failHold() {
    _holdTickTimer?.cancel();
    AudioFeedbackService.playError();
    setState(() {
      _isHolding = false;
      _failedAttempts++;
      _holdProgressNotifier.value = 0.0;
      _currentHoldMilliseconds = 0;
    });
  }

  void _finishGame() {
    _isGameOver = true;
    _gameTimer?.cancel();
    _holdTickTimer?.cancel();
    _inputService.stopWebcamTracking();
    AudioFeedbackService.playLevelComplete();

    final avgVariance = _holdSampleCount > 0
        ? (_accumulatedTremorVariance / _holdSampleCount) / 3.0
        : 10.0;

    final performance = PerformanceService.calculateMetrics(
      totalTargets: _requiredAttempts,
      successfulAttempts: _successfulAttempts,
      failedAttempts: _failedAttempts,
      durationSeconds: max(3, _elapsedGameSeconds),
      baseTargetDistance: 100.0,
      averageDeviation: avgVariance,
      stabilityVariance: avgVariance,
    );

    final patientId = context.read<AuthProvider>().activePatientId;
    context.read<ExerciseProvider>().completeExerciseSession(
          patientId: patientId,
          performance: performance,
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelCompletionScreen(
          exercise: widget.exercise,
          level: widget.level,
          performance: performance,
        ),
      ),
    );
  }

  void _retryLevel() {
    _gameTimer?.cancel();
    _holdTickTimer?.cancel();
    GameLauncher.launchGame(context, widget.exercise, widget.level);
  }

  void _goToNextLevel() {
    _gameTimer?.cancel();
    _holdTickTimer?.cancel();
    final allLevels = widget.exercise.levels;
    final currentIndex = allLevels.indexWhere((l) => l.levelNumber == widget.level.levelNumber);
    if (currentIndex >= 0 && currentIndex < allLevels.length - 1) {
      GameLauncher.launchGame(context, widget.exercise, allLevels[currentIndex + 1]);
    } else {
      _retryLevel();
    }
  }

  void _selectLevel(int lvlNum) {
    _gameTimer?.cancel();
    _holdTickTimer?.cancel();
    final target = widget.exercise.levels.firstWhere(
      (l) => l.levelNumber == lvlNum,
      orElse: () => widget.level,
    );
    GameLauncher.launchGame(context, widget.exercise, target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GameHud(
                exerciseTitle: widget.exercise.title,
                levelNumber: widget.level.levelNumber,
                score: _score,
                liveAccuracy: _currentAccuracy,
                elapsedSeconds: _elapsedGameSeconds,
                currentProgress: _successfulAttempts,
                totalProgress: _requiredAttempts,
                progressLabel: 'Holds Done',
                onExit: () => Navigator.of(context).pop(),
                onRetry: _retryLevel,
                onNextLevel: widget.level.levelNumber < widget.exercise.levels.length
                    ? _goToNextLevel
                    : null,
                onSelectLevel: _selectLevel,
                availableLevels: widget.exercise.levels.map((l) => l.levelNumber).toList(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bounds = Size(constraints.maxWidth, constraints.maxHeight);
                    _cachedBounds = bounds;

                    return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Webcam Live PiP Status
                            const Positioned(
                              top: 14,
                              right: 14,
                              child: WebcamPipView(),
                            ),

                            // Watermark / Instructions
                            Positioned(
                              top: 32,
                              child: Column(
                                children: [
                                  Text(
                                    'HOLD STABILIZER ORB FOR $_targetHoldSeconds SECONDS',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isHolding
                                        ? 'Keep steady inside the stability ring!'
                                        : 'Press and hold the glowing center orb',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _isHolding
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Outer Tolerance Boundary
                            Container(
                              width: 220 * widget.level.tolerance,
                              height: 220 * widget.level.tolerance,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isHolding
                                      ? AppColors.success.withOpacity(0.4)
                                      : AppColors.cyan.withOpacity(0.2),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),

                            // Middle Pulsing Ring
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final pulseScale =
                                    1.0 + (_pulseController.value * 0.08);
                                return Transform.scale(
                                  scale: _isHolding ? 1.0 : pulseScale,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isHolding
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.cyan.withOpacity(0.06),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Center Stabilizer Grip Orb
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _isHolding
                                    ? AppColors.successGradient
                                    : AppColors.cyanPurpleGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isHolding
                                            ? AppColors.success
                                            : AppColors.cyan)
                                        .withOpacity(0.45),
                                    blurRadius: _isHolding ? 24 : 12,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _isHolding
                                      ? Icons.lock_clock_rounded
                                      : Icons.fingerprint_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Bottom Hold Progress Display
                            Positioned(
                              bottom: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _holdProgressNotifier,
                                  builder: (context, progress, _) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Hold Progress',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 48),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _isHolding
                                                    ? AppColors.success
                                                    : AppColors.cyan,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 240,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: AppColors.border,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                _isHolding
                                                    ? AppColors.success
                                                    : AppColors.cyan,
                                              ),
                                              minHeight: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Real-time Virtual Hand & Finger Skeleton Overlay
                            VirtualHandCursor(
                              bounds: bounds,
                              targetPositions: const [Offset(0.5, 0.5)],
                              targetRadius: 80.0 * widget.level.tolerance,
                            ),
                          ],
                        ),
                      );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
