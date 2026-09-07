import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color deepNavy = Color(0xFF172554);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color purple = Color(0xFF7C3AED);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Backgrounds & Neutrals
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF0F172A);
  static const Color darkCardSurface = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFF8FAFC);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color darkBorder = Color(0xFF334155);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF172554), Color(0xFF1E1B4B), Color(0xFF311042)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanPurpleGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
