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

class PinchTarget {
  final int id;
  Offset position;
  final double radius;
  bool isCompleted;
  bool isSelected;

  PinchTarget({
    required this.id,
    required this.position,
    required this.radius,
    this.isCompleted = false,
    this.isSelected = false,
  });
}

class PinchMasterGame extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const PinchMasterGame({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<PinchMasterGame> createState() => _PinchMasterGameState();
}

class _PinchMasterGameState extends State<PinchMasterGame> {
  final HandTrackingInputService _inputService = HandTrackingInputService.instance;
  final List<PinchTarget> _targets = [];
  PinchTarget? _activeTarget;
  final Offset _portalPosition = const Offset(0.8, 0.5);

  int _score = 0;
  int _successfulAttempts = 0;
  int _failedAttempts = 0;
  int _elapsedSeconds = 0;
  Timer? _gameTimer;
  bool _isGameOver = false;

  final Random _random = Random();
  double _totalDeviation = 0.0;
  int _interactionSamples = 0;

  bool _wasPinching = false;
  Size _cachedBounds = const Size(800, 600);

  /// Tracks which target is nearest the hand — updated without setState.
  /// Only target widgets listen to this, not the whole game tree.
  final ValueNotifier<int?> _nearTargetId = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _initLevel();
    _startGameTimer();
    _inputService.addListener(_onCameraFrame);
    _inputService.startWebcamTracking();
  }

  void _onCameraFrame() {
    if (!mounted || _isGameOver) return;

    // ── Proximity update (no setState — uses ValueNotifier) ──
    if (_inputService.isHandDetected) {
      final handPx = Offset(
        _inputService.normalizedPosition.dx * _cachedBounds.width,
        _inputService.normalizedPosition.dy * _cachedBounds.height,
      );
      int? nearId;
      double nearDist = double.infinity;
      for (final t in _targets) {
        if (t.isCompleted) continue;
        final tPx = Offset(
          t.position.dx * _cachedBounds.width,
          t.position.dy * _cachedBounds.height,
        );
        final d = (handPx - tPx).distance;
        if (d < nearDist) { nearDist = d; nearId = t.id; }
      }
      final threshold = (_targets.isEmpty ? 44.0 : _targets.first.radius) * 3.0;
      _nearTargetId.value = (nearDist < threshold) ? nearId : null;
    } else {
      _nearTargetId.value = null;
    }

    if (!_inputService.isHandDetected) return;

    // ── Input events (only on state change) ──
    final pos = _inputService.normalizedPosition;
    final localPos = Offset(
      pos.dx * _cachedBounds.width,
      pos.dy * _cachedBounds.height,
    );
    final isPinch = _inputService.isPinching;

    if (isPinch && !_wasPinching) {
      _wasPinching = true;
      _onPointerDown(localPos, _cachedBounds);
    } else if (isPinch && _wasPinching) {
      _onPointerMoveDrag(localPos, _cachedBounds); // no setState unless dragging
    } else if (!isPinch && _wasPinching) {
      _wasPinching = false;
      _onPointerUp(localPos, _cachedBounds);
    }
    // No else branch — idle movement needs NO setState
  }

  @override
  void dispose() {
    _inputService.stopWebcamTracking();
    _inputService.removeListener(_onCameraFrame);
    _gameTimer?.cancel();
    _nearTargetId.dispose();
    super.dispose();
  }

  void _initLevel() {
    _targets.clear();
    final count = widget.level.targetCount;
    // Radius decreases by level
    final double radius = (48.0 - (widget.level.levelNumber * 4.0))
        .clamp(24.0, 48.0);

    for (int i = 0; i < count; i++) {
      // Keep targets on the left/middle area, portal on right
      final x = 0.15 + (_random.nextDouble() * 0.45);
      final y = 0.20 + (_random.nextDouble() * 0.60);
      _targets.add(PinchTarget(
        id: i,
        position: Offset(x, y),
        radius: radius,
      ));
    }
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }



  double get _currentAccuracy {
    final total = _successfulAttempts + _failedAttempts;
    if (total == 0) return 100.0;
    return (_successfulAttempts / total) * 100.0;
  }

  void _onPointerDown(Offset localPos, Size bounds) {
    if (_isGameOver) return;
    _inputService.updatePointer(localPos, bounds, isPressed: true);

    // Check if clicked near an uncompleted target
    for (final target in _targets.where((t) => !t.isCompleted)) {
      final targetPix = Offset(
        target.position.dx * bounds.width,
        target.position.dy * bounds.height,
      );
      final dist = (localPos - targetPix).distance;

      if (dist <= target.radius * 1.5) {
        AudioFeedbackService.playPinch();
        setState(() {
          target.isSelected = true;
          _activeTarget = target;
        });
        break;
      }
    }
  }

  void _onPointerMoveDrag(Offset localPos, Size bounds) {
    if (_isGameOver) return;
    if (_activeTarget != null) {
      // Only setState when actively dragging a target ball
      setState(() {
        _activeTarget!.position = Offset(
          (localPos.dx / bounds.width).clamp(0.05, 0.95),
          (localPos.dy / bounds.height).clamp(0.05, 0.95),
        );
      });
      _interactionSamples++;
    }
  }


  void _onPointerUp(Offset localPos, Size bounds) {
    if (_isGameOver || _activeTarget == null) return;

    final portalPix = Offset(
      _portalPosition.dx * bounds.width,
      _portalPosition.dy * bounds.height,
    );
    final distToPortal = (localPos - portalPix).distance;
    final portalRadius = 55.0 * widget.level.tolerance;

    setState(() {
      if (distToPortal <= portalRadius) {
        // Success
        AudioFeedbackService.playSuccess();
        _activeTarget!.isCompleted = true;
        _activeTarget!.isSelected = false;
        _successfulAttempts++;
        _score += (100 * widget.level.levelNumber);
        _totalDeviation += distToPortal;
      } else {
        // Drop failed
        AudioFeedbackService.playError();
        _activeTarget!.isSelected = false;
        _failedAttempts++;
      }
      _activeTarget = null;
    });

    _inputService.updatePointer(localPos, bounds, isPressed: false);
    _checkLevelCompletion();
  }

  void _checkLevelCompletion() {
    final completedCount = _targets.where((t) => t.isCompleted).length;
    if (completedCount >= widget.level.targetCount) {
      _finishGame();
    }
  }

  void _finishGame() {
    _isGameOver = true;
    _gameTimer?.cancel();
    _inputService.stopWebcamTracking();
    AudioFeedbackService.playLevelComplete();

    final avgDev = _interactionSamples > 0
        ? _totalDeviation / max(1, _successfulAttempts)
        : 12.0;

    final performance = PerformanceService.calculateMetrics(
      totalTargets: widget.level.targetCount,
      successfulAttempts: _successfulAttempts,
      failedAttempts: _failedAttempts,
      durationSeconds: max(3, _elapsedSeconds),
      baseTargetDistance: 250.0,
      averageDeviation: avgDev,
      stabilityVariance: 100.0 - _inputService.currentState.stabilityIndex,
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
    GameLauncher.launchGame(context, widget.exercise, widget.level);
  }

  void _goToNextLevel() {
    _gameTimer?.cancel();
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
    final target = widget.exercise.levels.firstWhere(
      (l) => l.levelNumber == lvlNum,
      orElse: () => widget.level,
    );
    GameLauncher.launchGame(context, widget.exercise, target);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _targets.where((t) => t.isCompleted).length;

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
                elapsedSeconds: _elapsedSeconds,
                currentProgress: completedCount,
                totalProgress: widget.level.targetCount,
                progressLabel: 'Pinches',
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
                          children: [
                            // Webcam Live PiP Status Bar
                            const Positioned(
                              top: 14,
                              right: 14,
                              child: WebcamPipView(),
                            ),

                            // Background Instruction / Watermark
                            Center(
                              child: Text(
                                'PINCH & DRAG TO PORTAL',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.deepNavy.withOpacity(0.04),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            // Destination Portal
                            Positioned(
                              left: _portalPosition.dx * bounds.width - 55,
                              top: _portalPosition.dy * bounds.height - 55,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan.withOpacity(0.12),
                                  border: Border.all(
                                    color: AppColors.cyan,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cyan.withOpacity(0.2),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.input_rounded,
                                        color: AppColors.cyan,
                                        size: 28,
                                      ),
                                      Text(
                                        'RELEASE',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.deepNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Targets – ValueListenableBuilder isolates proximity
                            // repaints to only the affected target widget.
                            ..._targets.map((target) {
                              if (target.isCompleted) {
                                return const SizedBox.shrink();
                              }
                              final r = target.radius;
                              return Positioned(
                                left: target.position.dx * bounds.width - r,
                                top: target.position.dy * bounds.height - r,
                                child: ValueListenableBuilder<int?>(
                                  valueListenable: _nearTargetId,
                                  builder: (context, nearId, _) {
                                    final isNear = nearId == target.id;
                                    final isSelected = target.isSelected;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: r * 2,
                                      height: r * 2,
                                      transform: Matrix4.identity()
                                        ..scale(isNear ? 1.22 : 1.0),
                                      transformAlignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: isSelected
                                            ? AppColors.cyanPurpleGradient
                                            : (isNear
                                                ? const LinearGradient(colors: [
                                                    Color(0xFF22C55E),
                                                    Color(0xFF06B6D4),
                                                  ])
                                                : const LinearGradient(colors: [
                                                    Color(0xFF06B6D4),
                                                    Color(0xFF0284C7),
                                                  ])),
                                        border: Border.all(
                                          color: Colors.white
                                              .withOpacity(isNear ? 1.0 : 0.7),
                                          width: isNear ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isSelected
                                                    ? AppColors.purple
                                                    : isNear
                                                        ? AppColors.success
                                                        : AppColors.cyan)
                                                .withOpacity(isNear ? 0.7 : 0.4),
                                            blurRadius: isNear ? 24 : 8,
                                            spreadRadius: isNear ? 3 : 0,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isNear
                                              ? Icons.touch_app_rounded
                                              : Icons.pinch_rounded,
                                          size: r * 0.85,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),

                            // Cursor — self-contained CustomPainter, no wrapper needed
                            VirtualHandCursor(
                              bounds: bounds,
                              targetPositions: _targets
                                  .where((t) => !t.isCompleted)
                                  .map((t) => t.position)
                                  .toList(),
                              targetRadius: _targets.isNotEmpty
                                  ? _targets.first.radius
                                  : 44.0,
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
