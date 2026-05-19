import 'package:flutter/material.dart';

/// Variante visual del logo.
/// [dark]  → logo sobre fondo claro  (versión oscura del logo)
/// [light] → logo sobre fondo oscuro (badge blanco sobre fondo oscuro)
enum NexusLogoVariant { dark, light }

/// Paths centralizados de los assets de branding — única fuente de verdad.
class NexusBranding {
  NexusBranding._();

  static const String logoPath    = 'assets/branding/logo-nexus.png';
  static const String isotipoPath = 'assets/branding/isotipo-nexus.png';
}

// ── NexusLogo ────────────────────────────────────────────────────────────────
/// Logo completo de Nexus (wordmark + símbolo).
/// Úsalo en: sidebar expandido, login, headers, estados vacíos.
///
/// [height]    → altura en px (el ancho se ajusta automáticamente).
/// [variant]   → dark (sobre fondo claro) | light (sobre fondo oscuro).
/// [clickable] → si es true muestra cursor pointer y envuelve en GestureDetector.
class NexusLogo extends StatelessWidget {
  final double height;
  final NexusLogoVariant variant;
  final bool clickable;
  final VoidCallback? onTap;

  const NexusLogo({
    super.key,
    this.height = 26,
    this.variant = NexusLogoVariant.dark,
    this.clickable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      NexusBranding.logoPath,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );

    // El PNG tiene fondo blanco: sobre fondos oscuros lo envolvemos en un badge
    // blanco con bordes redondeados para que el logo sea legible.
    Widget content = variant == NexusLogoVariant.light
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: img,
          )
        : img;

    if (!clickable) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

// ── NexusIcon ────────────────────────────────────────────────────────────────
/// Isotipo de Nexus (icono solo, sin texto).
/// Úsalo en: sidebar colapsado, mobile navbar, loading pequeño,
/// avatar por defecto del sistema, estados vacíos compactos.
///
/// [size]      → ancho y alto en px (cuadrado).
/// [variant]   → dark (sobre fondo claro) | light (sobre fondo oscuro).
/// [clickable] → si es true muestra cursor pointer y envuelve en GestureDetector.
class NexusIcon extends StatelessWidget {
  final double size;
  final NexusLogoVariant variant;
  final bool clickable;
  final VoidCallback? onTap;

  const NexusIcon({
    super.key,
    this.size = 32,
    this.variant = NexusLogoVariant.dark,
    this.clickable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      NexusBranding.isotipoPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    Widget content = variant == NexusLogoVariant.light
        ? Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: img,
          )
        : img;

    if (!clickable) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}
