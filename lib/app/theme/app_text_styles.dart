import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system: Manrope for headings, Inter for body/labels.
abstract class AppTextStyles {
  // ── Manrope headings ───────────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.02 * 40,
        color: color,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.01 * 32,
        color: color,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // ── Inter body ─────────────────────────────────────────────────────────────
  static TextStyle bodyLg({Color? color}) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle labelMd({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.01 * 14,
        color: color,
      );

  static TextStyle labelSm({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.05,
        color: color,
      );

  // ── Material 3 text theme mapping ─────────────────────────────────────────
  static TextTheme buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: h1(color: onSurface),
      displayMedium: h2(color: onSurface),
      displaySmall: h3(color: onSurface),
      headlineLarge: h2(color: onSurface),
      headlineMedium: h3(color: onSurface),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyLarge: bodyLg(color: onSurface),
      bodyMedium: bodyMd(color: onSurface),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelLarge: labelMd(color: onSurface),
      labelMedium: labelMd(color: onSurfaceVariant),
      labelSmall: labelSm(color: onSurfaceVariant),
    );
  }
}
