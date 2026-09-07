import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RehabMotionPanel extends StatefulWidget {
  const RehabMotionPanel({super.key});

  @override
  State<RehabMotionPanel> createState() => _RehabMotionPanelState();
}

class _RehabMotionPanelState extends State<RehabMotionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = 1.0 + math.sin(_controller.value * math.pi * 2) * 0.025;
          return Transform.scale(
            scale: pulse,
            child: SvgPicture.asset(
              'assets/hand_rehab_reference.svg',
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
