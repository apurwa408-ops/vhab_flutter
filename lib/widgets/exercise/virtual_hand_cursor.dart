import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/hand_tracking_input_service.dart';

/// High-performance holographic hand and finger tracker cursor.
///
/// Optimized for Web: zero MaskFilter.blur rasterization bottlenecks, pure hardware-accelerated
/// alpha-layered strokes inside an isolated RepaintBoundary.
class VirtualHandCursor extends StatefulWidget {
  final Size bounds;
  final List<Offset>? targetPositions;
  final double targetRadius;

  const VirtualHandCursor({
    super.key,
    required this.bounds,
    this.targetPositions,
    this.targetRadius = 44.0,
  });

  @override
  State<VirtualHandCursor> createState() => _VirtualHandCursorState();
}

class _VirtualHandCursorState extends State<VirtualHandCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: widget.bounds,
        painter: _HandCursorPainter(
          service: HandTrackingInputService.instance,
          pulseCtrl: _pulseCtrl,
          targetPositions: widget.targetPositions ?? const [],
          targetRadius: widget.targetRadius,
          repaint: Listenable.merge(
              [HandTrackingInputService.instance, _pulseCtrl]),
        ),
      ),
    );
  }
}

class _HandCursorPainter extends CustomPainter {
  final HandTrackingInputService service;
  final AnimationController pulseCtrl;
  final List<Offset> targetPositions;
  final double targetRadius;

  _HandCursorPainter({
    required this.service,
    required this.pulseCtrl,
    required this.targetPositions,
    required this.targetRadius,
    required super.repaint,
  });

  // MediaPipe hand skeleton connections (joint indices 0..20)
  static const List<List<int>> _fingerChains = [
    [0, 1, 2, 3, 4],       // Thumb
    [0, 5, 6, 7, 8],       // Index
    [9, 10, 11, 12],       // Middle
    [13, 14, 15, 16],      // Ring
    [0, 17, 18, 19, 20],   // Pinky
  ];

  static const List<List<int>> _palmConnections = [
    [5, 9],
    [9, 13],
    [13, 17],
    [0, 5],
    [0, 9],
    [0, 13],
    [0, 17],
  ];

  static const List<int> _fingertips = [4, 8, 12, 16, 20];

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = pulseCtrl.value;

    if (!service.isHandDetected) {
      _paintSearching(canvas, size, pulse);
      return;
    }

    final pos = service.normalizedPosition;
    final px = pos.dx * size.width;
    final py = pos.dy * size.height;
    final isPinching = service.isPinching;
    final handPt = Offset(px, py);

    // ── 1. Draw Live Hand Skeleton (Bones & Joints) ──
    final landmarks = service.landmarks;
    if (landmarks.length >= 21) {
      final pixelPts = landmarks.map((lm) {
        return Offset(lm.dx * size.width, lm.dy * size.height);
      }).toList();

      _paintHandSkeleton(canvas, pixelPts, pulse, isPinching);
    }

    // ── 2. Target Proximity Lock-On ──
    double? nearestDist;
    Offset? nearestPx;
    for (final t in targetPositions) {
      final tpx = Offset(t.dx * size.width, t.dy * size.height);
      final d = (handPt - tpx).distance;
      if (nearestDist == null || d < nearestDist) {
        nearestDist = d;
        nearestPx = tpx;
      }
    }

    final isNear = nearestDist != null && nearestDist < targetRadius * 2.5;
    if (isNear && nearestPx != null) {
      _paintLockRing(canvas, nearestPx, pulse, isPinching);
    }

    // ── 3. Pointer Crosshair Cursor ──
    _paintCursor(canvas, handPt, pulse, isPinching, isNear);
  }

  void _paintHandSkeleton(
      Canvas canvas, List<Offset> pts, double pulse, bool isPinching) {
    final baseColor = isPinching
        ? const Color(0xFFD946EF) // Electric Fuchsia when pinching
        : const Color(0xFF06B6D4); // Cyber Cyan

    final glowColor = isPinching
        ? const Color(0xFFA855F7)
        : const Color(0xFF0EA5E9);

    final bonePaint = Paint()
      ..color = baseColor.withOpacity(0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final boneGlow = Paint()
      ..color = glowColor.withOpacity(0.18)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw finger bone lines with layered alpha glow (zero blur cost)
    for (final chain in _fingerChains) {
      for (int i = 0; i < chain.length - 1; i++) {
        final p1 = pts[chain[i]];
        final p2 = pts[chain[i + 1]];
        canvas.drawLine(p1, p2, boneGlow);
        canvas.drawLine(p1, p2, bonePaint);
      }
    }

    // Draw palm webbing
    for (final conn in _palmConnections) {
      final p1 = pts[conn[0]];
      final p2 = pts[conn[1]];
      canvas.drawLine(p1, p2, bonePaint);
    }

    // Pinch electric spark line connecting thumb tip (4) & index tip (8)
    if (isPinching) {
      final thumbTip = pts[4];
      final indexTip = pts[8];
      final pinchLine = Paint()
        ..color = const Color(0xFFF43F5E)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      final pinchGlow = Paint()
        ..color = const Color(0xFFF43F5E).withOpacity(0.25)
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(thumbTip, indexTip, pinchGlow);
      canvas.drawLine(thumbTip, indexTip, pinchLine);
    }

    // Draw joint nodes
    final jointPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final jointOutline = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < pts.length; i++) {
      final pt = pts[i];
      final isFingertip = _fingertips.contains(i);

      if (isFingertip) {
        // Fingertip glowing orb
        final tipColor = (i == 4 || i == 8) && isPinching
            ? const Color(0xFFF43F5E)
            : baseColor;

        canvas.drawCircle(
          pt,
          8.0 + pulse * 2.0,
          Paint()..color = tipColor.withOpacity(0.22),
        );
        canvas.drawCircle(
          pt,
          5.0,
          Paint()..color = tipColor,
        );
        canvas.drawCircle(
          pt,
          2.0,
          Paint()..color = Colors.white,
        );
      } else {
        // Standard knuckle joint
        canvas.drawCircle(pt, 3.0, jointPaint);
        canvas.drawCircle(pt, 3.0, jointOutline);
      }
    }
  }

  void _paintSearching(Canvas canvas, Size size, double pulse) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 3; i++) {
      final phase = (pulse + i / 3.0) % 1.0;
      final r = phase * 80.0;
      final opacity = (1.0 - phase) * 0.4;
      if (opacity <= 0) continue;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = AppColors.cyan.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      26,
      Paint()..color = AppColors.deepNavy.withOpacity(0.8),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      26,
      Paint()
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '✋ Raise hand in front of camera',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7 + pulse * 0.3),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 36));
  }

  void _paintLockRing(
      Canvas canvas, Offset center, double pulse, bool isPinching) {
    final r = targetRadius + 12 + pulse * 8;
    final color = isPinching ? const Color(0xFFD946EF) : const Color(0xFF22C55E);

    canvas.drawCircle(
      center,
      r + 4,
      Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      r - 6,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _paintCursor(Canvas canvas, Offset pt, double pulse, bool isPinching,
      bool isNear) {
    final color = isPinching
        ? const Color(0xFFD946EF)
        : (isNear ? const Color(0xFF22C55E) : const Color(0xFF06B6D4));

    final ringR = isPinching ? 28.0 + pulse * 5 : 22.0 + pulse * 3;

    // Outer glow ring
    canvas.drawCircle(
      pt,
      ringR + 6,
      Paint()
        ..color = color.withOpacity(0.15 + pulse * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // Main ring
    canvas.drawCircle(
      pt,
      ringR,
      Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isPinching ? 3.0 : 2.0,
    );

    // Center interactive dot
    canvas.drawCircle(
      pt,
      isPinching ? 8.0 : 4.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      pt,
      isPinching ? 3.0 : 2.0,
      Paint()..color = Colors.white,
    );

    // Dynamic crosshairs
    const gap = 8.0;
    const len = 12.0;
    final lp = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pt.dx, pt.dy - gap), Offset(pt.dx, pt.dy - gap - len), lp);
    canvas.drawLine(Offset(pt.dx, pt.dy + gap), Offset(pt.dx, pt.dy + gap + len), lp);
    canvas.drawLine(Offset(pt.dx - gap, pt.dy), Offset(pt.dx - gap - len, pt.dy), lp);
    canvas.drawLine(Offset(pt.dx + gap, pt.dy), Offset(pt.dx + gap + len, pt.dy), lp);
  }

  @override
  bool shouldRepaint(_HandCursorPainter old) => true;
}
