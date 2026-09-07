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

class GestureItem {
  final String id;
  final String emoji;
  final String name;

  const GestureItem({
    required this.id,
    required this.emoji,
    required this.name,
  });
}

class GestureMatchGame extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const GestureMatchGame({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<GestureMatchGame> createState() => _GestureMatchGameState();
}

class _GestureMatchGameState extends State<GestureMatchGame> {
  final HandTrackingInputService _inputService = HandTrackingInputService.instance;

  static const List<GestureItem> _allGestures = [
    GestureItem(id: 'open_hand', emoji: '✋', name: 'Open Palm'),
    GestureItem(id: 'pinch', emoji: '🤏', name: 'Pinch Opposition'),
    GestureItem(id: 'fist', emoji: '✊', name: 'Closed Fist'),
    GestureItem(id: 'thumbs_up', emoji: '👍', name: 'Thumbs Up'),
    GestureItem(id: 'peace', emoji: '✌️', name: 'Peace / V-Sign'),
    GestureItem(id: 'point', emoji: '☝️', name: 'Index Point'),
  ];

  late List<GestureItem> _levelGestures;
  late GestureItem _targetGesture;

  int _score = 0;
  int _successfulMatches = 0;
  final int _failedMatches = 0;
  int _elapsedSeconds = 0;
  Timer? _gameTimer;
  DateTime _gesturePromptTime = DateTime.now();

  final List<int> _reactionTimes = [];
  bool _isGameOver = false;
  bool _showSuccessFlash = false;
  bool _isTransitioning = false;
  bool _gameHasStarted = false;

  final Random _random = Random();
  String _liveGesture = 'open_hand';
  Size _cachedBounds = const Size(800, 600);

  @override
  void initState() {
    super.initState();
    _initLevel();
    _startGameTimer();
    _inputService.addListener(_onCameraFrame);
    _inputService.startWebcamTracking();
  }

  void _onCameraFrame() {
    if (!mounted || _isGameOver || _isTransitioning) return;
    if (_inputService.isHandDetected) _gameHasStarted = true;

    final detectedGesture = _inputService.activeGesture;
    if (_liveGesture != detectedGesture) {
      setState(() {
        _liveGesture = detectedGesture;
      });
    }

    // Auto-match when camera detects the exact requested physical gesture!
    if (_inputService.isHandDetected && detectedGesture == _targetGesture.id) {
      _triggerMatch(detectedGesture);
    }
  }

  void _initLevel() {
    final count = min(widget.level.targetCount + 2, _allGestures.length);
    _levelGestures = _allGestures.take(count).toList();
    _nextGesture();
  }

  void _nextGesture() {
    setState(() {
      _targetGesture = _levelGestures[_random.nextInt(_levelGestures.length)];
      _gesturePromptTime = DateTime.now();
      _isTransitioning = false;
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_gameHasStarted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _inputService.stopWebcamTracking();
    _inputService.removeListener(_onCameraFrame);
    _gameTimer?.cancel();
    super.dispose();
  }

  double get _currentAccuracy {
    final total = _successfulMatches + _failedMatches;
    if (total == 0) return 100.0;
    return (_successfulMatches / total) * 100.0;
  }

  void _triggerMatch(String gestureId) {
    if (_isTransitioning || _isGameOver) return;
    _isTransitioning = true;

    final reactionMs =
        DateTime.now().difference(_gesturePromptTime).inMilliseconds;
    _reactionTimes.add(reactionMs);

    AudioFeedbackService.playGestureMatch();

    setState(() {
      _successfulMatches++;
      _score += (150 * widget.level.levelNumber);
      _showSuccessFlash = true;
    });

    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _showSuccessFlash = false);

      if (_successfulMatches >= widget.level.targetCount) {
        _finishGame();
      } else {
        _nextGesture();
      }
    });
  }


  void _finishGame() {
    _isGameOver = true;
    _gameTimer?.cancel();
    _inputService.stopWebcamTracking();
    AudioFeedbackService.playLevelComplete();

    final avgReaction = _reactionTimes.isNotEmpty
        ? (_reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length)
        : 450;

    final performance = PerformanceService.calculateMetrics(
      totalTargets: widget.level.targetCount,
      successfulAttempts: _successfulMatches,
      failedAttempts: _failedMatches,
      durationSeconds: max(3, _elapsedSeconds),
      baseTargetDistance: 100.0,
      averageDeviation: 6.0,
      stabilityVariance: 10.0,
      measuredReactionTimeMs: avgReaction,
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
                currentProgress: _successfulMatches,
                totalProgress: widget.level.targetCount,
                progressLabel: 'Matches',
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
                    _cachedBounds = Size(constraints.maxWidth, constraints.maxHeight);

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
                          // Webcam Live PiP
                          const Positioned(
                            top: 14,
                            right: 14,
                            child: WebcamPipView(),
                          ),

                          // Main Content Layout
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  'PERFORM THIS HAND GESTURE TO CAMERA',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Target Gesture Hologram Orb
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 175,
                                  height: 175,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: _showSuccessFlash
                                        ? const LinearGradient(
                                            colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                                          )
                                        : const LinearGradient(
                                            colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_showSuccessFlash
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF06B6D4))
                                            .withOpacity(0.4),
                                        blurRadius: 28,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _targetGesture.emoji,
                                          style: const TextStyle(fontSize: 68),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _targetGesture.name.toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Real-time Camera Feedback Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _inputService.isHandDetected
                                        ? const Color(0xFF10B981).withOpacity(0.15)
                                        : const Color(0xFFEF4444).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _inputService.isHandDetected
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _inputService.isHandDetected
                                            ? Icons.sensors_rounded
                                            : Icons.sensors_off_rounded,
                                        size: 18,
                                        color: _inputService.isHandDetected
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _inputService.isHandDetected
                                            ? 'LIVE HAND DETECTED: ${_liveGesture.replaceAll('_', ' ').toUpperCase()}'
                                            : 'NO HAND DETECTED — RAISE HAND',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _inputService.isHandDetected
                                              ? const Color(0xFF047857)
                                              : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Interactive Gesture Cards Grid
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 16,
                                  runSpacing: 14,
                                  children: _levelGestures.map((gesture) {
                                    final isTarget = gesture.id == _targetGesture.id;
                                    final isDetected = _liveGesture == gesture.id;

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 130,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isDetected
                                            ? LinearGradient(
                                                colors: [
                                                  const Color(0xFF10B981).withOpacity(0.2),
                                                  const Color(0xFF06B6D4).withOpacity(0.2),
                                                ],
                                              )
                                            : null,
                                        color: isDetected
                                            ? null
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDetected
                                              ? const Color(0xFF10B981)
                                              : (isTarget
                                                  ? const Color(0xFF06B6D4)
                                                  : AppColors.border),
                                          width: isDetected || isTarget ? 2.5 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isDetected
                                                    ? const Color(0xFF10B981)
                                                    : AppColors.cyan)
                                                .withOpacity(isDetected ? 0.3 : 0.05),
                                            blurRadius: isDetected ? 14 : 4,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            gesture.emoji,
                                            style: const TextStyle(fontSize: 38),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            gesture.name,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDetected
                                                  ? const Color(0xFF10B981)
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),

                                const Spacer(),
                              ],
                            ),
                          ),

                          // Real-time Virtual Hand & Finger Skeleton Overlay
                          VirtualHandCursor(
                            bounds: _cachedBounds,
                            targetRadius: 75.0,
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
