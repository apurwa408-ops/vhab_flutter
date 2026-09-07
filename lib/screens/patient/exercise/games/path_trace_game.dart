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

class PathTraceGame extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const PathTraceGame({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<PathTraceGame> createState() => _PathTraceGameState();
}

class _PathTraceGameState extends State<PathTraceGame> {
  final HandTrackingInputService _inputService = HandTrackingInputService.instance;

  // Zero-setState path tracking: CustomPainter listens directly to this ValueNotifier
  final ValueNotifier<List<Offset>> _userPathNotifier = ValueNotifier([]);
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);
  final List<Offset> _referenceWaypoints = [];

  bool _isTracing = false;
  bool _hasStarted = false;
  bool _isGameOver = false;

  int _score = 0;
  int _offPathErrors = 0;
  int _elapsedSeconds = 0;
  Timer? _gameTimer;

  double _totalDeviation = 0.0;
  int _sampleCount = 0;
  int _lastTickSample = 0;
  Size _cachedBounds = const Size(800, 600);

  @override
  void initState() {
    super.initState();
    _startGameTimer();
    _inputService.addListener(_onCameraFrame);
    _inputService.startWebcamTracking();
  }

  void _onCameraFrame() {
    if (!mounted || _isGameOver || !_inputService.isHandDetected || _referenceWaypoints.isEmpty) return;

    final pos = _inputService.normalizedPosition;
    final localPos = Offset(
      pos.dx * _cachedBounds.width,
      pos.dy * _cachedBounds.height,
    );

    final startPt = _referenceWaypoints.first;
    final distToStart = (localPos - startPt).distance;

    if (!_isTracing && distToStart <= 65.0) {
      _hasStarted = true;
      _isTracing = true;
      _userPathNotifier.value = [localPos];
      AudioFeedbackService.playPinch();
    } else if (_isTracing) {
      _processTracePoint(localPos);
    }
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _inputService.stopWebcamTracking();
    _inputService.removeListener(_onCameraFrame);
    _gameTimer?.cancel();
    _userPathNotifier.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  void _generateWaypoints(Size size) {
    if (_referenceWaypoints.isNotEmpty) return;
    final lvl = widget.level.levelNumber;
    final w = size.width;
    final h = size.height;

    switch (lvl) {
      case 1: // Straight bridge
        _referenceWaypoints.addAll([
          Offset(w * 0.12, h * 0.5),
          Offset(w * 0.88, h * 0.5),
        ]);
        break;
      case 2: // Zigzag mountain pass
        _referenceWaypoints.addAll([
          Offset(w * 0.15, h * 0.35),
          Offset(w * 0.38, h * 0.72),
          Offset(w * 0.62, h * 0.28),
          Offset(w * 0.85, h * 0.65),
        ]);
        break;
      case 3: // S-Curve river of light
        _referenceWaypoints.addAll([
          Offset(w * 0.12, h * 0.25),
          Offset(w * 0.32, h * 0.75),
          Offset(w * 0.68, h * 0.25),
          Offset(w * 0.88, h * 0.75),
        ]);
        break;
      case 4: // Sine-wave rollercoaster
        _referenceWaypoints.addAll([
          Offset(w * 0.12, h * 0.50),
          Offset(w * 0.30, h * 0.22),
          Offset(w * 0.50, h * 0.78),
          Offset(w * 0.70, h * 0.22),
          Offset(w * 0.88, h * 0.50),
        ]);
        break;
      case 5: // 5-segment complex winding labyrinth
      default:
        _referenceWaypoints.addAll([
          Offset(w * 0.12, h * 0.30),
          Offset(w * 0.30, h * 0.75),
          Offset(w * 0.50, h * 0.25),
          Offset(w * 0.70, h * 0.80),
          Offset(w * 0.88, h * 0.35),
        ]);
        break;
    }
  }

  double get _currentAccuracy {
    if (_sampleCount == 0) return 100.0;
    final avgDev = _totalDeviation / _sampleCount;
    final acc = (100.0 - (avgDev * 1.5) - (_offPathErrors * 2.0)).clamp(30.0, 99.0);
    return double.parse(acc.toStringAsFixed(1));
  }

  double _minDistanceToWaypoints(Offset p) {
    if (_referenceWaypoints.length < 2) return 0.0;
    double minD = double.infinity;
    for (int i = 0; i < _referenceWaypoints.length - 1; i++) {
      final a = _referenceWaypoints[i];
      final b = _referenceWaypoints[i + 1];
      final d = _distToSegment(p, a, b);
      if (d < minD) minD = d;
    }
    return minD;
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final l2 = pow(b.dx - a.dx, 2) + pow(b.dy - a.dy, 2);
    if (l2 == 0) return (p - a).distance;
    final t = max(0, min(1, ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2));
    final projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - projection).distance;
  }

  void _processTracePoint(Offset localPos) {
    if (_isGameOver || !_isTracing || _referenceWaypoints.isEmpty) return;

    final currentList = _userPathNotifier.value;
    if (currentList.isNotEmpty) {
      final lastPoint = currentList.last;
      // Sub-sample to keep point count compact and eliminate CPU lag
      if ((localPos - lastPoint).distance < 4.5) return;
    }

    final dev = _minDistanceToWaypoints(localPos);
    final corridorWidth = 44.0 * widget.level.tolerance;

    // Append point without calling setState!
    final updatedList = List<Offset>.from(currentList)..add(localPos);
    _userPathNotifier.value = updatedList;

    _totalDeviation += dev;
    _sampleCount++;

    if (dev > corridorWidth) {
      _offPathErrors++;
      if (_sampleCount % 10 == 0) {
        AudioFeedbackService.playError();
      }
    } else {
      if (_sampleCount - _lastTickSample >= 14) {
        _lastTickSample = _sampleCount;
        AudioFeedbackService.playHoldTick(_progressNotifier.value);
      }
    }

    final startX = _referenceWaypoints.first.dx;
    final endX = _referenceWaypoints.last.dx;
    final pct = ((localPos.dx - startX) / (endX - startX)).clamp(0.0, 1.0);
    _progressNotifier.value = pct;

    // Check distance to end portal
    final endPoint = _referenceWaypoints.last;
    final distToEnd = (localPos - endPoint).distance;

    if (distToEnd <= 52.0 && updatedList.length > 12) {
      _finishGame();
    }
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

  void _finishGame() {
    if (_isGameOver) return;
    _isGameOver = true;
    _isTracing = false;
    _gameTimer?.cancel();
    _inputService.stopWebcamTracking();
    _score = (120 * widget.level.levelNumber) + (_currentAccuracy * 2).toInt();

    AudioFeedbackService.playSuccess();
    AudioFeedbackService.playLevelComplete();

    final avgDev = _sampleCount > 0 ? _totalDeviation / _sampleCount : 8.0;

    final performance = PerformanceService.calculateMetrics(
      totalTargets: max(1, _referenceWaypoints.length - 1),
      successfulAttempts: 1,
      failedAttempts: _offPathErrors > 5 ? 1 : 0,
      durationSeconds: max(3, _elapsedSeconds),
      baseTargetDistance: 400.0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top HUD with integrated Retry & Next Level buttons
              GameHud(
                exerciseTitle: widget.exercise.title,
                levelNumber: widget.level.levelNumber,
                score: _score,
                liveAccuracy: _currentAccuracy,
                elapsedSeconds: _elapsedSeconds,
                currentProgress: (_progressNotifier.value * 100).toInt(),
                totalProgress: 100,
                progressLabel: 'Path %',
                onExit: () => Navigator.of(context).pop(),
                onRetry: _retryLevel,
                onNextLevel: widget.level.levelNumber < widget.exercise.levels.length
                    ? _goToNextLevel
                    : null,
                onSelectLevel: _selectLevel,
                availableLevels: widget.exercise.levels.map((l) => l.levelNumber).toList(),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    _cachedBounds = size;
                    _generateWaypoints(size);

                    return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // ── Background Holographic Static Path ──
                            CustomPaint(
                              size: size,
                              painter: _StaticCorridorPainter(
                                waypoints: _referenceWaypoints,
                                tolerance: widget.level.tolerance,
                              ),
                            ),

                            // ── Zero-Lag Dynamic Traced Path Layer ──
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: _DynamicTracePainter(
                                  pathNotifier: _userPathNotifier,
                                ),
                              ),
                            ),

                            // Webcam Live PiP
                            const Positioned(
                              top: 14,
                              right: 14,
                              child: WebcamPipView(),
                            ),

                            // Guide Title & Quick Reset Pill
                            Positioned(
                              top: 18,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.touch_app_rounded,
                                        size: 16, color: AppColors.cyan),
                                    const SizedBox(width: 8),
                                    Text(
                                      !_hasStarted
                                          ? 'MOVE FINGER TO GREEN START GATE'
                                          : 'TRACE ALONG THE NEON CORRIDOR',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Real-time Virtual Hand & Finger Skeleton Overlay
                            VirtualHandCursor(
                              bounds: size,
                              targetPositions: _referenceWaypoints.isNotEmpty
                                  ? [
                                      Offset(
                                        _referenceWaypoints.last.dx / size.width,
                                        _referenceWaypoints.last.dy / size.height,
                                      )
                                    ]
                                  : null,
                              targetRadius: 44.0,
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

// ─────────────────────────────────────────────────────────────
// Static Corridor Painter: draws waypoints, corridor, portals once
// ─────────────────────────────────────────────────────────────
class _StaticCorridorPainter extends CustomPainter {
  final List<Offset> waypoints;
  final double tolerance;

  _StaticCorridorPainter({
    required this.waypoints,
    required this.tolerance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.length < 2) return;

    final corridorWidth = 42.0 * tolerance;

    // Outer glow aura
    final corridorGlow = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.12)
      ..strokeWidth = corridorWidth * 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final corridorBody = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.25)
      ..strokeWidth = corridorWidth * 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(waypoints.first.dx, waypoints.first.dy);
    for (int i = 1; i < waypoints.length; i++) {
      path.lineTo(waypoints[i].dx, waypoints[i].dy);
    }
    canvas.drawPath(path, corridorGlow);
    canvas.drawPath(path, corridorBody);

    // Neon centerline
    final centerLinePaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, centerLinePaint);

    // Checkpoint nodes
    for (int i = 1; i < waypoints.length - 1; i++) {
      final cp = waypoints[i];
      canvas.drawCircle(
        cp,
        14,
        Paint()..color = const Color(0xFF06B6D4).withOpacity(0.3),
      );
      canvas.drawCircle(
        cp,
        7,
        Paint()..color = Colors.white,
      );
    }

    // Start Portal (Neon Emerald)
    final startPt = waypoints.first;
    canvas.drawCircle(
      startPt,
      30,
      Paint()..color = const Color(0xFF10B981).withOpacity(0.25),
    );
    canvas.drawCircle(startPt, 22, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(
      startPt,
      22,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Start Icon/Label
    final tpStart = TextPainter(
      text: const TextSpan(
        text: 'START',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpStart.paint(canvas, Offset(startPt.dx - tpStart.width / 2, startPt.dy - tpStart.height / 2));

    // End Portal (Neon Fuchsia)
    final endPt = waypoints.last;
    canvas.drawCircle(
      endPt,
      30,
      Paint()..color = const Color(0xFFD946EF).withOpacity(0.25),
    );
    canvas.drawCircle(endPt, 22, Paint()..color = const Color(0xFFD946EF));
    canvas.drawCircle(
      endPt,
      22,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final tpEnd = TextPainter(
      text: const TextSpan(
        text: 'GOAL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEnd.paint(canvas, Offset(endPt.dx - tpEnd.width / 2, endPt.dy - tpEnd.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StaticCorridorPainter old) =>
      old.tolerance != tolerance || old.waypoints != waypoints;
}

// ─────────────────────────────────────────────────────────────
// Dynamic Trace Painter: repaints only the traced polyline at 60fps
// Zero MaskFilter.blur, pure layered alpha strokes for ultimate speed
// ─────────────────────────────────────────────────────────────
class _DynamicTracePainter extends CustomPainter {
  final ValueNotifier<List<Offset>> pathNotifier;

  _DynamicTracePainter({required this.pathNotifier})
      : super(repaint: pathNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final points = pathNotifier.value;
    if (points.length < 2) return;

    // Outer luminous glow line (strokeWidth 10, alpha layered, zero blur)
    final glowPaint = Paint()
      ..color = const Color(0xFFF43F5E).withOpacity(0.35)
      ..strokeWidth = 11
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Core bright neon trace line
    final corePaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final userTrace = Path();
    userTrace.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      userTrace.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(userTrace, glowPaint);
    canvas.drawPath(userTrace, corePaint);

    // Glowing tip orb at active finger location
    final tip = points.last;
    canvas.drawCircle(
      tip,
      12,
      Paint()..color = const Color(0xFFF43F5E).withOpacity(0.35),
    );
    canvas.drawCircle(
      tip,
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _DynamicTracePainter old) => false;
}
