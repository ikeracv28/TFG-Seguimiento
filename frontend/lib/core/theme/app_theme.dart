import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/seguimiento_model.dart';

// ── Paleta estática (modo claro) ──────────────────────────────────────────────

class NexusColors {
  NexusColors._();

  static const Color primary      = Color(0xFF185FA5);
  static const Color primaryLight = Color(0xFFEFF4FF);
  static const Color primaryText  = Color(0xFF0C447C);

  static const Color success      = Color(0xFF3B6D11);
  static const Color successLight = Color(0xFFEAF3DE);
  static const Color successText  = Color(0xFF27500A);

  static const Color warning      = Color(0xFFBA7517);
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color warningText  = Color(0xFF633806);

  static const Color danger       = Color(0xFFBA1A1A);
  static const Color dangerLight  = Color(0xFFFFDAD6);
  static const Color dangerText   = Color(0xFF93000A);

  static const Color neutral      = Color(0xFF424751);
  static const Color neutralLight = Color(0xFFE5EEFF);
  static const Color neutralText  = Color(0xFF0B1C30);

  // Capas de superficie (Stitch "Layered White" con tinte azul)
  static const Color surface               = Color(0xFFFFFFFF);
  static const Color surfaceAlt            = Color(0xFFF8F9FF);
  static const Color surfaceContainerLow   = Color(0xFFEFF4FF);
  static const Color surfaceContainer      = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh  = Color(0xFFDCE9FF);

  static const Color border       = Color(0xFFC2C6D2);
  static const Color borderStrong = Color(0xFF727782);

  static const Color ink          = Color(0xFF0B1C30);
  static const Color inkSecondary = Color(0xFF424751);
  static const Color inkTertiary  = Color(0xFF727782);
}

// ── Paleta estática modo oscuro ───────────────────────────────────────────────

class NexusDarkColors {
  NexusDarkColors._();

  static const Color surface               = Color(0xFF1A1D22);
  static const Color surfaceAlt            = Color(0xFF12151A);
  static const Color surfaceContainerLow   = Color(0xFF1E2535);
  static const Color surfaceContainer      = Color(0xFF222A3C);
  static const Color border                = Color(0xFF2C3244);
  static const Color borderStrong          = Color(0xFF3C4255);
  static const Color ink                   = Color(0xFFE8EEFF);
  static const Color inkSecondary          = Color(0xFFA4AABC);
  static const Color inkTertiary           = Color(0xFF6B7289);
  static const Color primary               = Color(0xFF5BA8F5);
  static const Color primaryLight          = Color(0xFF1A2D4A);
}

// ── ThemeExtension: colores adaptativos accesibles via contexto ───────────────

@immutable
class NexusThemeExt extends ThemeExtension<NexusThemeExt> {
  const NexusThemeExt({
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.primaryColor,
    required this.primaryLight,
  });

  final Color surface;
  final Color surfaceAlt;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color border;
  final Color borderStrong;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color primaryColor;
  final Color primaryLight;

  static const NexusThemeExt light = NexusThemeExt(
    surface:             NexusColors.surface,
    surfaceAlt:          NexusColors.surfaceAlt,
    surfaceContainerLow: NexusColors.surfaceContainerLow,
    surfaceContainer:    NexusColors.surfaceContainer,
    border:              NexusColors.border,
    borderStrong:        NexusColors.borderStrong,
    ink:                 NexusColors.ink,
    inkSecondary:        NexusColors.inkSecondary,
    inkTertiary:         NexusColors.inkTertiary,
    primaryColor:        NexusColors.primary,
    primaryLight:        NexusColors.primaryLight,
  );

  static const NexusThemeExt dark = NexusThemeExt(
    surface:             NexusDarkColors.surface,
    surfaceAlt:          NexusDarkColors.surfaceAlt,
    surfaceContainerLow: NexusDarkColors.surfaceContainerLow,
    surfaceContainer:    NexusDarkColors.surfaceContainer,
    border:              NexusDarkColors.border,
    borderStrong:        NexusDarkColors.borderStrong,
    ink:                 NexusDarkColors.ink,
    inkSecondary:        NexusDarkColors.inkSecondary,
    inkTertiary:         NexusDarkColors.inkTertiary,
    primaryColor:        NexusDarkColors.primary,
    primaryLight:        NexusDarkColors.primaryLight,
  );

  @override
  NexusThemeExt copyWith({
    Color? surface, Color? surfaceAlt, Color? surfaceContainerLow, Color? surfaceContainer,
    Color? border, Color? borderStrong,
    Color? ink, Color? inkSecondary, Color? inkTertiary,
    Color? primaryColor, Color? primaryLight,
  }) => NexusThemeExt(
    surface:             surface             ?? this.surface,
    surfaceAlt:          surfaceAlt          ?? this.surfaceAlt,
    surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
    surfaceContainer:    surfaceContainer    ?? this.surfaceContainer,
    border:              border              ?? this.border,
    borderStrong:        borderStrong        ?? this.borderStrong,
    ink:                 ink                 ?? this.ink,
    inkSecondary:        inkSecondary        ?? this.inkSecondary,
    inkTertiary:         inkTertiary         ?? this.inkTertiary,
    primaryColor:        primaryColor        ?? this.primaryColor,
    primaryLight:        primaryLight        ?? this.primaryLight,
  );

  @override
  NexusThemeExt lerp(NexusThemeExt? other, double t) {
    if (other == null) return this;
    return NexusThemeExt(
      surface:             Color.lerp(surface,             other.surface,             t)!,
      surfaceAlt:          Color.lerp(surfaceAlt,          other.surfaceAlt,          t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer:    Color.lerp(surfaceContainer,    other.surfaceContainer,    t)!,
      border:              Color.lerp(border,              other.border,              t)!,
      borderStrong:        Color.lerp(borderStrong,        other.borderStrong,        t)!,
      ink:                 Color.lerp(ink,                 other.ink,                 t)!,
      inkSecondary:        Color.lerp(inkSecondary,        other.inkSecondary,        t)!,
      inkTertiary:         Color.lerp(inkTertiary,         other.inkTertiary,         t)!,
      primaryColor:        Color.lerp(primaryColor,        other.primaryColor,        t)!,
      primaryLight:        Color.lerp(primaryLight,        other.primaryLight,        t)!,
    );
  }
}

// ── Extensión de BuildContext para acceso corto ───────────────────────────────

extension NexusBuildContextExt on BuildContext {
  NexusThemeExt get nxt =>
      Theme.of(this).extension<NexusThemeExt>() ?? NexusThemeExt.light;
}

// ── Tipografía (SIN color — lo provee el tema) ────────────────────────────────

class NexusText {
  NexusText._();

  static const TextStyle heading1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static const TextStyle heading2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle small    = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  static const TextStyle caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle label    = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6);
}

// ── Tamaños ───────────────────────────────────────────────────────────────────

class NexusSizes {
  NexusSizes._();

  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 12.0;
  static const double spaceLG  = 16.0;
  static const double spaceXL  = 20.0;
  static const double space2XL = 24.0;
  static const double space3XL = 32.0;
  static const double space4XL = 40.0;

  static const double radiusSM   = 6.0;
  static const double radiusMD   = 8.0;
  static const double radiusLG   = 12.0;
  static const double radiusXL   = 16.0;
  static const double radiusFull = 999.0;

  static const double borderWidth = 1.0;
}

// ── Temas ─────────────────────────────────────────────────────────────────────

ThemeData nexusTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    scaffoldBackgroundColor: NexusColors.surfaceAlt,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NexusColors.primary,
      brightness: Brightness.light,
      surface: NexusColors.surface,
    ),
    extensions: const [NexusThemeExt.light],
    textTheme: const TextTheme(
      displayLarge:   NexusText.heading1,
      headlineMedium: NexusText.heading2,
      titleLarge:     NexusText.heading3,
      bodyLarge:      NexusText.body,
      bodyMedium:     NexusText.small,
      bodySmall:      NexusText.caption,
      labelSmall:     NexusText.label,
    ).apply(bodyColor: NexusColors.ink, displayColor: NexusColors.ink),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: NexusColors.surface,
      foregroundColor: NexusColors.ink,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: NexusColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NexusColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
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
      hintStyle: const TextStyle(fontSize: 13, color: NexusColors.inkTertiary),
      errorStyle: const TextStyle(fontSize: 12, color: NexusColors.danger),
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
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: NexusColors.border,
      thickness: NexusSizes.borderWidth,
      space: 0,
    ),
  );
}

ThemeData nexusDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NexusDarkColors.surfaceAlt,
    colorScheme: ColorScheme.dark(
      primary:                  NexusDarkColors.primary,
      onPrimary:                const Color(0xFF0A2A4A),
      surface:                  NexusDarkColors.surface,
      onSurface:                NexusDarkColors.ink,
      surfaceContainerHighest:  NexusDarkColors.surfaceAlt,
      outline:                  NexusDarkColors.border,
      outlineVariant:           NexusDarkColors.borderStrong,
    ),
    extensions: const [NexusThemeExt.dark],
    textTheme: const TextTheme(
      displayLarge:   NexusText.heading1,
      headlineMedium: NexusText.heading2,
      titleLarge:     NexusText.heading3,
      bodyLarge:      NexusText.body,
      bodyMedium:     NexusText.small,
      bodySmall:      NexusText.caption,
      labelSmall:     NexusText.label,
    ).apply(bodyColor: NexusDarkColors.ink, displayColor: NexusDarkColors.ink),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: NexusDarkColors.surface,
      foregroundColor: NexusDarkColors.ink,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: NexusDarkColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NexusDarkColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        side: const BorderSide(color: NexusDarkColors.border, width: NexusSizes.borderWidth),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NexusDarkColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusDarkColors.border, width: NexusSizes.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusDarkColors.border, width: NexusSizes.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusDarkColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.danger, width: NexusSizes.borderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        borderSide: const BorderSide(color: NexusColors.danger, width: 1.5),
      ),
      hintStyle: const TextStyle(fontSize: 13, color: NexusDarkColors.inkTertiary),
      errorStyle: const TextStyle(fontSize: 12, color: NexusColors.danger),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NexusDarkColors.primary,
        foregroundColor: const Color(0xFF0A2A4A),
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: NexusDarkColors.border,
      thickness: NexusSizes.borderWidth,
      space: 0,
    ),
  );
}

// ── Componentes reutilizables ─────────────────────────────────────────────────

Widget nexusEstadoBadge(String texto, {required Color bg, required Color textColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
    ),
    child: Text(
      texto,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
    ),
  );
}

Widget nexusCard({required Widget child, EdgeInsets? padding, BuildContext? context}) {
  final ext = context != null
      ? (Theme.of(context).extension<NexusThemeExt>() ?? NexusThemeExt.light)
      : NexusThemeExt.light;
  return Container(
    padding: padding ?? const EdgeInsets.all(NexusSizes.spaceLG),
    decoration: BoxDecoration(
      color: ext.surface,
      border: Border.all(color: ext.border, width: NexusSizes.borderWidth),
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
    ),
    child: child,
  );
}

// ── Formateo de horas con soporte de medias horas ─────────────────────────────
// Ej: 7.0 → "7h" | 7.5 → "7h 30min" | 0.5 → "30min"
String fmtH(num h) {
  if (h == h.truncate()) return '${h.toInt()}h';
  final enteras = h.truncate();
  return enteras == 0 ? '30min' : '${enteras}h 30min';
}

// ── Formateo de fecha de seguimiento según tipo ────────────────────────────────
// DIARIO: "12 may 26" | SEMANAL: "Sem. 12-16 may 26"
String fmtSeguimientoFecha(Seguimiento s) {
  if (s.esSemanal) {
    final viernes = s.fechaRegistro.add(const Duration(days: 4));
    final ini = DateFormat('d MMM', 'es_ES').format(s.fechaRegistro);
    final fin = DateFormat('d MMM yy', 'es_ES').format(viernes);
    return 'Sem. $ini-$fin';
  }
  return DateFormat('d MMM yy', 'es_ES').format(s.fechaRegistro);
}
