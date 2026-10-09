import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VKU brand color — Navy Blue
const _kSeedColor = Color(0xFF2C4570);

class AppTheme {
  AppTheme._();

  // ── Light Theme ──────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _kSeedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(cs);
  }

  // ── Dark Theme ───────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _kSeedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(cs);
  }

  static ThemeData _buildTheme(ColorScheme cs) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: cs.onSurface,
        displayColor: cs.onSurface,
      ),
    );

    return base.copyWith(
      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cs.surfaceContainerLow,
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: cs.primaryContainer,
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (s) => GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        selectedColor: cs.primaryContainer,
        labelStyle: GoogleFonts.outfit(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
