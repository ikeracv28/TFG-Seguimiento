import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../providers/auth_provider.dart';
import '../providers/practica_provider.dart';
import 'seguimientos_screen.dart';
import 'incidencias_screen.dart';
import 'ausencias_screen.dart';
import 'chat_placeholder_screen.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import '../widgets/nexus_avatar.dart';
import '../providers/notificacion_provider.dart';
import '../widgets/nexus_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PracticaProvider>(context, listen: false).cargarDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final practica = Provider.of<PracticaProvider>(context);

    final tabs = [
      _InicioTab(
        auth: auth,
        practica: practica,
        onVerTodosSeguimientos: () => setState(() => _navIndex = 1),
        onReportarIncidencia: () => setState(() => _navIndex = 2),
        onVerAusencias: () => setState(() => _navIndex = 3),
        onIrAlChat: () => setState(() => _navIndex = 4),
      ),
      const SeguimientosScreen(),
      const IncidenciasScreen(),
      const AusenciasScreen(),
      const ChatPlaceholderScreen(),
    ];

    return Scaffold(
      backgroundColor: context.nxt.surfaceAlt,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          if (isWide) {
            return Row(
              children: [
                _NexusRail(
                  selectedIndex: _navIndex,
                  onDestinationSelected: (i) => setState(() => _navIndex = i),
                  auth: auth,
                ),
                Expanded(child: IndexedStack(index: _navIndex, children: tabs)),
              ],
            );
          }
          return Column(
            children: [
              _MobileHeader(auth: auth),
              Expanded(child: IndexedStack(index: _navIndex, children: tabs)),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) return const SizedBox.shrink();
          return _NexusBottomNav(
            selectedIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
          );
        },
      ),
    );
  }
}

// ─── Mobile header ────────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  final AuthProvider auth;
  const _MobileHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NexusColors.ink,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
            child: const NexusLogo(height: 22, variant: NexusLogoVariant.light),
          ),
          const Spacer(),
          Consumer<NotificacionProvider>(
            builder: (ctx, notifProv, _) {
              final count = notifProv.noLeidas;
              return IconButton(
                onPressed: () async {
                  await Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                        value: notifProv, child: const NotificacionesScreen())));
                  notifProv.cargar();
                },
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(count > 9 ? '9+' : '$count', style: const TextStyle(fontSize: 10)),
                  child: const Icon(Icons.notifications_none_outlined, size: 20, color: Colors.white70),
                ),
              );
            },
          ),
          Builder(builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20, color: Colors.white70),
              onPressed: () => ctx.read<ThemeProvider>().toggle(),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20, color: Colors.white70),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar oscuro ────────────────────────────────────────────────────────────

class _NexusRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AuthProvider auth;

  const _NexusRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.auth,
  });

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Inicio'),
    (Icons.list_alt_outlined, Icons.list_alt, 'Seguimientos'),
    (Icons.warning_amber_outlined, Icons.warning_amber, 'Incidencias'),
    (Icons.date_range_outlined, Icons.date_range, 'Ausencias'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = auth.user?.nombreCompleto.split(' ').first ?? 'Usuario';

    return Container(
      width: 200,
      color: NexusColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: const NexusLogo(height: 26, variant: NexusLogoVariant.light),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (int i = 0; i < _items.length; i++)
                  _SidebarItem(
                    icon: i == selectedIndex ? _items[i].$2 : _items[i].$1,
                    label: _items[i].$3,
                    isSelected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
              ],
            ),
          ),

          // Iconos de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Consumer<NotificacionProvider>(
                  builder: (ctx, notifProv, _) {
                    final count = notifProv.noLeidas;
                    return IconButton(
                      tooltip: 'Notificaciones',
                      onPressed: () async {
                        await Navigator.push(ctx,
                            MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                              value: notifProv, child: const NotificacionesScreen())));
                        notifProv.cargar();
                      },
                      icon: Badge(
                        isLabelVisible: count > 0,
                        label: Text(count > 9 ? '9+' : '$count', style: const TextStyle(fontSize: 10)),
                        child: const Icon(Icons.notifications_none_outlined, size: 18, color: Colors.white60),
                      ),
                    );
                  },
                ),
                Builder(builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return IconButton(
                    icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 18, color: Colors.white60),
                    tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                    onPressed: () => ctx.read<ThemeProvider>().toggle(),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, size: 18, color: Colors.white60),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => auth.logout(),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.white12, height: 1),
          ),

          // Avatar + nombre usuario
          InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerfilScreen())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  NexusAvatar(
                    userId: auth.user!.id,
                    nombre: auth.user!.nombreCompleto,
                    radius: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(firstName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                        const Text('Estudiante',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? NexusColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab de inicio ─────────────────────────────────────────────────────────────

class _InicioTab extends StatelessWidget {
  final AuthProvider auth;
  final PracticaProvider practica;
  final VoidCallback onVerTodosSeguimientos;
  final VoidCallback onReportarIncidencia;
  final VoidCallback onVerAusencias;
  final VoidCallback onIrAlChat;

  const _InicioTab({
    required this.auth,
    required this.practica,
    required this.onVerTodosSeguimientos,
    required this.onReportarIncidencia,
    required this.onVerAusencias,
    required this.onIrAlChat,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NexusColors.primary,
      onRefresh: () => practica.cargarDashboard(),
      child: LayoutBuilder(builder: (ctx, cst) {
        final pad = cst.maxWidth < 600 ? 16.0 : NexusSizes.space3XL;
        return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingHeader(nombreCompleto: auth.user?.nombreCompleto ?? 'Usuario'),
                const SizedBox(height: NexusSizes.space2XL),
                if (practica.isLoading)
                  const _LoadingCard()
                else if (practica.errorMessage != null)
                  _ErrorCard(
                    message: practica.errorMessage!,
                    onRetry: () => practica.cargarDashboard(),
                  )
                else if (practica.practicaActiva == null)
                  const _EmptyState()
                else
                  _DashboardContent(
                    practica: practica,
                    onVerTodosSeguimientos: onVerTodosSeguimientos,
                    onReportarIncidencia: onReportarIncidencia,
                    onIrAlChat: onIrAlChat,
                  ),
              ],
            ),
      );
      }),
    );
  }
}

// ─── Layout 2 columnas ─────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final PracticaProvider practica;
  final VoidCallback onVerTodosSeguimientos;
  final VoidCallback onReportarIncidencia;
  final VoidCallback onIrAlChat;

  const _DashboardContent({
    required this.practica,
    required this.onVerTodosSeguimientos,
    required this.onReportarIncidencia,
    required this.onIrAlChat,
  });

  @override
  Widget build(BuildContext context) {
    final p = practica.practicaActiva!;
    final seguimientos = practica.seguimientos;
    final horasCompletadas = practica.horasCompletadas;

    final mainCard = _PracticaMainCard(
      practica: p,
      seguimientos: seguimientos,
      horasCompletadas: horasCompletadas,
      onVerTodos: onVerTodosSeguimientos,
      onRegistrar: () => showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.45),
        builder: (_) => NuevoParteDialog(onGuardado: practica.cargarDashboard),
      ),
    );

    final rightCol = Column(
      children: [
        _ResponsablesCard(practica: p),
        const SizedBox(height: NexusSizes.spaceLG),
        _AyudaCard(
          onReportarIncidencia: onReportarIncidencia,
          onIrAlChat: onIrAlChat,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: mainCard),
              const SizedBox(width: NexusSizes.spaceLG),
              SizedBox(width: 260, child: rightCol),
            ],
          );
        }
        return Column(
          children: [mainCard, const SizedBox(height: NexusSizes.spaceLG), rightCol],
        );
      },
    );
  }
}

// ─── Card principal de práctica ────────────────────────────────────────────────

class _PracticaMainCard extends StatelessWidget {
  final Practica practica;
  final List<Seguimiento> seguimientos;
  final double horasCompletadas;
  final VoidCallback onVerTodos;
  final VoidCallback onRegistrar;

  const _PracticaMainCard({
    required this.practica,
    required this.seguimientos,
    required this.horasCompletadas,
    required this.onVerTodos,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final horas = practica.horasTotales ?? 0;
    final pct = horas > 0 ? (horasCompletadas / horas * 100).round() : 0;
    final recientes = seguimientos.take(3).toList();
    final ultimoReporte = seguimientos.isNotEmpty ? seguimientos.first : null;

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.fromLTRB(
                NexusSizes.space2XL, NexusSizes.space2XL, NexusSizes.space2XL, NexusSizes.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _EstadoBadge(practica.estado),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: NexusSizes.spaceSM),
                Text(
                  practica.empresaNombre,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700,
                      color: context.nxt.ink, letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(practica.codigo, style: NexusText.caption),
              ],
            ),
          ),

          // Stats strip
          Padding(
            padding: const EdgeInsets.fromLTRB(
                NexusSizes.space2XL, 0, NexusSizes.space2XL, NexusSizes.spaceLG),
            child: _StatsRow(
              horas: horas,
              horasCompletadas: horasCompletadas,
              pct: pct,
              ultimoReporte: ultimoReporte,
            ),
          ),

          Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

          // Cabecera tabla
          Padding(
            padding: const EdgeInsets.fromLTRB(
                NexusSizes.space2XL, NexusSizes.spaceMD, NexusSizes.spaceMD, NexusSizes.spaceMD),
            child: Row(
              children: [
                Text('Seguimiento reciente',
                    style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: onVerTodos,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Ver todo',
                      style: NexusText.caption.copyWith(color: NexusColors.primary)),
                ),
              ],
            ),
          ),

          // Cabecera columnas
          Container(
            color: context.nxt.surfaceAlt,
            padding: const EdgeInsets.fromLTRB(NexusSizes.space2XL, 8, NexusSizes.space2XL, 8),
            child: Row(
              children: [
                _ColHeader('FECHA', flex: 2),
                _ColHeader('ACTIVIDAD', flex: 4),
                _ColHeader('HORAS', flex: 1),
                _ColHeader('ESTADO', flex: 2),
              ],
            ),
          ),

          Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

          // Filas
          if (recientes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              child: Center(
                child: Text('Sin seguimientos registrados', style: NexusText.caption),
              ),
            )
          else
            for (final s in recientes) _SeguimientoRow(s),

          // Botón registrar
          Padding(
            padding: const EdgeInsets.all(NexusSizes.spaceLG),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRegistrar,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Registrar nueva actividad'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NexusColors.primary,
                  side: const BorderSide(color: NexusColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge(this.estado);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color fg;
    Color bg;
    Color dot;
    String label;
    switch (estado) {
      case 'ACTIVA':
        fg = isDark ? const Color(0xFF86C962) : NexusColors.successText;
        bg = isDark ? const Color(0xFF1E3D10) : NexusColors.successLight;
        dot = isDark ? const Color(0xFF86C962) : NexusColors.success;
        label = 'En curso';
      case 'FINALIZADA':
        fg = isDark ? const Color(0xFF7AB5F5) : NexusColors.primaryText;
        bg = isDark ? const Color(0xFF0D2B4F) : NexusColors.primaryLight;
        dot = isDark ? const Color(0xFF7AB5F5) : NexusColors.primary;
        label = 'Finalizada';
      default:
        fg = isDark ? const Color(0xFFA4AABC) : NexusColors.neutralText;
        bg = isDark ? const Color(0xFF252B3D) : NexusColors.neutralLight;
        dot = isDark ? const Color(0xFFA4AABC) : NexusColors.neutral;
        label = 'Borrador';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int horas;
  final double horasCompletadas;
  final int pct; // double horasCompletadas handled downstream
  final Seguimiento? ultimoReporte;

  const _StatsRow({
    required this.horas,
    required this.horasCompletadas,
    required this.pct,
    required this.ultimoReporte,
  });

  @override
  Widget build(BuildContext context) {
    final horasCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOTAL HORAS',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: context.nxt.inkTertiary)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(_fmtH(horasCompletadas),
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700,
                    color: NexusColors.primary)),
            Text(' / ${horas}h', style: NexusText.caption),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: horas > 0 ? (horasCompletadas / horas).clamp(0.0, 1.0) : 0.0,
            minHeight: 4,
            backgroundColor: context.nxt.border,
            valueColor: const AlwaysStoppedAnimation<Color>(NexusColors.primary),
          ),
        ),
      ],
    );
    final progresoCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROGRESO GLOBAL',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: context.nxt.inkTertiary)),
        const SizedBox(height: 4),
        Text('$pct%',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700,
                color: context.nxt.ink)),
      ],
    );
    final reporteCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ÚLTIMO REPORTE',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: context.nxt.inkTertiary)),
        const SizedBox(height: 4),
        if (ultimoReporte != null) ...[
          Text(_estadoLabel(ultimoReporte!.estado),
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                  color: _estadoColor(ultimoReporte!.estado))),
          const SizedBox(height: 2),
          Text(_relativeDays(ultimoReporte!.fechaRegistro), style: NexusText.caption),
        ] else
          Text('Sin partes', style: NexusText.caption),
      ],
    );

    return LayoutBuilder(builder: (ctx, cst) {
      if (cst.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            horasCol,
            Divider(height: 24, thickness: 1, color: context.nxt.border),
            progresoCol,
            Divider(height: 24, thickness: 1, color: context.nxt.border),
            reporteCol,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: horasCol),
          Container(width: 1, height: 56, color: context.nxt.border,
              margin: const EdgeInsets.symmetric(horizontal: 16)),
          Expanded(child: progresoCol),
          Container(width: 1, height: 56, color: context.nxt.border,
              margin: const EdgeInsets.symmetric(horizontal: 16)),
          Expanded(child: reporteCol),
        ],
      );
    });
  }

  static String _fmtH(double h) {
    if (h == h.truncateToDouble()) return '${h.toInt()}h';
    return '${h.truncate()}h 30min';
  }

  static String _estadoLabel(String e) => switch (e) {
    'COMPLETADO' => 'Validado',
    'PENDIENTE_EMPRESA' => 'Pend. Empresa',
    'PENDIENTE_CENTRO' => 'Pend. Centro',
    'RECHAZADO' => 'Rechazado',
    _ => e,
  };

  static Color _estadoColor(String e) => switch (e) {
    'COMPLETADO' => NexusColors.success,
    'RECHAZADO' => NexusColors.danger,
    _ => NexusColors.primary,
  };

  static String _relativeDays(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Hace 1 día';
    return 'Hace $diff días';
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
          letterSpacing: 0.8, color: context.nxt.inkTertiary,
        ),
      ),
    );
  }
}

class _SeguimientoRow extends StatelessWidget {
  final Seguimiento s;
  const _SeguimientoRow(this.s);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.fromLTRB(NexusSizes.space2XL, 12, NexusSizes.space2XL, 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_fmtDate(s.fechaRegistro), style: NexusText.small)),
          Expanded(
            flex: 4,
            child: Text(
              s.descripcion?.isNotEmpty == true ? s.descripcion! : '${fmtH(s.horasRealizadas)} de trabajo',
              style: NexusText.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 1, child: Text(fmtH(s.horasRealizadas), style: NexusText.small)),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerLeft, child: _MiniEstadoBadge(s.estado)),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${meses[d.month - 1]}';
  }
}

class _MiniEstadoBadge extends StatelessWidget {
  final String estado;
  const _MiniEstadoBadge(this.estado);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color fg;
    Color bg;
    String label;
    switch (estado) {
      case 'COMPLETADO':
        fg = isDark ? const Color(0xFF86C962) : NexusColors.successText;
        bg = isDark ? const Color(0xFF1E3D10) : NexusColors.successLight;
        label = 'Validado';
      case 'RECHAZADO':
        fg = isDark ? const Color(0xFFFF8A80) : NexusColors.dangerText;
        bg = isDark ? const Color(0xFF4A1515) : NexusColors.dangerLight;
        label = 'Rechazado';
      case 'PENDIENTE_EMPRESA':
        fg = isDark ? const Color(0xFFFFB74D) : NexusColors.warningText;
        bg = isDark ? const Color(0xFF3D2A06) : NexusColors.warningLight;
        label = 'Pend. Empresa';
      default:
        fg = isDark ? const Color(0xFF7AB5F5) : NexusColors.primaryText;
        bg = isDark ? const Color(0xFF0D2B4F) : NexusColors.primaryLight;
        label = 'Pend. Centro';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NexusSizes.radiusFull)),
      child: Text(label,
          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: fg),
          overflow: TextOverflow.ellipsis),
    );
  }
}

// ─── Card de responsables ───────────────────────────────────────────────────────

class _ResponsablesCard extends StatelessWidget {
  final Practica practica;
  const _ResponsablesCard({required this.practica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexusSizes.spaceLG),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Responsables', style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: NexusSizes.spaceMD),
          _TutorRow(
            role: 'TUTOR ACADÉMICO',
            name: practica.tutorCentroNombre,
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: NexusSizes.spaceMD),
          _TutorRow(
            role: 'TUTOR EMPRESA',
            name: practica.tutorEmpresaNombre,
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }
}

class _TutorRow extends StatelessWidget {
  final String role;
  final String name;
  final IconData icon;
  const _TutorRow({required this.role, required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: NexusColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
          ),
          child: Icon(icon, size: 16, color: NexusColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                      letterSpacing: 0.6, color: context.nxt.inkTertiary)),
              Text(name,
                  style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Card de ayuda ────────────────────────────────────────────────────────────

class _AyudaCard extends StatelessWidget {
  final VoidCallback onReportarIncidencia;
  final VoidCallback onIrAlChat;
  const _AyudaCard({required this.onReportarIncidencia, required this.onIrAlChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexusSizes.spaceLG),
      decoration: BoxDecoration(
        color: NexusColors.primary,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Necesitas ayuda?',
              style: TextStyle(
                  fontFamily: 'Inter', color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Si tienes alguna incidencia con tus prácticas, contacta con nosotros.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReportarIncidencia,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
              child: const Text('Reportar Incidencia'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onIrAlChat,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
              child: const Text('Ir al Chat'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saludo ────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String nombreCompleto;
  const _GreetingHeader({required this.nombreCompleto});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fecha = _formatDate(now);
    final firstName = nombreCompleto.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $firstName',
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w700,
            color: context.nxt.ink, letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fecha,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: context.nxt.inkTertiary),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const dias = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio',
                   'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}

// ─── Estados vacíos y carga ────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: NexusSizes.space3XL),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 36, color: context.nxt.inkTertiary),
          const SizedBox(height: NexusSizes.spaceMD),
          Text('Sin práctica asignada',
              style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(
            'Contacta con tu tutor del centro para que te asigne una práctica.',
            style: NexusText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: NexusColors.primary),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final msg = message.replaceFirst(RegExp(r'^Exception: '), '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NexusSizes.space2XL),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: NexusColors.dangerLight, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: NexusColors.danger),
          const SizedBox(height: NexusSizes.spaceMD),
          Text('No se pudo cargar la práctica',
              style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(msg, style: NexusText.caption, textAlign: TextAlign.center),
          const SizedBox(height: NexusSizes.spaceLG),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom nav (móvil) ────────────────────────────────────────────────────────

class _NexusBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NexusBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: context.nxt.surface,
        selectedItemColor: NexusColors.primary,
        unselectedItemColor: context.nxt.inkTertiary,
        selectedLabelStyle: NexusText.caption.copyWith(color: NexusColors.primary),
        unselectedLabelStyle: NexusText.caption,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Seguimientos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_outlined), activeIcon: Icon(Icons.warning_amber), label: 'Incidencias'),
          BottomNavigationBarItem(
              icon: Icon(Icons.date_range_outlined), activeIcon: Icon(Icons.date_range), label: 'Ausencias'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
      ),
    );
  }
}
