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

enum RehabShapeType {
  circle,
  square,
  triangle,
  star,
  hexagon,
}

class RehabShapeItem {
  final int id;
  final RehabShapeType type;
  final String label;
  final IconData icon;
  final Color color;
  Offset currentPos;
  bool isPlaced;
  bool isGrabbed;

  RehabShapeItem({
    required this.id,
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.currentPos,
    this.isPlaced = false,
    this.isGrabbed = false,
  });
}

class ShapeSlot {
  final RehabShapeType type;
  final Offset position;
  final double radius;
  bool isFilled;

  ShapeSlot({
    required this.type,
    required this.position,
    required this.radius,
    this.isFilled = false,
  });
}

class ShapeDragGame extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const ShapeDragGame({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<ShapeDragGame> createState() => _ShapeDragGameState();
}

class _ShapeDragGameState extends State<ShapeDragGame> {
  final HandTrackingInputService _inputService = HandTrackingInputService.instance;
  final List<RehabShapeItem> _items = [];
  final List<ShapeSlot> _slots = [];
  RehabShapeItem? _draggingItem;

  int _score = 0;
  int _successfulPlacements = 0;
  int _failedPlacements = 0;
  int _elapsedSeconds = 0;
  Timer? _gameTimer;
  bool _isGameOver = false;

  bool _wasPinching = false;
  Size _cachedBounds = const Size(800, 600);

  @override
  void initState() {
    super.initState();
    _initShapesAndSlots();
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
    final isPinch = _inputService.isPinching;

    if (isPinch && !_wasPinching) {
      _wasPinching = true;
      _onPointerDown(localPos, _cachedBounds);
    } else if (isPinch && _wasPinching) {
      _onPointerMoveDrag(localPos, _cachedBounds);
    } else if (!isPinch && _wasPinching) {
      _wasPinching = false;
      _onPointerUp(localPos, _cachedBounds);
    }
  }

  void _initShapesAndSlots() {
    _items.clear();
    _slots.clear();

    final count = widget.level.targetCount;
    final allShapes = [
      (RehabShapeType.circle, 'Circle', Icons.circle, const Color(0xFF06B6D4)),
      (RehabShapeType.square, 'Square', Icons.square_rounded, const Color(0xFF8B5CF6)),
      (RehabShapeType.triangle, 'Triangle', Icons.change_history_rounded, const Color(0xFFF59E0B)),
      (RehabShapeType.star, 'Star', Icons.star_rounded, const Color(0xFF10B981)),
      (RehabShapeType.hexagon, 'Hexagon', Icons.hexagon_rounded, const Color(0xFFEC4899)),
    ];

    final activeDefs = allShapes.take(min(count, allShapes.length)).toList();

    for (int i = 0; i < activeDefs.length; i++) {
      final def = activeDefs[i];
      final yFactor = 0.22 + (i * 0.14);

      // Shapes start on the left
      _items.add(RehabShapeItem(
        id: i,
        type: def.$1,
        label: def.$2,
        icon: def.$3,
        color: def.$4,
        currentPos: Offset(0.20, yFactor),
      ));

      // Slots wait on the right
      _slots.add(ShapeSlot(
        type: def.$1,
        position: Offset(0.80, yFactor),
        radius: 46.0 * widget.level.tolerance,
      ));
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
    super.dispose();
  }

  double get _currentAccuracy {
    final total = _successfulPlacements + _failedPlacements;
    if (total == 0) return 100.0;
    return (_successfulPlacements / total) * 100.0;
  }

  void _onPointerDown(Offset localPos, Size bounds) {
    if (_isGameOver) return;
    _inputService.updatePointer(localPos, bounds, isPressed: true);

    for (final item in _items.where((i) => !i.isPlaced)) {
      final itemPix = Offset(
        item.currentPos.dx * bounds.width,
        item.currentPos.dy * bounds.height,
      );
      if ((localPos - itemPix).distance <= 60.0) {
        AudioFeedbackService.playPinch();
        setState(() {
          item.isGrabbed = true;
          _draggingItem = item;
        });
        break;
      }
    }
  }

  void _onPointerMoveDrag(Offset localPos, Size bounds) {
    if (_isGameOver) return;
    if (_draggingItem != null) {
      setState(() {
        _draggingItem!.currentPos = Offset(
          (localPos.dx / bounds.width).clamp(0.05, 0.95),
          (localPos.dy / bounds.height).clamp(0.05, 0.95),
        );
      });
    }
  }


  void _onPointerUp(Offset localPos, Size bounds) {
    if (_isGameOver || _draggingItem == null) return;
    _inputService.updatePointer(localPos, bounds, isPressed: false);

    final item = _draggingItem!;
    bool matched = false;

    for (final slot in _slots.where((s) => !s.isFilled)) {
      final slotPix = Offset(
        slot.position.dx * bounds.width,
        slot.position.dy * bounds.height,
      );
      final dist = (localPos - slotPix).distance;

      if (dist <= slot.radius) {
        if (slot.type == item.type) {
          // Successful match!
          matched = true;
          AudioFeedbackService.playSuccess();
          setState(() {
            item.isPlaced = true;
            item.isGrabbed = false;
            item.currentPos = slot.position;
            slot.isFilled = true;
            _successfulPlacements++;
            _score += (120 * widget.level.levelNumber);
          });
          break;
        }
      }
    }

    if (!matched) {
      // Failed placement or mismatch
      AudioFeedbackService.playError();
      setState(() {
        _failedPlacements++;
        item.isGrabbed = false;
        final index = _items.indexOf(item);
        item.currentPos = Offset(0.20, 0.22 + (index * 0.14));
      });
    }

    _draggingItem = null;
    _checkLevelCompletion();
  }

  void _checkLevelCompletion() {
    final filledSlots = _slots.where((s) => s.isFilled).length;
    if (filledSlots >= _slots.length) {
      _finishGame();
    }
  }

  void _finishGame() {
    _isGameOver = true;
    _gameTimer?.cancel();
    _inputService.stopWebcamTracking();
    AudioFeedbackService.playLevelComplete();

    final performance = PerformanceService.calculateMetrics(
      totalTargets: _slots.length,
      successfulAttempts: _successfulPlacements,
      failedAttempts: _failedPlacements,
      durationSeconds: max(3, _elapsedSeconds),
      baseTargetDistance: 300.0,
      averageDeviation: 12.0,
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
                currentProgress: _successfulPlacements,
                totalProgress: _slots.length,
                progressLabel: 'Shapes',
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

                            // Watermark Guide
                            Center(
                              child: Text(
                                'PINCH SHAPE & DRAG TO MATCHING SLOT',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.deepNavy.withOpacity(0.04),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            // Target Slots (Right side)
                            ..._slots.map((slot) {
                              final sx = slot.position.dx * bounds.width;
                              final sy = slot.position.dy * bounds.height;
                              final r = slot.radius;

                              return Positioned(
                                left: sx - r,
                                top: sy - r,
                                child: Container(
                                  width: r * 2,
                                  height: r * 2,
                                  decoration: BoxDecoration(
                                    color: slot.isFilled
                                        ? const Color(0xFF10B981).withOpacity(0.18)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: slot.isFilled
                                          ? const Color(0xFF10B981)
                                          : AppColors.cyan.withOpacity(0.35),
                                      width: 2.5,
                                    ),
                                    boxShadow: slot.isFilled
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withOpacity(0.35),
                                              blurRadius: 16,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: AppColors.cyan.withOpacity(0.08),
                                              blurRadius: 10,
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getIconForType(slot.type),
                                      size: r * 0.9,
                                      color: slot.isFilled
                                          ? const Color(0xFF10B981)
                                          : AppColors.cyan.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Draggable Shapes (Left side / live dragged)
                            ..._items.map((item) {
                              final ix = item.currentPos.dx * bounds.width;
                              final iy = item.currentPos.dy * bounds.height;
                              final size = item.isGrabbed ? 80.0 : 70.0;

                              return Positioned(
                                left: ix - (size / 2),
                                top: iy - (size / 2),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        item.color,
                                        item.color.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: item.isGrabbed ? 3.0 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.color.withOpacity(item.isGrabbed ? 0.6 : 0.35),
                                        blurRadius: item.isGrabbed ? 24 : 12,
                                        spreadRadius: item.isGrabbed ? 3 : 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      item.icon,
                                      size: item.isGrabbed ? 44 : 38,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Real-time Virtual Hand & Finger Skeleton Overlay
                            VirtualHandCursor(
                              bounds: bounds,
                              targetPositions: _items
                                  .where((i) => !i.isPlaced)
                                  .map((i) => i.currentPos)
                                  .toList(),
                              targetRadius: 46.0,
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

  IconData _getIconForType(RehabShapeType type) {
    switch (type) {
      case RehabShapeType.circle:
        return Icons.circle_outlined;
      case RehabShapeType.square:
        return Icons.crop_square_rounded;
      case RehabShapeType.triangle:
        return Icons.change_history_rounded;
      case RehabShapeType.star:
        return Icons.star_border_rounded;
      case RehabShapeType.hexagon:
        return Icons.hexagon_outlined;
    }
  }
}
