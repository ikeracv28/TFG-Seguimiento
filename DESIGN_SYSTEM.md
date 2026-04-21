# Nexus — Sistema de Diseño
# Referencia visual para la implementación Flutter

Este archivo define el sistema de diseño oficial de Nexus.
Toda decisión de color, tipografía, espaciado y componente parte de aquí.
Claude Code debe consultar este archivo antes de implementar cualquier pantalla Flutter.

---

## Filosofía

- **Espacio blanco generoso**: Nada apelmazado. Los elementos respiran.
- **Color funcional**: El color informa estado, no decora. Nunca usar color solo por estética.
- **Tipografía en dos pesos**: Regular (400) para contenido, Medium (500) para títulos y etiquetas.
- **Flat y limpio**: Sin gradientes, sin sombras decorativas. Estilo Notion / Linear.
- **Adaptable**: Sidebar en web/tablet, BottomNavigationBar en móvil. Mismo código Dart.

---

## Paleta de Colores

### Color primario
```dart
static const Color primary        = Color(0xFF185FA5);  // Azul — acciones, estado activo
static const Color primaryLight   = Color(0xFFE6F1FB);  // Azul claro — fondos de badges activos
static const Color primaryText    = Color(0xFF0C447C);  // Azul oscuro — texto sobre fondo azul claro
```

### Estados semánticos
```dart
// Validado / Éxito
static const Color success        = Color(0xFF3B6D11);
static const Color successLight   = Color(0xFFEAF3DE);
static const Color successText    = Color(0xFF27500A);

// Pendiente / Alerta
static const Color warning        = Color(0xFFBA7517);
static const Color warningLight   = Color(0xFFFAEEDA);
static const Color warningText    = Color(0xFF633806);

// Incidencia / Error
static const Color danger         = Color(0xFFE24B4A);
static const Color dangerLight    = Color(0xFFFCEBEB);
static const Color dangerText     = Color(0xFF791F1F);

// Neutro / Borrador
static const Color neutral        = Color(0xFF5F5E5A);
static const Color neutralLight   = Color(0xFFF1EFE8);
static const Color neutralText    = Color(0xFF444441);
```

### Superficies y bordes
```dart
static const Color surface        = Color(0xFFFFFFFF);  // Cards, contenido principal
static const Color surfaceAlt     = Color(0xFFF5F5F3);  // Fondos secundarios, métricas
static const Color border         = Color(0xFFE8E6DF);  // Borde estándar (0.5px)
static const Color borderStrong   = Color(0xFFD3D1C7);  // Borde énfasis
```

---

## Regla de uso del color

| Situación | Color de fondo | Color de texto |
|-----------|---------------|----------------|
| Práctica activa / En curso | `primaryLight` | `primaryText` |
| Seguimiento validado | `successLight` | `successText` |
| Seguimiento pendiente | `warningLight` | `warningText` |
| Incidencia / Rechazado | `dangerLight` | `dangerText` |
| Borrador / Finalizado | `neutralLight` | `neutralText` |

**Nunca** usar negro o gris genérico como texto sobre un fondo de color semántico.

---

## Tipografía

```dart
// Fuente del sistema — Flutter usa la fuente del SO (Roboto en Android, SF Pro en iOS)
// Para web: añadir Google Fonts 'Inter' en pubspec.yaml

// Escala tipográfica
static const TextStyle heading1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
static const TextStyle heading2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
static const TextStyle body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
static const TextStyle small    = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
static const TextStyle caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
static const TextStyle label    = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6);
```

---

## Espaciado

```dart
// Sistema de 4px
static const double spaceXS  = 4.0;
static const double spaceSM  = 8.0;
static const double spaceMD  = 12.0;
static const double spaceLG  = 16.0;
static const double spaceXL  = 20.0;
static const double space2XL = 24.0;
static const double space3XL = 32.0;

// Border radius
static const double radiusSM = 6.0;
static const double radiusMD = 8.0;
static const double radiusLG = 12.0;
static const double radiusFull = 999.0;  // pills / avatares

// Grosor de borde
static const double borderWidth = 0.5;
```

---

## Componentes

### Badge de estado

```dart
Widget estadoBadge(String texto, {required Color bg, required Color textColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    ),
  );
}

// Uso:
estadoBadge('En curso',   bg: NexusColors.primaryLight,  textColor: NexusColors.primaryText);
estadoBadge('Validado',   bg: NexusColors.successLight,  textColor: NexusColors.successText);
estadoBadge('Pendiente',  bg: NexusColors.warningLight,  textColor: NexusColors.warningText);
estadoBadge('Incidencia', bg: NexusColors.dangerLight,   textColor: NexusColors.dangerText);
```

### Card base

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: NexusColors.surface,
    border: Border.all(color: NexusColors.border, width: 0.5),
    borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
  ),
  child: /* contenido */,
)
```

### Barra de progreso de horas

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Horas completadas', style: NexusText.caption.copyWith(color: Colors.grey)),
        Text('$horasRealizadas / $horasTotales h', style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
      ],
    ),
    const SizedBox(height: 6),
    ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: horasRealizadas / horasTotales,
        backgroundColor: NexusColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(NexusColors.primary),
        minHeight: 6,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      '${((horasRealizadas / horasTotales) * 100).toStringAsFixed(0)}% · ${horasTotales - horasRealizadas} h restantes',
      style: NexusText.caption.copyWith(color: Colors.grey),
    ),
  ],
)
```

### Avatar con iniciales

```dart
CircleAvatar(
  radius: 16,
  backgroundColor: NexusColors.primaryLight,
  child: Text(
    iniciales,  // ej: 'JP' para José Pérez
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: NexusColors.primaryText,
    ),
  ),
)
```

### Burbuja de chat (mensaje recibido)

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    CircleAvatar(radius: 13, backgroundColor: primaryLight, child: Text('SG', style: ...)),
    const SizedBox(width: 7),
    Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NexusColors.surfaceAlt,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(2),  // esquina plana = lado del avatar
        ),
      ),
      child: Text(texto, style: NexusText.small),
    ),
  ],
)
```

### Burbuja de chat (mensaje propio)

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: NexusColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(2),  // esquina plana = lado del avatar
        ),
      ),
      child: Text(texto, style: NexusText.small.copyWith(color: Colors.white)),
    ),
    const SizedBox(width: 7),
    CircleAvatar(radius: 13, backgroundColor: primary, child: Text('IA', style: ...)),
  ],
)
```

---

## Navegación adaptativa (web + móvil)

Este es el patrón clave para que la app funcione bien en las dos plataformas.

```dart
// En el widget raíz de la app (scaffold principal):

LayoutBuilder(
  builder: (context, constraints) {
    final bool isWide = constraints.maxWidth > 600;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar: solo en pantallas anchas (web/tablet)
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.none,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Inicio')),
                NavigationRailDestination(icon: Icon(Icons.list_alt_outlined),  label: Text('Seguimientos')),
                NavigationRailDestination(icon: Icon(Icons.warning_amber_outlined), label: Text('Incidencias')),
                NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Chat')),
              ],
            ),

          // Contenido principal
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),

      // Bottom nav: solo en móvil
      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined),      label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined),       label: 'Seguimientos'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_outlined),  label: 'Incidencias'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),     label: 'Chat'),
        ],
      ),
    );
  },
)
```

---

## Pantallas definidas

### Dashboard del alumno
- Saludo con nombre y fecha.
- Card de práctica activa: empresa, código, tutor, barra de progreso de horas.
- Grid 2 columnas: últimos seguimientos + incidencias activas.
- Preview del chat con el tutor (últimos 2 mensajes + campo de escritura).
- Botón "Reportar incidencia" siempre visible en el header.

### Panel del tutor
- Lista lateral de alumnos asignados con indicadores de estado (badge rojo = incidencia, ámbar = pendiente validar, verde = al día).
- Panel de detalle al seleccionar un alumno: progreso, seguimientos pendientes de validar, incidencias activas, chat.
- Botones de validar / rechazar seguimiento directamente en la lista.

### Panel del centro (admin)
- Lista de tutores con carga de alumnos.
- Métricas: prácticas activas, incidencias abiertas, porcentaje de seguimientos al día.
- Acceso a CRUD de prácticas.

### Pantalla de seguimiento (nuevo registro)
- Selector de fecha.
- Campo numérico de horas (1-10).
- Área de texto para descripción de tareas.
- Botón de enviar con confirmación.

### Pantalla de incidencias
- Lista de incidencias con estado (abierta / en proceso / resuelta).
- Formulario de nueva incidencia: tipo (selector), descripción (área de texto).
- Detalle de incidencia con historial de cambios de estado.

### Pantalla de chat
- Listado de mensajes en orden cronológico.
- Diferenciación visual clara entre mensajes propios (azul, derecha) y recibidos (gris, izquierda).
- Campo de texto + botón enviar en la parte inferior.
- Conexión por WebSocket/STOMP (implementación posterior).

---

## AppTheme — archivo a crear

Ruta: `frontend/lib/core/theme/app_theme.dart`

Este archivo centraliza todos los colores, texto y decoraciones.
Ninguna pantalla define colores directamente; siempre importa desde aquí.
Cuando Claude Code implemente una pantalla nueva, lo primero es importar `app_theme.dart`.

```dart
import 'package:flutter/material.dart';

class NexusColors {
  NexusColors._();
  static const Color primary      = Color(0xFF185FA5);
  static const Color primaryLight = Color(0xFFE6F1FB);
  static const Color primaryText  = Color(0xFF0C447C);
  // ... resto de colores definidos arriba
}

class NexusSizes {
  NexusSizes._();
  static const double radiusLG   = 12.0;
  static const double radiusMD   = 8.0;
  static const double borderWidth = 0.5;
  // ... resto de tamaños definidos arriba
}

ThemeData nexusTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NexusColors.primary,
      brightness: Brightness.light,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        side: BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A18),
    ),
  );
}
```

---

## Referencia visual

Los mockups interactivos de referencia fueron generados el 18/04/2025 en la sesión de diseño con Claude.
Pantallas diseñadas: Dashboard alumno, Panel tutor, Sistema de diseño completo.
El estilo de referencia es: Notion / Linear — limpio, profesional, adaptable web y móvil.
