import 'package:flutter/material.dart';

class NexusColors {
  NexusColors._();

  static const Color primary      = Color(0xFF185FA5);
  static const Color primaryLight = Color(0xFFE6F1FB);
  static const Color primaryText  = Color(0xFF0C447C);

  static const Color success      = Color(0xFF3B6D11);
  static const Color successLight = Color(0xFFEAF3DE);
  static const Color successText  = Color(0xFF27500A);

  static const Color warning      = Color(0xFFBA7517);
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color warningText  = Color(0xFF633806);

  static const Color danger       = Color(0xFFE24B4A);
  static const Color dangerLight  = Color(0xFFFCEBEB);
  static const Color dangerText   = Color(0xFF791F1F);

  static const Color neutral      = Color(0xFF5F5E5A);
  static const Color neutralLight = Color(0xFFF1EFE8);
  static const Color neutralText  = Color(0xFF444441);

  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceAlt   = Color(0xFFF5F5F3);
  static const Color border       = Color(0xFFE8E6DF);
  static const Color borderStrong = Color(0xFFD3D1C7);

  static const Color ink         = Color(0xFF1A1A18);
  static const Color inkSecondary = Color(0xFF5F5E5A);
  static const Color inkTertiary  = Color(0xFF9C9A94);
}

class NexusSizes {
  NexusSizes._();

  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 12.0;
  static const double spaceLG  = 16.0;
  static const double spaceXL  = 20.0;
  static const double space2XL = 24.0;
  static const double space3XL = 32.0;

  static const double radiusSM   = 6.0;
  static const double radiusMD   = 8.0;
  static const double radiusLG   = 12.0;
  static const double radiusFull = 999.0;

  static const double borderWidth = 0.5;
}

class NexusText {
  NexusText._();

  static const TextStyle heading1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: NexusColors.ink);
  static const TextStyle heading2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: NexusColors.ink);
  static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: NexusColors.ink);
  static const TextStyle body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: NexusColors.ink);
  static const TextStyle small    = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: NexusColors.ink);
  static const TextStyle caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: NexusColors.inkSecondary);
  static const TextStyle label    = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: NexusColors.inkSecondary);
}

ThemeData nexusTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: NexusColors.surfaceAlt,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NexusColors.primary,
      brightness: Brightness.light,
      surface: NexusColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: NexusColors.surface,
      foregroundColor: NexusColors.ink,
      titleTextStyle: NexusText.heading3,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NexusColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        side: const BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NexusColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.danger, width: NexusSizes.borderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.danger, width: 1.5),
      ),
      labelStyle: NexusText.small.copyWith(color: NexusColors.inkSecondary),
      hintStyle: NexusText.small.copyWith(color: NexusColors.inkTertiary),
      errorStyle: NexusText.caption.copyWith(color: NexusColors.danger),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NexusColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: NexusColors.border,
      thickness: NexusSizes.borderWidth,
      space: 0,
    ),
  );
}

// Componentes reutilizables

Widget nexusEstadoBadge(String texto, {required Color bg, required Color textColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
    ),
    child: Text(
      texto,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
    ),
  );
}

Widget nexusCard({required Widget child, EdgeInsets? padding}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(NexusSizes.spaceLG),
    decoration: BoxDecoration(
      color: NexusColors.surface,
      border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
      borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
    ),
    child: child,
  );
}
