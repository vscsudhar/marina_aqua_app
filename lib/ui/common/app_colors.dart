import 'package:flutter/material.dart';

// SS AquaFlow Theme Colors - Ocean & Crystal Water Identity
const Color kcPrimaryColor = Color(0xFF0284C7); // Vivid Sky Blue
const Color kcPrimaryDark = Color(0xFF0369A1); // Deep Ocean Blue
const Color kcPrimaryLight = Color(0xFF38BDF8); // Crystal Aqua Blue

const Color kcAquaCyan = Color(0xFF06B6D4); // Bright Cyan
const Color kcAquaTeal = Color(0xFF0D9488); // Deep Teal
const Color kcAquaMint = Color(0xFF10B981); // Emerald / Success

const Color kcDeepNavy = Color(0xFF0B192C); // Dark Background / Navy Surface
const Color kcDarkSlate = Color(0xFF1E293B); // Card Background Dark
const Color kcMediumGrey = Color(0xFF64748B); // Slate Muted Text
const Color kcLightGrey = Color(0xFF94A3B8); // Border & Placeholder
const Color kcVeryLightGrey = Color(0xFFF1F5F9); // Light Gray Background

const Color kcBackgroundColor = Color(0xFFF8FAFC); // Clean Canvas Background
const Color kcSurfaceWhite = Color(0xFFFFFFFF);
const Color kcTextPrimary = Color(0xFF0F172A);
const Color kcTextSecondary = Color(0xFF475569);
const Color kcTextMuted = Color(0xFF94A3B8);

const Color kcBorderColor = Color(0xFFE2E8F0);
const Color kcErrorColor = Color(0xFFEF4444);
const Color kcWarningColor = Color(0xFFF59E0B);
const Color kcSuccessColor = Color(0xFF10B981);

// Modern Gradients
const LinearGradient kcOceanGradient = LinearGradient(
  colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF06B6D4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kcHeroDarkGradient = LinearGradient(
  colors: [Color(0xFF0B192C), Color(0xFF1E293B), Color(0xFF0F172A)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const LinearGradient kcGlassGradient = LinearGradient(
  colors: [Colors.white24, Colors.white10],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

abstract class AppColors {
  static const Color primary = kcPrimaryColor;
  static const Color primaryDark = kcPrimaryDark;
  static const Color primaryLight = kcPrimaryLight;
  static const Color accent = kcAquaCyan;
  static const Color background = kcBackgroundColor;
  static const Color surface = kcSurfaceWhite;
  static const Color border = kcBorderColor;
  static const Color textPrimary = kcTextPrimary;
  static const Color textSecondary = kcTextSecondary;
  static const Color textMuted = kcTextMuted;
  static const Color error = kcErrorColor;
  static const Color warning = kcWarningColor;
  static const Color success = kcSuccessColor;
}
