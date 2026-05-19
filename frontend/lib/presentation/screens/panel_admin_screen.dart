import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/empresa_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/audit_log_model.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import '../providers/notificacion_provider.dart';
import '../widgets/nexus_avatar.dart';
import '../widgets/nexus_logo.dart';

enum _ModoAdmin { dashboard, practicas, usuarios, empresas, auditoria }

class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  _ModoAdmin _modo = _ModoAdmin.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final esWeb = constraints.maxWidth > 600;
      if (esWeb) {
        return Scaffold(
          backgroundColor: context.nxt.surfaceAlt,
          body: Row(
            children: [
              _Sidebar(
                  modoActivo: _modo,
                  onModoChanged: (m) => setState(() => _modo = m)),
              Expanded(child: _contenidoPorModo()),
            ],
          ),
        );
      }
      return Scaffold(
        backgroundColor: context.nxt.surfaceAlt,
        appBar: AppBar(
          backgroundColor: NexusColors.primary,
          elevation: 0,
          title: Text(
            _modoLabel,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          actions: [
            Builder(builder: (ctx) {
              final isDark = ctx.watch<ThemeProvider>().isDark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Colors.white70, size: 20),
                tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                onPressed: () => ctx.read<ThemeProvider>().toggle(),
              );
            }),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              tooltip: 'Cerrar sesión',
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
        body: _contenidoPorModo(),
        bottomNavigationBar: _MobileBottomNavAdmin(
          modo: _modo,
          onChanged: (m) => setState(() => _modo = m),
        ),
      );
    });
  }

  String get _modoLabel {
    switch (_modo) {
      case _ModoAdmin.dashboard:
        return 'Administración';
      case _ModoAdmin.practicas:
        return 'Prácticas';
      case _ModoAdmin.usuarios:
        return 'Usuarios';
      case _ModoAdmin.empresas:
        return 'Empresas';
      case _ModoAdmin.auditoria:
        return 'Auditoría';
    }
  }

  Widget _contenidoPorModo() {
    switch (_modo) {
      case _ModoAdmin.dashboard:
        return _VistaDashboard(
          onModoChanged: (m) => setState(() => _modo = m),
        );
      case _ModoAdmin.practicas:
        return const _VistaPracticas();
      case _ModoAdmin.usuarios:
        return const _VistaUsuarios();
      case _ModoAdmin.empresas:
        return const _VistaEmpresas();
      case _ModoAdmin.auditoria:
        return const _VistaAuditoria();
    }
  }
}

// ---- Sidebar ----

class _Sidebar extends StatelessWidget {
  final _ModoAdmin modoActivo;
  final ValueChanged<_ModoAdmin> onModoChanged;

  const _Sidebar({required this.modoActivo, required this.onModoChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(right: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: const NexusLogo(height: 28),
          ),
          Divider(height: 1, color: context.nxt.border),
          const SizedBox(height: NexusSizes.spaceSM),
          _NavBtn(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            activo: modoActivo == _ModoAdmin.dashboard,
            onTap: () => onModoChanged(_ModoAdmin.dashboard),
          ),
          _NavBtn(
            icon: Icons.folder_open_outlined,
            label: 'Prácticas',
            activo: modoActivo == _ModoAdmin.practicas,
            onTap: () => onModoChanged(_ModoAdmin.practicas),
          ),
          _NavBtn(
            icon: Icons.people_alt_outlined,
            label: 'Usuarios',
            activo: modoActivo == _ModoAdmin.usuarios,
            onTap: () => onModoChanged(_ModoAdmin.usuarios),
          ),
          _NavBtn(
            icon: Icons.business_outlined,
            label: 'Empresas',
            activo: modoActivo == _ModoAdmin.empresas,
            onTap: () => onModoChanged(_ModoAdmin.empresas),
          ),
          _NavBtn(
            icon: Icons.history_outlined,
            label: 'Auditoría',
            activo: modoActivo == _ModoAdmin.auditoria,
            onTap: () => onModoChanged(_ModoAdmin.auditoria),
          ),
          const Spacer(),
          _NavBtn(
            icon: Icons.person_outline,
            label: 'Mi perfil',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerfilScreen())),
          ),
          Consumer<NotificacionProvider>(
            builder: (ctx, notifProv, _) {
              final count = notifProv.noLeidas;
              return InkWell(
                onTap: () async {
                  await Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                        value: notifProv,
                        child: const NotificacionesScreen(),
                      )));
                  notifProv.cargar();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Badge(
                        isLabelVisible: count > 0,
                        label: Text(count > 9 ? '9+' : '$count',
                            style: const TextStyle(fontSize: 10)),
                        child: Icon(Icons.notifications_none_outlined,
                            size: 18, color: context.nxt.inkSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text('Notificaciones',
                          style: TextStyle(fontSize: 13, color: context.nxt.inkSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
          _NavBtn(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark ? 'Modo claro' : 'Modo oscuro',
            onTap: () => context.read<ThemeProvider>().toggle(),
          ),
          _NavBtn(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            onTap: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(height: NexusSizes.spaceLG),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: activo ? NexusColors.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: activo ? NexusColors.primary : context.nxt.inkSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                      color: activo ? NexusColors.primary : context.nxt.inkSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Vista Dashboard ----

class _VistaDashboard extends StatelessWidget {
  final ValueChanged<_ModoAdmin> onModoChanged;
  const _VistaDashboard({required this.onModoChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, admin, _) {
      if (admin.cargando) {
        return const Center(child: CircularProgressIndicator());
      }

      final practicasActivas =
          admin.practicas.where((p) => p.estado == 'ACTIVA').toList();
      final incRecientes = admin.incidencias.take(4).toList();

      return RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().cargarTodo(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panel de Administración',
                            style: NexusText.heading2
                                .copyWith(letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(
                          'CampusFP · Administración General',
                          style: NexusText.body
                              .copyWith(color: context.nxt.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stat cards (clickable) — responsive 2×2 en móvil, 1×4 en desktop
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final cards = [
                    _DashStatCard(
                      valor: admin.practicasActivas,
                      label: 'Prácticas activas',
                      subtitulo: '${admin.practicasBorrador} en borrador · ${admin.practicasFinalizadas} finalizadas',
                      color: NexusColors.success,
                      icon: Icons.work_outline_rounded,
                      onTap: () => onModoChanged(_ModoAdmin.practicas),
                    ),
                    _DashStatCard(
                      valor: admin.empresas.length,
                      label: 'Empresas colaboradoras',
                      subtitulo: '${admin.practicas.map((p) => p.empresaId).toSet().length} con práctica activa',
                      color: NexusColors.primary,
                      icon: Icons.business_outlined,
                      onTap: () => onModoChanged(_ModoAdmin.empresas),
                    ),
                    _DashStatCard(
                      valor: admin.incidenciasAbiertas,
                      label: 'Incidencias abiertas',
                      subtitulo: '${admin.incidencias.length} incidencias en total',
                      color: NexusColors.danger,
                      icon: Icons.warning_amber_outlined,
                      onTap: () => onModoChanged(_ModoAdmin.auditoria),
                    ),
                    _DashStatCard(
                      valor: admin.alumnos.length,
                      label: 'Alumnos registrados',
                      subtitulo: '${admin.practicasActivas} en prácticas activas',
                      color: NexusColors.warning,
                      icon: Icons.school_outlined,
                      onTap: () => onModoChanged(_ModoAdmin.usuarios),
                    ),
                  ];
                  if (isMobile) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: cards[2]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[3]),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 12),
                      Expanded(child: cards[1]),
                      const SizedBox(width: 12),
                      Expanded(child: cards[2]),
                      const SizedBox(width: 12),
                      Expanded(child: cards[3]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Two-column layout
              LayoutBuilder(
                builder: (ctx, constraints) {
                  if (constraints.maxWidth > 680) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 3,
                            child: _PracticasEnCurso(
                                practicas: practicasActivas,
                                onVerPracticas: () => onModoChanged(_ModoAdmin.practicas))),
                        const SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _IncidenciasRecientes(
                                    incidencias: incRecientes,
                                    admin: admin),
                                const SizedBox(height: 16),
                                _DistribucionTutores(practicas: practicasActivas),
                              ],
                            )),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _PracticasEnCurso(practicas: practicasActivas,
                          onVerPracticas: () => onModoChanged(_ModoAdmin.practicas)),
                      const SizedBox(height: 16),
                      _IncidenciasRecientes(
                          incidencias: incRecientes, admin: admin),
                      const SizedBox(height: 16),
                      _DistribucionTutores(practicas: practicasActivas),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DashStatCard extends StatelessWidget {
  final int valor;
  final String label;
  final String subtitulo;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _DashStatCard({
    required this.valor,
    required this.label,
    required this.subtitulo,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.nxt.surface,
          border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withAlpha(24),
                    borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: context.nxt.inkTertiary),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: context.nxt.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(subtitulo,
                style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PracticasEnCurso extends StatelessWidget {
  final List<Practica> practicas;
  final VoidCallback? onVerPracticas;
  const _PracticasEnCurso({required this.practicas, this.onVerPracticas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Prácticas en curso',
                      style: NexusText.small.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (onVerPracticas != null)
                  TextButton.icon(
                    onPressed: onVerPracticas,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                    label: const Text('Ver todas'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      foregroundColor: NexusColors.primary,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: context.nxt.border),
          if (practicas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No hay prácticas activas.',
                  style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
            )
          else
            ...practicas.take(5).map((p) => _PracticaEnCursoRow(
                  practica: p,
                  onTap: onVerPracticas,
                )),
          if (practicas.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'y ${practicas.length - 5} más…',
                style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PracticaEnCursoRow extends StatelessWidget {
  final Practica practica;
  final VoidCallback? onTap;
  const _PracticaEnCursoRow({required this.practica, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                NexusAvatar(
                  userId: practica.alumnoId,
                  nombre: practica.alumnoNombre,
                  radius: 16,
                  backgroundColor: NexusColors.primaryLight,
                  textColor: NexusColors.primaryText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(practica.alumnoNombre,
                          style: NexusText.small.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${practica.empresaNombre} · ${practica.codigo}',
                        style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tutor: ${practica.tutorCentroNombre}',
                        style: NexusText.caption.copyWith(
                            color: context.nxt.inkTertiary, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NexusColors.successLight,
                    borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                  ),
                  child: const Text('En curso',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: NexusColors.successText)),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 16, color: context.nxt.inkTertiary),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: context.nxt.border),
      ],
    );
  }
}

class _IncidenciasRecientes extends StatelessWidget {
  final List<Incidencia> incidencias;
  final AdminProvider admin;
  const _IncidenciasRecientes(
      {required this.incidencias, required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(
            color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('INCIDENCIAS RECIENTES',
                style: NexusText.caption.copyWith(
                    color: context.nxt.inkSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ),
          if (incidencias.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('Sin incidencias recientes.',
                  style: TextStyle(color: context.nxt.inkSecondary)),
            )
          else
            ...incidencias.map((inc) {
              final practica = admin.practicas
                  .where((p) => p.id == inc.practicaId)
                  .firstOrNull;
              final color =
                  inc.estado == 'ABIERTA' ? NexusColors.danger : NexusColors.warning;
              final label =
                  inc.estado == 'ABIERTA' ? 'Abierta' : 'En proceso';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${inc.creadaPorNombre} — ${inc.descripcion}',
                            style: NexusText.small,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            practica != null
                                ? '${practica.codigo} · ${inc.creadaPorNombre}'
                                : inc.creadaPorNombre,
                            style: NexusText.caption.copyWith(
                                color: context.nxt.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius:
                            BorderRadius.circular(NexusSizes.radiusSM),
                      ),
                      child: Text(label,
                          style: NexusText.caption.copyWith(
                              color: color, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---- Distribución por Tutor de Centro ----

class _DistribucionTutores extends StatelessWidget {
  final List<Practica> practicas;
  const _DistribucionTutores({required this.practicas});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> conteo = {};
    for (final p in practicas) {
      conteo[p.tutorCentroNombre] = (conteo[p.tutorCentroNombre] ?? 0) + 1;
    }
    final entries = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.isEmpty ? 1 : entries.first.value;

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('DISTRIBUCIÓN POR TUTOR DE CENTRO',
                style: NexusText.caption.copyWith(
                    color: context.nxt.inkSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('Sin datos.', style: TextStyle(color: context.nxt.inkSecondary)),
            )
          else
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.key,
                                style: NexusText.small,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.value}',
                              style: NexusText.small.copyWith(
                                  color: NexusColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value / maxVal,
                          minHeight: 5,
                          backgroundColor: context.nxt.border,
                          color: NexusColors.primary,
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---- Vista Prácticas ----

class _VistaPracticas extends StatefulWidget {
  const _VistaPracticas();

  @override
  State<_VistaPracticas> createState() => _VistaPracticasState();
}

class _VistaPracticasState extends State<_VistaPracticas> {
  String _filtro = 'TODAS';

  static const _filtros = ['TODAS', 'ACTIVA', 'BORRADOR', 'FINALIZADA'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, admin, _) {
      final lista = _filtro == 'TODAS'
          ? admin.practicas
          : admin.practicas.where((p) => p.estado == _filtro).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: context.nxt.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: NexusSizes.space3XL,
                vertical: NexusSizes.spaceLG),
            child: Row(
              children: [
                const Text('Prácticas', style: NexusText.heading2),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _mostrarDialogCrear(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nueva práctica'),
                  style: FilledButton.styleFrom(
                      backgroundColor: NexusColors.primary),
                ),
              ],
            ),
          ),
          // Filtros pill tabs
          Container(
            color: context.nxt.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: _filtros.map((f) {
                final activo = _filtro == f;
                final count = f == 'TODAS'
                    ? admin.practicas.length
                    : admin.practicas.where((p) => p.estado == f).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _filtro = f),
                    borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: activo ? NexusColors.primary : context.nxt.surfaceAlt,
                        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                        border: Border.all(
                          color: activo ? NexusColors.primary : context.nxt.border,
                          width: NexusSizes.borderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _labelFiltro(f),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activo ? Colors.white : context.nxt.inkSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: activo ? Colors.white.withAlpha(50) : context.nxt.border,
                              borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: activo ? Colors.white : context.nxt.inkSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Lista
          Expanded(
            child: admin.cargando
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? Center(
                        child: Text(
                          'No hay prácticas con estado $_filtro.',
                          style: TextStyle(
                              color: context.nxt.inkSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(NexusSizes.space2XL),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: NexusSizes.spaceSM),
                        itemBuilder: (_, i) =>
                            _PracticaCard(practica: lista[i]),
                      ),
          ),
        ],
      );
    });
  }

  void _mostrarDialogCrear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AdminProvider>(),
        child: const _DialogCrearPractica(),
      ),
    );
  }

  String _labelFiltro(String f) {
    switch (f) {
      case 'ACTIVA': return 'Activa';
      case 'BORRADOR': return 'Borrador';
      case 'FINALIZADA': return 'Finalizada';
      default: return 'Todas';
    }
  }
}

class _PracticaCard extends StatelessWidget {
  final Practica practica;
  final bool compacta;

  const _PracticaCard({required this.practica, this.compacta = false});

  Color get _bgEstado {
    switch (practica.estado) {
      case 'ACTIVA': return NexusColors.successLight;
      case 'BORRADOR': return NexusColors.warningLight;
      case 'FINALIZADA': return NexusColors.neutralLight;
      default: return NexusColors.neutralLight;
    }
  }

  Color get _textEstado {
    switch (practica.estado) {
      case 'ACTIVA': return NexusColors.successText;
      case 'BORRADOR': return NexusColors.warningText;
      case 'FINALIZADA': return NexusColors.neutralText;
      default: return NexusColors.neutralText;
    }
  }

  String get _labelEstado {
    switch (practica.estado) {
      case 'ACTIVA': return 'Activa';
      case 'BORRADOR': return 'Borrador';
      case 'FINALIZADA': return 'Finalizada';
      default: return practica.estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cst) {
      final narrow = compacta || cst.maxWidth < 480;
      return _buildCard(context, narrow);
    });
  }

  Widget _buildCard(BuildContext context, bool narrow) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Left: code + badge + student
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(practica.codigo,
                          style: NexusText.small.copyWith(
                              fontWeight: FontWeight.w700, letterSpacing: -0.2),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _bgEstado,
                        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                      ),
                      child: Text(_labelEstado,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _textEstado)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    NexusAvatar(
                      userId: practica.alumnoId,
                      nombre: practica.alumnoNombre,
                      radius: 10,
                      backgroundColor: NexusColors.primaryLight,
                      textColor: NexusColors.primaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(practica.alumnoNombre,
                          style: NexusText.caption.copyWith(
                              fontWeight: FontWeight.w500, color: context.nxt.ink),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!narrow) ...[
            // Center: empresa + tutor
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business_outlined, size: 12, color: context.nxt.inkSecondary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(practica.empresaNombre,
                            style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: context.nxt.inkTertiary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(practica.tutorCentroNombre,
                            style: NexusText.caption.copyWith(
                                fontSize: 11, color: context.nxt.inkTertiary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // Right: hours + action
          if (practica.horasTotales != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${practica.horasTotales}h',
                      style: NexusText.small.copyWith(
                          fontWeight: FontWeight.w700,
                          color: practica.estado == 'FINALIZADA'
                              ? NexusColors.success
                              : context.nxt.ink)),
                  Text('totales',
                      style: NexusText.caption.copyWith(color: context.nxt.inkTertiary)),
                ],
              ),
            ),
          Builder(builder: (ctx) {
            return IconButton(
              icon: Icon(
                practica.estado == 'FINALIZADA'
                    ? Icons.visibility_outlined
                    : Icons.edit_outlined,
                size: 17,
              ),
              tooltip: practica.estado == 'FINALIZADA' ? 'Ver práctica' : 'Editar práctica',
              color: context.nxt.inkSecondary,
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => ChangeNotifierProvider.value(
                  value: ctx.read<AdminProvider>(),
                  child: _DialogEditarPractica(practica: practica),
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            );
          }),
          if (practica.estado == 'BORRADOR')
            Builder(builder: (ctx) {
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: NexusColors.danger, size: 17),
                tooltip: 'Eliminar práctica',
                onPressed: () => _confirmarEliminar(ctx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar práctica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vas a eliminar la práctica ${practica.codigo}.'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NexusColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: NexusColors.dangerText, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no tiene vuelta atrás.',
                      style: TextStyle(fontWeight: FontWeight.w600, color: NexusColors.dangerText, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: NexusColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (primera != true || !context.mounted) return;

    final segunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmación final'),
        content: const Text(
          'La práctica y todos sus partes de seguimiento se eliminarán de forma permanente.\n\n¿Estás completamente seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: NexusColors.danger),
            child: const Text('Sí, eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (segunda != true || !context.mounted) return;

    final ok = await context.read<AdminProvider>().eliminarPractica(practica.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Práctica ${practica.codigo} eliminada' : context.read<AdminProvider>().error ?? 'Error al eliminar'),
        backgroundColor: ok ? NexusColors.success : NexusColors.danger,
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String estado;
  final Color color;

  const _ChipEstado({required this.estado, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceSM, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(estado,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ---- Dialog crear práctica ----

class _DialogCrearPractica extends StatefulWidget {
  const _DialogCrearPractica();

  @override
  State<_DialogCrearPractica> createState() => _DialogCrearPracticaState();
}

class _DialogCrearPracticaState extends State<_DialogCrearPractica> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _horasCtrl = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  UsuarioModel? _alumno;
  UsuarioModel? _tutorCentro;
  UsuarioModel? _tutorEmpresa;
  EmpresaModel? _empresa;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _horasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) _fechaInicio = picked;
        else _fechaFin = picked;
      });
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _error = 'Las fechas de inicio y fin son obligatorias');
      return;
    }
    setState(() { _enviando = true; _error = null; });

    final ok = await context.read<AdminProvider>().crearPractica(
      codigo: _codigoCtrl.text.trim(),
      alumnoId: _alumno!.id,
      tutorCentroId: _tutorCentro!.id,
      tutorEmpresaId: _tutorEmpresa!.id,
      empresaId: _empresa!.id,
      fechaInicio: _fechaInicio!.toIso8601String().split('T')[0],
      fechaFin: _fechaFin!.toIso8601String().split('T')[0],
      horasTotales: int.parse(_horasCtrl.text.trim()),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Práctica creada correctamente'),
        backgroundColor: NexusColors.success,
      ));
    } else {
      setState(() {
        _error = context.read<AdminProvider>().error;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return AlertDialog(
      title: const Text('Nueva práctica', style: NexusText.heading3),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  _ErrorBanner(mensaje: _error!),
                  const SizedBox(height: NexusSizes.spaceMD),
                ],
                Row(children: [
                  Expanded(child: _campoTexto(_codigoCtrl, 'Código', required: true)),
                  const SizedBox(width: NexusSizes.spaceMD),
                  Expanded(
                    child: _campoTexto(_horasCtrl, 'Horas totales',
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null)
                            ? 'Número válido'
                            : null),
                  ),
                ]),
                const SizedBox(height: NexusSizes.spaceMD),
                _DropdownUsuario(
                  label: 'Alumno',
                  usuarios: admin.alumnos,
                  valor: _alumno,
                  onChanged: (u) => setState(() => _alumno = u),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                _DropdownUsuario(
                  label: 'Tutor del centro',
                  usuarios: admin.tutoresCentro,
                  valor: _tutorCentro,
                  onChanged: (u) => setState(() => _tutorCentro = u),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                _DropdownUsuario(
                  label: 'Tutor de empresa',
                  usuarios: admin.tutoresEmpresa,
                  valor: _tutorEmpresa,
                  onChanged: (u) => setState(() => _tutorEmpresa = u),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                DropdownButtonFormField<EmpresaModel>(
                  value: _empresa,
                  decoration: _deco('Empresa'),
                  items: admin.empresas
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.nombre)))
                      .toList(),
                  onChanged: (e) => setState(() => _empresa = e),
                  validator: (v) => v == null ? 'Selecciona una empresa' : null,
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                Row(children: [
                  Expanded(
                    child: _BotonFecha(
                      label: 'Inicio',
                      fecha: _fechaInicio,
                      onTap: () => _seleccionarFecha(true),
                    ),
                  ),
                  const SizedBox(width: NexusSizes.spaceMD),
                  Expanded(
                    child: _BotonFecha(
                      label: 'Fin',
                      fecha: _fechaFin,
                      onTap: () => _seleccionarFecha(false),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          style: FilledButton.styleFrom(backgroundColor: NexusColors.primary),
          child: _enviando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Crear práctica'),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceMD),
        isDense: true,
      );

  Widget _campoTexto(TextEditingController ctrl, String label,
      {bool required = false,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _deco(label),
      validator: validator ??
          (required ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null : null),
    );
  }
}

class _DropdownUsuario extends StatelessWidget {
  final String label;
  final List<UsuarioModel> usuarios;
  final UsuarioModel? valor;
  final ValueChanged<UsuarioModel?> onChanged;

  const _DropdownUsuario({
    required this.label,
    required this.usuarios,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<UsuarioModel>(
      value: valor,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceMD),
        isDense: true,
      ),
      items: usuarios
          .map((u) => DropdownMenuItem(
                value: u,
                child: Text(u.nombreCompleto,
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona un $label' : null,
    );
  }
}

class _BotonFecha extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final VoidCallback onTap;

  const _BotonFecha(
      {required this.label, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 14),
      label: Text(
        fecha != null
            ? '${fecha!.day}/${fecha!.month}/${fecha!.year}'
            : '$label: seleccionar',
        style: TextStyle(
            fontSize: 12,
            color: fecha != null ? context.nxt.ink : context.nxt.inkTertiary),
      ),
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceMD)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String mensaje;

  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexusSizes.spaceMD),
      decoration: BoxDecoration(
        color: NexusColors.dangerLight,
        borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
      ),
      child: Text(mensaje,
          style: const TextStyle(color: NexusColors.dangerText, fontSize: 13)),
    );
  }
}

// ---- Vista Usuarios ----

class _VistaUsuarios extends StatelessWidget {
  const _VistaUsuarios();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: context.nxt.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.space3XL, vertical: NexusSizes.spaceLG),
          child: Row(
            children: [
              const Text('Usuarios', style: NexusText.heading2),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _mostrarDialogCrear(context),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Nuevo usuario'),
                style: FilledButton.styleFrom(
                    backgroundColor: NexusColors.primary),
              ),
            ],
          ),
        ),
        Expanded(child: _ListaUsuarios()),
      ],
    );
  }

  void _mostrarDialogCrear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AdminProvider>(),
        child: const _DialogCrearUsuario(),
      ),
    );
  }
}

class _ListaUsuarios extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, admin, _) {
      if (admin.cargando) return const Center(child: CircularProgressIndicator());
      if (admin.usuarios.isEmpty) {
        return Center(
          child: Text('No hay usuarios registrados.',
              style: TextStyle(color: context.nxt.inkSecondary)),
        );
      }

      final grupos = [
        (
          'Alumnos',
          admin.alumnos,
          NexusColors.neutral,
          Icons.school_outlined,
        ),
        (
          'Tutores de Centro',
          admin.tutoresCentro,
          NexusColors.primary,
          Icons.account_balance_outlined,
        ),
        (
          'Tutores de Empresa',
          admin.tutoresEmpresa,
          NexusColors.warning,
          Icons.business_center_outlined,
        ),
        (
          'Administradores',
          admin.usuarios
              .where((u) => u.roles.contains('ROLE_ADMIN'))
              .toList(),
          NexusColors.danger,
          Icons.admin_panel_settings_outlined,
        ),
      ];

      return ListView(
        padding: const EdgeInsets.all(NexusSizes.space2XL),
        children: [
          for (final grupo in grupos)
            if (grupo.$2.isNotEmpty) ...[
              _SeccionHeader(
                label: grupo.$1,
                count: grupo.$2.length,
                color: grupo.$3,
                icon: grupo.$4,
              ),
              const SizedBox(height: NexusSizes.spaceSM),
              ...grupo.$2.map((u) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: NexusSizes.spaceSM),
                    child: _UsuarioCard(usuario: u),
                  )),
              const SizedBox(height: NexusSizes.spaceLG),
            ],
        ],
      );
    });
  }
}

class _SeccionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SeccionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: NexusText.small.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ],
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;

  const _UsuarioCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(
            color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceLG, vertical: NexusSizes.spaceMD),
      child: Row(
        children: [
          _AvatarIniciales(nombre: usuario.nombreCompleto),
          const SizedBox(width: NexusSizes.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.nombreCompleto,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: context.nxt.ink)),
                const SizedBox(height: 2),
                Text(usuario.email,
                    style: TextStyle(
                        fontSize: 12, color: context.nxt.inkSecondary)),
                Text(usuario.dni,
                    style: TextStyle(
                        fontSize: 11, color: context.nxt.inkTertiary)),
              ],
            ),
          ),
          _ChipRol(rol: usuario.rolPrincipal),
          const SizedBox(width: NexusSizes.spaceMD),
          _ChipActivoEstado(activo: usuario.activo),
          const SizedBox(width: NexusSizes.spaceXS),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Editar usuario',
            color: context.nxt.inkSecondary,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AdminProvider>(),
                child: _DialogEditarUsuario(usuario: usuario),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              usuario.activo ? Icons.toggle_on : Icons.toggle_off,
              color: usuario.activo ? NexusColors.success : NexusColors.inkTertiary,
              size: 28,
            ),
            tooltip: usuario.activo ? 'Desactivar' : 'Activar',
            onPressed: () =>
                context.read<AdminProvider>().toggleActivo(usuario.id),
          ),
        ],
      ),
    );
  }
}

class _AvatarIniciales extends StatelessWidget {
  final String nombre;

  const _AvatarIniciales({required this.nombre});

  String get _iniciales {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: NexusColors.primaryLight,
      child: Text(_iniciales,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NexusColors.primaryText)),
    );
  }
}

class _ChipRol extends StatelessWidget {
  final String rol;

  const _ChipRol({required this.rol});

  Color get _color {
    switch (rol) {
      case 'Admin': return NexusColors.danger;
      case 'Tutor Centro': return NexusColors.primary;
      case 'Tutor Empresa': return NexusColors.warning;
      default: return NexusColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceSM, vertical: NexusSizes.spaceXS),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(rol,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: _color)),
    );
  }
}

class _ChipActivoEstado extends StatelessWidget {
  final bool activo;

  const _ChipActivoEstado({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceSM, vertical: NexusSizes.spaceXS),
      decoration: BoxDecoration(
        color: activo ? NexusColors.successLight : NexusColors.neutralLight,
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: activo ? NexusColors.successText : NexusColors.neutralText),
      ),
    );
  }
}

// ---- Dialog crear usuario ----

class _DialogCrearUsuario extends StatefulWidget {
  const _DialogCrearUsuario();

  @override
  State<_DialogCrearUsuario> createState() => _DialogCrearUsuarioState();
}

class _DialogCrearUsuarioState extends State<_DialogCrearUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _dniCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _rolSeleccionado = 'ROLE_ALUMNO';
  bool _enviando = false;
  String? _error;

  static const _roles = [
    ('ROLE_ALUMNO', 'Alumno'),
    ('ROLE_TUTOR_CENTRO', 'Tutor Centro'),
    ('ROLE_TUTOR_EMPRESA', 'Tutor Empresa'),
    ('ROLE_ADMIN', 'Administrador'),
  ];

  @override
  void dispose() {
    _dniCtrl.dispose(); _nombreCtrl.dispose(); _apellidosCtrl.dispose();
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _enviando = true; _error = null; });
    final ok = await context.read<AdminProvider>().crearUsuario(
      dni: _dniCtrl.text.trim(), nombre: _nombreCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(), email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text, rolNombre: _rolSeleccionado,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuario creado correctamente'),
        backgroundColor: NexusColors.success,
      ));
    } else {
      setState(() {
        _error = context.read<AdminProvider>().error;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo usuario', style: NexusText.heading3),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                _ErrorBanner(mensaje: _error!),
                const SizedBox(height: NexusSizes.spaceMD),
              ],
              Row(children: [
                Expanded(child: _campo(_nombreCtrl, 'Nombre', required: true)),
                const SizedBox(width: NexusSizes.spaceMD),
                Expanded(child: _campo(_apellidosCtrl, 'Apellidos', required: true)),
              ]),
              const SizedBox(height: NexusSizes.spaceMD),
              Row(children: [
                Expanded(child: _campo(_dniCtrl, 'DNI', required: true)),
                const SizedBox(width: NexusSizes.spaceMD),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    decoration: _deco('Rol'),
                    items: _roles.map((r) =>
                        DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
                    onChanged: (v) => setState(() => _rolSeleccionado = v!),
                  ),
                ),
              ]),
              const SizedBox(height: NexusSizes.spaceMD),
              _campo(_emailCtrl, 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null),
              const SizedBox(height: NexusSizes.spaceMD),
              _campo(_passwordCtrl, 'Contraseña temporal',
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          style: FilledButton.styleFrom(backgroundColor: NexusColors.primary),
          child: _enviando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Crear'),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
      labelText: label, border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceMD),
      isDense: true);

  Widget _campo(TextEditingController ctrl, String label,
      {bool required = false, bool obscure = false,
      TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: _deco(label),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
              : null),
    );
  }
}

// ---- Vista Empresas ----

class _VistaEmpresas extends StatefulWidget {
  const _VistaEmpresas();
  @override
  State<_VistaEmpresas> createState() => _VistaEmpresasState();
}

class _VistaEmpresasState extends State<_VistaEmpresas> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final empresas = provider.empresas
        .where((e) =>
            e.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
            (e.cif ?? '').toLowerCase().contains(_busqueda.toLowerCase()))
        .toList();

    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().cargarTodo(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(NexusSizes.space2XL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Empresas colaboradoras',
                              style: NexusText.heading2.copyWith(letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text('${provider.empresas.length} empresas registradas',
                              style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _mostrarFormulario(context, null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nueva empresa'),
                      style: FilledButton.styleFrom(
                        backgroundColor: NexusColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NexusSizes.spaceLG),
                // Buscador
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o CIF…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: context.nxt.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                      borderSide: BorderSide(color: context.nxt.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                      borderSide: BorderSide(color: context.nxt.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                ),
                const SizedBox(height: NexusSizes.spaceLG),
                if (provider.cargando)
                  const Center(child: CircularProgressIndicator(color: NexusColors.primary))
                else if (empresas.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.business_outlined, size: 48,
                              color: context.nxt.inkSecondary.withAlpha(80)),
                          const SizedBox(height: 12),
                          Text('Sin empresas', style: NexusText.heading2),
                          Text('Pulsa "Nueva empresa" para añadir la primera.',
                              style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: context.nxt.surface,
                      border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                    ),
                    child: Column(
                      children: [
                        // Cabecera tabla
                        Container(
                          decoration: BoxDecoration(
                            color: context.nxt.surfaceAlt,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(NexusSizes.radiusLG - 1)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: const Row(
                            children: [
                              _ColH('Nombre', flex: 4),
                              _ColH('CIF', flex: 2),
                              _ColH('Email contacto', flex: 3),
                              _ColH('Teléfono', flex: 2),
                              _ColH('Acciones', flex: 2),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: context.nxt.border),
                        ...empresas.asMap().entries.map((entry) {
                          final e = entry.value;
                          final isLast = entry.key == empresas.length - 1;
                          return _EmpresaRow(
                            empresa: e,
                            isLast: isLast,
                            onEditar: () => _mostrarFormulario(context, e),
                            onEliminar: () => _confirmarEliminar(context, e),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text('${empresas.length} empresas',
                              style: NexusText.caption),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  Future<void> _mostrarFormulario(BuildContext context, EmpresaModel? empresa) async {
    await showDialog(
      context: context,
      builder: (ctx) => _EmpresaFormDialog(empresa: empresa),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, EmpresaModel empresa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar empresa'),
        content: Text(
          '¿Seguro que quieres eliminar "${empresa.nombre}"? Esta acción no se puede deshacer y fallará si la empresa tiene prácticas asociadas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: NexusColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<AdminProvider>().eliminarEmpresa(empresa.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Empresa eliminada' : context.read<AdminProvider>().error ?? 'Error al eliminar'),
        backgroundColor: ok ? NexusColors.success : NexusColors.danger,
      ));
    }
  }
}

class _EmpresaRow extends StatelessWidget {
  final EmpresaModel empresa;
  final bool isLast;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _EmpresaRow({
    required this.empresa,
    required this.isLast,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: NexusColors.primaryLight,
                    borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                  ),
                  child: const Icon(Icons.business, size: 16, color: NexusColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(empresa.nombre,
                      style: NexusText.small.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(empresa.cif ?? '—',
                style: NexusText.small.copyWith(
                    fontFamily: 'monospace', color: context.nxt.inkSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(empresa.emailContacto ?? '—',
                style: NexusText.small.copyWith(color: context.nxt.inkSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(empresa.telefonoContacto ?? '—',
                style: NexusText.small.copyWith(color: context.nxt.inkSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  color: NexusColors.primary,
                  tooltip: 'Editar',
                  onPressed: onEditar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 17),
                  color: NexusColors.danger,
                  tooltip: 'Eliminar',
                  onPressed: onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpresaFormDialog extends StatefulWidget {
  final EmpresaModel? empresa;
  const _EmpresaFormDialog({this.empresa});

  @override
  State<_EmpresaFormDialog> createState() => _EmpresaFormDialogState();
}

class _EmpresaFormDialogState extends State<_EmpresaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _cif;
  late final TextEditingController _direccion;
  late final TextEditingController _email;
  late final TextEditingController _telefono;
  bool _guardando = false;
  String? _errorMsg;

  bool get _esEdicion => widget.empresa != null;

  @override
  void initState() {
    super.initState();
    final e = widget.empresa;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _cif = TextEditingController(text: e?.cif ?? '');
    _direccion = TextEditingController(text: e?.direccion ?? '');
    _email = TextEditingController(text: e?.emailContacto ?? '');
    _telefono = TextEditingController(text: e?.telefonoContacto ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cif.dispose();
    _direccion.dispose();
    _email.dispose();
    _telefono.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.nxt.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusSizes.radiusLG)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NexusColors.primaryLight,
                        borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                      ),
                      child: const Icon(Icons.business_outlined, size: 16, color: NexusColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _esEdicion ? 'Editar empresa' : 'Nueva empresa',
                        style: NexusText.small.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: context.nxt.inkSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NexusColors.dangerLight,
                      borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 15, color: NexusColors.danger),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMsg!,
                            style: const TextStyle(fontSize: 12, color: NexusColors.danger))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _Campo(
                  label: 'Nombre *',
                  controller: _nombre,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                _Campo(
                  label: 'CIF *',
                  controller: _cif,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  hint: 'Ej: B12345678',
                ),
                const SizedBox(height: 14),
                _Campo(label: 'Dirección', controller: _direccion),
                const SizedBox(height: 14),
                _Campo(
                  label: 'Email de contacto',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!v.contains('@')) return 'Email no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Campo(
                  label: 'Teléfono',
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: NexusColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_esEdicion ? 'Guardar cambios' : 'Crear empresa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _guardando = true; _errorMsg = null; });

    final provider = context.read<AdminProvider>();
    bool ok;

    if (_esEdicion) {
      ok = await provider.editarEmpresa(
        id: widget.empresa!.id,
        nombre: _nombre.text.trim(),
        cif: _cif.text.trim(),
        direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
        emailContacto: _email.text.trim().isEmpty ? null : _email.text.trim(),
        telefonoContacto: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
      );
    } else {
      ok = await provider.crearEmpresa(
        nombre: _nombre.text.trim(),
        cif: _cif.text.trim(),
        direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
        emailContacto: _email.text.trim().isEmpty ? null : _email.text.trim(),
        telefonoContacto: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_esEdicion ? 'Empresa actualizada' : 'Empresa creada correctamente'),
        backgroundColor: NexusColors.success,
      ));
    } else {
      setState(() {
        _guardando = false;
        _errorMsg = provider.error ?? 'Error desconocido';
      });
    }
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? hint;

  const _Campo({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: NexusText.caption.copyWith(
                fontWeight: FontWeight.w600, color: context.nxt.ink)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: NexusText.small,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: context.nxt.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
              borderSide: BorderSide(color: context.nxt.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
              borderSide: BorderSide(color: context.nxt.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
              borderSide: const BorderSide(color: NexusColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ---- Vista Auditoría ----

class _VistaAuditoria extends StatefulWidget {
  const _VistaAuditoria();

  @override
  State<_VistaAuditoria> createState() => _VistaAuditoriaState();
}

class _VistaAuditoriaState extends State<_VistaAuditoria> {
  static const _modulos = ['TODOS', 'USUARIOS', 'PRACTICAS', 'AUSENCIAS', 'INCIDENCIAS', 'SEGUIMIENTOS'];
  String _moduloSeleccionado = 'TODOS';

  static const _coloresModulo = {
    'USUARIOS': NexusColors.danger,
    'PRACTICAS': NexusColors.primary,
    'AUSENCIAS': NexusColors.warning,
    'INCIDENCIAS': Color(0xFFE57373),
    'SEGUIMIENTOS': NexusColors.success,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarAuditLogs();
    });
  }

  void _cambiarModulo(String modulo) {
    setState(() => _moduloSeleccionado = modulo);
    final filtro = modulo == 'TODOS' ? null : modulo;
    context.read<AdminProvider>().cargarAuditLogs(modulo: filtro);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: context.nxt.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.space3XL, vertical: NexusSizes.spaceLG),
          child: Row(
            children: [
              const Text('Auditoría del sistema', style: NexusText.heading2),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Recargar',
                onPressed: () => _cambiarModulo(_moduloSeleccionado),
              ),
            ],
          ),
        ),
        Container(
          color: context.nxt.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.space3XL, vertical: NexusSizes.spaceSM),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _modulos.map((m) {
                final activo = _moduloSeleccionado == m;
                final color = m == 'TODOS' ? context.nxt.ink : (_coloresModulo[m] ?? context.nxt.ink);
                return Padding(
                  padding: const EdgeInsets.only(right: NexusSizes.spaceSM),
                  child: FilterChip(
                    label: Text(m),
                    selected: activo,
                    onSelected: (_) => _cambiarModulo(m),
                    selectedColor: color.withOpacity(0.15),
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                        color: activo ? color : context.nxt.inkSecondary),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(child: Consumer<AdminProvider>(
          builder: (context, admin, _) {
            if (admin.cargandoAudit) {
              return const Center(child: CircularProgressIndicator());
            }
            if (admin.auditLogs.isEmpty) {
              return Center(
                child: Text('No hay registros de auditoría.',
                    style: TextStyle(color: context.nxt.inkSecondary)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              itemCount: admin.auditLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: NexusSizes.spaceXS),
              itemBuilder: (_, i) => _AuditLogTile(
                log: admin.auditLogs[i],
                color: _coloresModulo[admin.auditLogs[i].modulo] ?? context.nxt.ink,
              ),
            );
          },
        )),
      ],
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLogModel log;
  final Color color;

  const _AuditLogTile({required this.log, required this.color});

  @override
  Widget build(BuildContext context) {
    final fecha = log.fecha;
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}  '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceLG, vertical: NexusSizes.spaceMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: NexusSizes.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ChipModulo(modulo: log.modulo, color: color),
                    const SizedBox(width: NexusSizes.spaceSM),
                    Text(log.accion,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: context.nxt.ink)),
                    if (log.entidadId != null) ...[
                      const SizedBox(width: NexusSizes.spaceXS),
                      Text('#${log.entidadId}',
                          style: TextStyle(
                              fontSize: 11, color: context.nxt.inkTertiary)),
                    ],
                    const Spacer(),
                    Text(fechaStr,
                        style: TextStyle(
                            fontSize: 11, color: context.nxt.inkTertiary)),
                  ],
                ),
                if (log.descripcion != null && log.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.descripcion!,
                      style: TextStyle(
                          fontSize: 12, color: context.nxt.inkSecondary)),
                ],
                if (log.usuarioEmail != null) ...[
                  const SizedBox(height: 2),
                  Text('por ${log.usuarioEmail}',
                      style: TextStyle(
                          fontSize: 11, color: context.nxt.inkTertiary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipModulo extends StatelessWidget {
  final String modulo;
  final Color color;

  const _ChipModulo({required this.modulo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(modulo,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ---- Dialog editar usuario ----

class _DialogEditarUsuario extends StatefulWidget {
  final UsuarioModel usuario;
  const _DialogEditarUsuario({required this.usuario});

  @override
  State<_DialogEditarUsuario> createState() => _DialogEditarUsuarioState();
}

class _DialogEditarUsuarioState extends State<_DialogEditarUsuario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _emailCtrl;
  late String _rolSeleccionado;
  bool _enviando = false;
  String? _error;

  static const _roles = [
    ('ROLE_ALUMNO', 'Alumno'),
    ('ROLE_TUTOR_CENTRO', 'Tutor Centro'),
    ('ROLE_TUTOR_EMPRESA', 'Tutor Empresa'),
    ('ROLE_ADMIN', 'Administrador'),
  ];

  String _rolActual(UsuarioModel u) {
    if (u.roles.contains('ROLE_ADMIN')) return 'ROLE_ADMIN';
    if (u.roles.contains('ROLE_TUTOR_CENTRO')) return 'ROLE_TUTOR_CENTRO';
    if (u.roles.contains('ROLE_TUTOR_EMPRESA')) return 'ROLE_TUTOR_EMPRESA';
    return 'ROLE_ALUMNO';
  }

  @override
  void initState() {
    super.initState();
    _dniCtrl = TextEditingController(text: widget.usuario.dni);
    _nombreCtrl = TextEditingController(text: widget.usuario.nombre);
    _apellidosCtrl = TextEditingController(text: widget.usuario.apellidos);
    _emailCtrl = TextEditingController(text: widget.usuario.email);
    _rolSeleccionado = _rolActual(widget.usuario);
  }

  @override
  void dispose() {
    _dniCtrl.dispose(); _nombreCtrl.dispose();
    _apellidosCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _enviando = true; _error = null; });
    final ok = await context.read<AdminProvider>().editarUsuario(
      id: widget.usuario.id,
      dni: _dniCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      rolNombre: _rolSeleccionado,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuario actualizado correctamente'),
        backgroundColor: NexusColors.success,
      ));
    } else {
      setState(() {
        _error = context.read<AdminProvider>().error;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar usuario', style: NexusText.heading3),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                _ErrorBanner(mensaje: _error!),
                const SizedBox(height: NexusSizes.spaceMD),
              ],
              Row(children: [
                Expanded(child: _campo(_nombreCtrl, 'Nombre', required: true)),
                const SizedBox(width: NexusSizes.spaceMD),
                Expanded(child: _campo(_apellidosCtrl, 'Apellidos', required: true)),
              ]),
              const SizedBox(height: NexusSizes.spaceMD),
              Row(children: [
                Expanded(child: _campo(_dniCtrl, 'DNI', required: true)),
                const SizedBox(width: NexusSizes.spaceMD),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    decoration: _deco('Rol'),
                    items: _roles.map((r) =>
                        DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
                    onChanged: (v) => setState(() => _rolSeleccionado = v!),
                  ),
                ),
              ]),
              const SizedBox(height: NexusSizes.spaceMD),
              _campo(_emailCtrl, 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null),
              const SizedBox(height: NexusSizes.spaceXS),
              Text(
                'La contraseña no se puede editar desde aquí.',
                style: TextStyle(fontSize: 11, color: context.nxt.inkTertiary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          style: FilledButton.styleFrom(backgroundColor: NexusColors.primary),
          child: _enviando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
      labelText: label, border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceMD),
      isDense: true);

  Widget _campo(TextEditingController ctrl, String label,
      {bool required = false, TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _deco(label),
      validator: validator ??
          (required ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null : null),
    );
  }
}

// ---- Dialog editar práctica ----

class _DialogEditarPractica extends StatefulWidget {
  final Practica practica;
  const _DialogEditarPractica({required this.practica});

  @override
  State<_DialogEditarPractica> createState() => _DialogEditarPracticaState();
}

class _DialogEditarPracticaState extends State<_DialogEditarPractica> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _horasCtrl;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  UsuarioModel? _alumno;
  UsuarioModel? _tutorCentro;
  UsuarioModel? _tutorEmpresa;
  EmpresaModel? _empresa;
  late String _estado;
  bool _enviando = false;
  String? _error;

  static const _estados = ['BORRADOR', 'ACTIVA', 'FINALIZADA'];

  @override
  void initState() {
    super.initState();
    final p = widget.practica;
    _codigoCtrl = TextEditingController(text: p.codigo);
    _horasCtrl = TextEditingController(text: p.horasTotales?.toString() ?? '');
    _fechaInicio = p.fechaInicio;
    _fechaFin = p.fechaFin;
    _estado = p.estado;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_alumno == null) {
      final admin = context.read<AdminProvider>();
      final p = widget.practica;
      _alumno = admin.alumnos.where((u) => u.id == p.alumnoId).firstOrNull;
      _tutorCentro = admin.tutoresCentro.where((u) => u.id == p.tutorCentroId).firstOrNull;
      _tutorEmpresa = admin.tutoresEmpresa.where((u) => u.id == p.tutorEmpresaId).firstOrNull;
      _empresa = admin.empresas.where((e) => e.id == p.empresaId).firstOrNull;
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _horasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) _fechaInicio = picked;
        else _fechaFin = picked;
      });
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _error = 'Las fechas de inicio y fin son obligatorias');
      return;
    }
    setState(() { _enviando = true; _error = null; });

    final ok = await context.read<AdminProvider>().editarPractica(
      id: widget.practica.id,
      codigo: _codigoCtrl.text.trim(),
      alumnoId: _alumno!.id,
      tutorCentroId: _tutorCentro!.id,
      tutorEmpresaId: _tutorEmpresa!.id,
      empresaId: _empresa!.id,
      fechaInicio: _fechaInicio!.toIso8601String().split('T')[0],
      fechaFin: _fechaFin!.toIso8601String().split('T')[0],
      horasTotales: int.parse(_horasCtrl.text.trim()),
      estado: _estado,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Práctica actualizada correctamente'),
        backgroundColor: NexusColors.success,
      ));
    } else {
      setState(() {
        _error = context.read<AdminProvider>().error;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return AlertDialog(
      title: const Text('Editar práctica', style: NexusText.heading3),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  _ErrorBanner(mensaje: _error!),
                  const SizedBox(height: NexusSizes.spaceMD),
                ],
                Row(children: [
                  Expanded(child: _campoTexto(_codigoCtrl, 'Código', required: true)),
                  const SizedBox(width: NexusSizes.spaceMD),
                  Expanded(
                    child: _campoTexto(_horasCtrl, 'Horas totales',
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null)
                            ? 'Número válido'
                            : null),
                  ),
                ]),
                const SizedBox(height: NexusSizes.spaceMD),
                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: _deco('Estado'),
                  items: _estados.map((e) =>
                      DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                _DropdownUsuario(
                  label: 'Alumno',
                  usuarios: admin.alumnos,
                  valor: _alumno,
                  onChanged: (u) => setState(() => _alumno = u),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                _DropdownUsuario(
                  label: 'Tutor del centro',
                  usuarios: admin.tutoresCentro,
                  valor: _tutorCentro,
                  onChanged: (u) => setState(() => _tutorCentro = u),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                _DropdownUsuario(
                  label: 'Tutor de empresa',
                  usuarios: admin.tutoresEmpresa,
                  valor: _tutorEmpresa,
                  onChanged: (u) => setState(() => _tutorEmpresa = u),
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                DropdownButtonFormField<EmpresaModel>(
                  value: _empresa,
                  decoration: _deco('Empresa'),
                  items: admin.empresas
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.nombre)))
                      .toList(),
                  onChanged: (e) => setState(() => _empresa = e),
                  validator: (v) => v == null ? 'Selecciona una empresa' : null,
                ),
                const SizedBox(height: NexusSizes.spaceMD),
                Row(children: [
                  Expanded(
                    child: _BotonFecha(
                      label: 'Inicio',
                      fecha: _fechaInicio,
                      onTap: () => _seleccionarFecha(true),
                    ),
                  ),
                  const SizedBox(width: NexusSizes.spaceMD),
                  Expanded(
                    child: _BotonFecha(
                      label: 'Fin',
                      fecha: _fechaFin,
                      onTap: () => _seleccionarFecha(false),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          style: FilledButton.styleFrom(backgroundColor: NexusColors.primary),
          child: _enviando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceMD),
        isDense: true,
      );

  Widget _campoTexto(TextEditingController ctrl, String label,
      {bool required = false,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _deco(label),
      validator: validator ??
          (required ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null : null),
    );
  }
}

// ---- Mobile bottom nav ----

class _MobileBottomNavAdmin extends StatelessWidget {
  final _ModoAdmin modo;
  final ValueChanged<_ModoAdmin> onChanged;

  const _MobileBottomNavAdmin(
      {required this.modo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(top: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _MobileNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              isActive: modo == _ModoAdmin.dashboard,
              onTap: () => onChanged(_ModoAdmin.dashboard),
            ),
            _MobileNavItem(
              icon: Icons.folder_open_outlined,
              activeIcon: Icons.folder_open,
              label: 'Prácticas',
              isActive: modo == _ModoAdmin.practicas,
              onTap: () => onChanged(_ModoAdmin.practicas),
            ),
            _MobileNavItem(
              icon: Icons.people_alt_outlined,
              activeIcon: Icons.people_alt,
              label: 'Usuarios',
              isActive: modo == _ModoAdmin.usuarios,
              onTap: () => onChanged(_ModoAdmin.usuarios),
            ),
            _MobileNavItem(
              icon: Icons.business_outlined,
              activeIcon: Icons.business,
              label: 'Empresas',
              isActive: modo == _ModoAdmin.empresas,
              onTap: () => onChanged(_ModoAdmin.empresas),
            ),
            _MobileNavItem(
              icon: Icons.history_outlined,
              activeIcon: Icons.history,
              label: 'Auditoría',
              isActive: modo == _ModoAdmin.auditoria,
              onTap: () => onChanged(_ModoAdmin.auditoria),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? NexusColors.primary : NexusColors.inkTertiary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? NexusColors.primary : NexusColors.inkTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColH extends StatelessWidget {
  final String label;
  final int flex;
  const _ColH(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.nxt.inkTertiary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
