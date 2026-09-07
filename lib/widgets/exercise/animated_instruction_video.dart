import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/exercise.dart';

class AnimatedInstructionVideo extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseLevel level;

  const AnimatedInstructionVideo({
    super.key,
    required this.exercise,
    required this.level,
  });

  @override
  State<AnimatedInstructionVideo> createState() =>
      _AnimatedInstructionVideoState();
}

class _AnimatedInstructionVideoState extends State<AnimatedInstructionVideo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
        _isPlaying = false;
      } else {
        _controller.repeat();
        _isPlaying = true;
      }
    });
  }

  void _restart() {
    _controller.reset();
    _controller.repeat();
    setState(() => _isPlaying = true);
  }

  void _toggleSpeed() {
    setState(() {
      _playbackSpeed = _playbackSpeed == 1.0 ? 0.5 : 1.0;
      _controller.duration = Duration(
        milliseconds: (8000 / _playbackSpeed).round(),
      );
      if (_isPlaying) {
        _controller.repeat();
      }
    });
  }

  int get _currentStepIndex {
    final progress = _controller.value;
    final totalSteps = max(1, widget.exercise.tutorialSteps.length);
    final idx = (progress * totalSteps).floor();
    return idx.clamp(0, totalSteps - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Video Player Top Bar / Camera HUD Overlay
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.error.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'STEP TUTORIAL VIDEO',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.exercise.title} • Motion Guide',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VR-SIM 60 FPS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video Viewport Canvas
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Grid background lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridBackgroundPainter(),
                      ),
                    ),

                    // Demonstration animation per exercise
                    Positioned.fill(
                      child: _buildExerciseAnimation(_controller.value),
                    ),

                    // Active step overlay banner at top-center of video
                    Positioned(
                      top: 14,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cyan.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cyan,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'STEP ${_currentStepIndex + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.exercise
                                    .tutorialSteps[_currentStepIndex],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Video Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Scrubber Timeline
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = _controller.value;
                    final currentSeconds =
                        (progress * (8 / _playbackSpeed)).toStringAsFixed(1);
                    final totalSeconds =
                        (8 / _playbackSpeed).toStringAsFixed(1);

                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFF1F2937),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.cyan,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '00:${currentSeconds.padLeft(4, '0')}s',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '00:${totalSeconds.padLeft(4, '0')}s',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 4),

                // Playback Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: AppColors.cyan,
                            size: 32,
                          ),
                          tooltip: _isPlaying ? 'Pause Video' : 'Play Video',
                        ),
                        IconButton(
                          onPressed: _restart,
                          icon: const Icon(
                            Icons.replay_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                          tooltip: 'Replay from Start',
                        ),
                      ],
                    ),

                    // Slow motion toggle for rehabilitation patients
                    TextButton.icon(
                      onPressed: _toggleSpeed,
                      icon: const Icon(Icons.slow_motion_video_rounded,
                          size: 16, color: AppColors.cyan),
                      label: Text(
                        'Speed: ${_playbackSpeed}x',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseAnimation(double progress) {
    switch (widget.exercise.id) {
      case AppConstants.exercisePinching:
        return _buildPinchingDemo(progress);
      case AppConstants.exerciseHolding:
        return _buildHoldingDemo(progress);
      case AppConstants.exerciseTracing:
        return _buildTracingDemo(progress);
      case AppConstants.exerciseDragging:
        return _buildDraggingDemo(progress);
      case AppConstants.exerciseGesture:
      default:
        return _buildGestureDemo(progress);
    }
  }

  // Demo 1: Pinch Master Demonstration
  Widget _buildPinchingDemo(double progress) {
    // 0.0-0.3: Hand approaches target orb
    // 0.3-0.5: Hand pinches orb (glows cyan)
    // 0.5-0.8: Hand drags orb to portal on right
    // 0.8-1.0: Releases into portal with success burst
    final handX = progress < 0.3
        ? 0.15 + (progress / 0.3) * 0.20
        : (progress < 0.5
            ? 0.35
            : (progress < 0.8
                ? 0.35 + ((progress - 0.5) / 0.3) * 0.40
                : 0.75));

    final isPinching = progress >= 0.3 && progress <= 0.8;
    final isDropped = progress > 0.8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Target Portal on Right
            Positioned(
              left: w * 0.75 - 35,
              top: h * 0.55 - 35,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDropped
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.cyan.withOpacity(0.12),
                  border: Border.all(
                    color: isDropped ? AppColors.success : AppColors.cyan,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isDropped
                        ? Icons.check_circle_rounded
                        : Icons.input_rounded,
                    color: isDropped ? AppColors.success : AppColors.cyan,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Target Orb (carried by hand after pinch)
            if (!isDropped)
              Positioned(
                left: (isPinching ? handX : 0.35) * w - 18,
                top: h * 0.55 - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.cyanPurpleGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.5),
                        blurRadius: isPinching ? 14 : 6,
                      ),
                    ],
                  ),
                ),
              ),

            // Animated Virtual Hand
            Positioned(
              left: handX * w - 24,
              top: h * 0.55 - 24,
              child: Transform.scale(
                scale: isPinching ? 0.9 : 1.1,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: isPinching ? AppColors.cyan : Colors.white70,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPinching
                          ? Icons.pinch_rounded
                          : Icons.front_hand_rounded,
                      color: isPinching ? AppColors.cyan : Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Demo 2: Steady Hold Demonstration
  Widget _buildHoldingDemo(double progress) {
    final holdFraction = (progress * 1.25).clamp(0.0, 1.0);
    final isDone = holdFraction >= 1.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.cyan.withOpacity(0.1),
              border: Border.all(
                color: isDone ? AppColors.success : AppColors.cyan,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDone ? AppColors.success : AppColors.cyan)
                      .withOpacity(0.3),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isDone ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                size: 54,
                color: isDone ? AppColors.success : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isDone ? 'HOLD STABILITY: 100%' : 'MAINTAINING ISOMETRIC GRIP...',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDone ? AppColors.success : AppColors.cyan,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: holdFraction,
                backgroundColor: const Color(0xFF1F2937),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.success : AppColors.cyan,
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Demo 3: Path Trace Demonstration
  Widget _buildTracingDemo(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final tracerX = w * (0.2 + (progress * 0.6));
        final tracerY = (h * 0.55) + sin(progress * pi * 2) * (h * 0.22);

        return Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _DemoPathPainter(progress: progress),
            ),
            Positioned(
              left: tracerX - 16,
              top: tracerY - 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.8),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Demo 4: Shape Drag Demonstration
  Widget _buildDraggingDemo(double progress) {
    final dragFraction = (progress * 1.3).clamp(0.0, 1.0);
    final isSnapped = dragFraction >= 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final shapeX = (w * 0.25) + (dragFraction * (w * 0.5));
        final shapeY = h * 0.55;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Target Socket on Right
            Positioned(
              left: (w * 0.75) - 30,
              top: shapeY - 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSnapped
                      ? AppColors.success.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSnapped ? AppColors.success : Colors.white38,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.crop_square_rounded,
                    size: 32,
                    color: isSnapped ? AppColors.success : Colors.white30,
                  ),
                ),
              ),
            ),

            // Draggable Shape Token
            Positioned(
              left: shapeX - 25,
              top: shapeY - 25,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isSnapped
                      ? AppColors.successGradient
                      : AppColors.cyanPurpleGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isSnapped ? AppColors.success : AppColors.cyan)
                          .withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isSnapped
                        ? Icons.check_rounded
                        : Icons.crop_square_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Demo 5: Gesture Match Demonstration
  Widget _buildGestureDemo(double progress) {
    final poses = ['👍', '✌️', '🤏', '✋'];
    final poseIdx = (progress * poses.length).floor().clamp(0, poses.length - 1);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            poses[poseIdx],
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
            ),
            child: Text(
              'PROMPT MATCHED • 340ms REACTION',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937).withOpacity(0.35)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DemoPathPainter extends CustomPainter {
  final double progress;
  _DemoPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final corridorPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.15)
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(w * 0.2, h * 0.55);
    for (double x = w * 0.2; x <= w * 0.8; x += 10) {
      final t = (x - w * 0.2) / (w * 0.6);
      final y = (h * 0.55) + sin(t * pi * 2) * (h * 0.22);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, corridorPaint);

    // Illuminated trace line
    final tracePaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, tracePaint);
  }

  @override
  bool shouldRepaint(covariant _DemoPathPainter oldDelegate) => true;
}
