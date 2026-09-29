import 'package:flutter/material.dart';

abstract final class Cores {
  static const fundo = Color(0xFFF3F6FB);
  static const painel = Color(0xFFF8FAFD);
  static const papel = Color(0xFFFFFFFF);
  static const tinta = Color(0xFF1C1915);
  static const suave = Color(0xFF64748B);
  static const linha = Color(0xFFE2E8F0);
  static const azul = Color(0xFF2563EB);
  static const azulSuave = Color(0xFFDBE7FF);
}

ThemeData temaPrestador() {
  const borda = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: Cores.linha),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Cores.fundo,
    colorScheme: const ColorScheme.light(
      primary: Cores.azul,
      onPrimary: Colors.white,
      surface: Cores.papel,
      onSurface: Cores.tinta,
      secondary: Cores.tinta,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        color: Cores.tinta,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: Cores.tinta,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Cores.tinta,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: Cores.tinta),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(color: Cores.suave, fontSize: 13),
      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: borda,
      enabledBorder: borda,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Cores.azul, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Cores.azul,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Color(0xFFE2E8F0),
        disabledForegroundColor: Color(0xFF94A3B8),
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Cores.tinta),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Cores.azulSuave,
      side: const BorderSide(color: Cores.linha),
      labelStyle: const TextStyle(
        color: Cores.tinta,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}
