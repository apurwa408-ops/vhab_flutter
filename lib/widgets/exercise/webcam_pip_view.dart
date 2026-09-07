import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/hand_tracking_input_service.dart';

class WebcamPipView extends StatefulWidget {
  const WebcamPipView({super.key});

  @override
  State<WebcamPipView> createState() => _WebcamPipViewState();
}

class _WebcamPipViewState extends State<WebcamPipView> {
  final HandTrackingInputService _service = HandTrackingInputService.instance;

  @override
  void initState() {
    super.initState();
    // Automatically attempt camera tracking if on web
    _service.startWebcamTracking();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final isActive = _service.isWebcamActive;
        final isDetected = _service.isHandDetected;
        final gesture = _service.activeGesture;
        final isPinching = _service.isPinching;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDetected ? AppColors.success : AppColors.border,
              width: isDetected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera Live Indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (isDetected ? AppColors.success : AppColors.warning)
                      : AppColors.error,
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: (isDetected ? AppColors.success : AppColors.warning)
                            .withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'WEBCAM TRACKING',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isActive && isDetected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isPinching
                                ? AppColors.purple.withOpacity(0.15)
                                : AppColors.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPinching
                                ? 'PINCHING 🤏'
                                : gesture.toUpperCase().replaceAll('_', ' '),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isPinching
                                  ? AppColors.purple
                                  : AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isActive
                        ? (isDetected
                            ? 'Hand in frame • Ready'
                            : 'Raise hand into camera view')
                        : 'Camera paused (Touch/Click enabled)',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDetected
                          ? AppColors.success
                          : (isActive
                              ? AppColors.textSecondary
                              : AppColors.textMuted),
                      fontWeight: isDetected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Action button: Toggle PiP Preview or Start/Stop
              IconButton(
                onPressed: () {
                  if (!isActive) {
                    _service.startWebcamTracking();
                  } else {
                    _service.togglePip();
                  }
                },
                icon: Icon(
                  isActive
                      ? (_service.isPipVisible
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded)
                      : Icons.play_arrow_rounded,
                  size: 18,
                  color: isActive ? AppColors.cyan : AppColors.textSecondary,
                ),
                tooltip: isActive
                    ? 'Toggle Video Skeleton Preview'
                    : 'Start Webcam Tracking',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(28, 28),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
