import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../providers/auth_provider.dart';
import '../providers/tutor_centro_provider.dart';
import 'chat_placeholder_screen.dart';
import 'ficha_alumno_screen.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import '../widgets/nexus_avatar.dart';
import '../providers/notificacion_provider.dart';
import '../widgets/nexus_logo.dart';

enum _Mode { alumnos, partes, incidencias, chat }

class PanelTutorCentroScreen extends StatefulWidget {
  const PanelTutorCentroScreen({super.key});

  @override
  State<PanelTutorCentroScreen> createState() =>
      _PanelTutorCentroScreenState();
}

class _PanelTutorCentroScreenState extends State<PanelTutorCentroScreen> {
  _Mode _mode = _Mode.alumnos;
  String _canalChat = 'ALUMNO'; // 'ALUMNO' | 'TUTORES'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorCentroProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<TutorCentroProvider>();

    return Scaffold(
      backgroundColor: context.nxt.surfaceAlt,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = MediaQuery.sizeOf(context).width > 600;

          if (isWide) {
            return Row(
              children: [
                _Sidebar(
                  auth: auth,
                  provider: provider,
                  mode: _mode,
                  onChangeMode: (m) => setState(() => _mode = m),
                ),
                if (_mode == _Mode.alumnos || _mode == _Mode.chat) ...[
                  _StudentList(provider: provider),
                  Expanded(
                    child: switch (_mode) {
                      _Mode.chat => _ChatDualPane(
                          practicaId: provider.selectedPractica?.id,
                          canalActivo: _canalChat,
                          onCanalChanged: (c) => setState(() => _canalChat = c),
                          alumnoNombre: provider.selectedPractica?.alumnoNombre ?? '',
                          empresaNombre: provider.selectedPractica?.empresaNombre ?? '',
                        ),
                      _ => _DetailPanel(
                          provider: provider,
                          auth: auth,
                          onValidar: _confirmarValidar,
                          onCambiarEstadoIncidencia: _mostrarModalEstado,
                          onChatTap: () => setState(() {
                            _mode = _Mode.chat;
                            _canalChat = 'ALUMNO';
                          }),
                          onChatTutoresTap: () => setState(() {
                            _mode = _Mode.chat;
                            _canalChat = 'TUTORES';
                          }),
                        ),
                    },
                  ),
                ] else
                  Expanded(child: _buildWidePanel(provider)),
              ],
            );
          }

          // Mobile
          return Column(
            children: [
              _MobileHeader(auth: auth),
              Expanded(child: _buildMobileBody(provider, auth)),
              _MobileBottomNav(
                mode: _mode,
                onChangeMode: (m) => setState(() {
                  _mode = m;
                  if (m != _Mode.alumnos && m != _Mode.chat) {
                    provider.seleccionar(-1);
                  }
                }),
                pendientePartes: provider.todosPendientesCentro.length,
                pendienteIncidencias:
                    provider.todasIncidencias.where((i) => i.estaAbierta).length,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWidePanel(TutorCentroProvider provider) {
    switch (_mode) {
      case _Mode.partes:
        return _AllPartesPanel(provider: provider, onValidar: _confirmarValidar);
      case _Mode.incidencias:
        return _AllIncidenciasPanel(
            provider: provider, onCambiarEstado: _mostrarModalEstado);
      case _Mode.chat:
        return _ChatDualPane(
          practicaId: provider.selectedPractica?.id,
          canalActivo: _canalChat,
          onCanalChanged: (c) => setState(() => _canalChat = c),
          alumnoNombre: provider.selectedPractica?.alumnoNombre ?? '',
          empresaNombre: provider.selectedPractica?.empresaNombre ?? '',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMobileBody(TutorCentroProvider provider, AuthProvider auth) {
    switch (_mode) {
      case _Mode.partes:
        return _AllPartesPanel(provider: provider, onValidar: _confirmarValidar);
      case _Mode.incidencias:
        return _AllIncidenciasPanel(
            provider: provider, onCambiarEstado: _mostrarModalEstado);
      case _Mode.chat:
        if (provider.selectedPractica == null) {
          return _StudentList(provider: provider, isMobile: true);
        }
        return _ChatDualPane(
          practicaId: provider.selectedPractica?.id,
          canalActivo: _canalChat,
          onCanalChanged: (c) => setState(() => _canalChat = c),
          alumnoNombre: provider.selectedPractica?.alumnoNombre ?? '',
          empresaNombre: provider.selectedPractica?.empresaNombre ?? '',
        );
      case _Mode.alumnos:
        if (provider.selectedPractica == null) {
          return _StudentList(provider: provider, isMobile: true);
        }
        return _DetailPanel(
          provider: provider,
          auth: auth,
          onValidar: _confirmarValidar,
          onCambiarEstadoIncidencia: _mostrarModalEstado,
          showBackButton: true,
          onBack: () => provider.seleccionar(-1),
          onChatTap: () => setState(() {
            _mode = _Mode.chat;
            _canalChat = 'ALUMNO';
          }),
          onChatTutoresTap: () => setState(() {
            _mode = _Mode.chat;
            _canalChat = 'TUTORES';
          }),
        );
    }
  }

  Future<void> _confirmarValidar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dar visto bueno'),
        content: const Text(
            '¿Confirmas que este parte cumple los requisitos formativos?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ok =
        await context.read<TutorCentroProvider>().validarCentro(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Parte completado correctamente'
            : 'Error al completar el parte'),
        backgroundColor: ok ? NexusColors.success : NexusColors.danger,
      ));
    }
  }

  Future<void> _mostrarModalEstado(Incidencia incidencia) async {
    final siguientes = _siguientesEstados(incidencia.estado);
    if (siguientes.isEmpty) return;

    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.nxt.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NexusColors.dangerLight,
                        borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          size: 16, color: NexusColors.danger),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gestionar incidencia',
                              style: NexusText.small.copyWith(fontWeight: FontWeight.w700)),
                          Text(incidencia.descripcion,
                              style: NexusText.caption.copyWith(color: ctx.nxt.inkSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: ctx.nxt.inkSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Cambiar estado a:',
                    style: NexusText.caption.copyWith(
                        color: ctx.nxt.inkSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ...siguientes.map((estado) {
                  final color = _colorEstado(context, estado);
                  final bg = color.withAlpha(20);
                  final icon = _iconEstado(estado);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, estado),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: color.withAlpha(60)),
                          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 16, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Marcar como ${_labelEstado(estado)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: color.withAlpha(160)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );

    if (nuevoEstado == null || !mounted) return;
    final ok = await context
        .read<TutorCentroProvider>()
        .actualizarEstadoIncidencia(incidencia.id, nuevoEstado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Incidencia actualizada' : 'Error al actualizar'),
        backgroundColor: ok ? NexusColors.success : NexusColors.danger,
      ));
    }
  }

  List<String> _siguientesEstados(String actual) {
    const orden = ['ABIERTA', 'EN_PROCESO', 'RESUELTA', 'CERRADA'];
    final idx = orden.indexOf(actual);
    if (idx == -1 || idx >= orden.length - 1) return [];
    return orden.sublist(idx + 1);
  }

  String _labelEstado(String estado) {
    const labels = {
      'EN_PROCESO': 'En proceso',
      'RESUELTA': 'Resuelta',
      'CERRADA': 'Cerrada',
    };
    return labels[estado] ?? estado;
  }

  Color _colorEstado(BuildContext context, String estado) {
    switch (estado) {
      case 'EN_PROCESO': return NexusColors.primary;
      case 'RESUELTA': return NexusColors.success;
      default: return context.nxt.inkSecondary;
    }
  }

  IconData _iconEstado(String estado) {
    switch (estado) {
      case 'EN_PROCESO': return Icons.autorenew_rounded;
      case 'RESUELTA': return Icons.check_circle_outline_rounded;
      case 'CERRADA': return Icons.lock_outline_rounded;
      default: return Icons.circle_outlined;
    }
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final AuthProvider auth;
  final TutorCentroProvider provider;
  final _Mode mode;
  final ValueChanged<_Mode> onChangeMode;

  const _Sidebar({
    required this.auth,
    required this.provider,
    required this.mode,
    required this.onChangeMode,
  });

  @override
  Widget build(BuildContext context) {
    final incAbiertos =
        provider.todasIncidencias.where((i) => i.estaAbierta).length;
    final partesPendientes = provider.todosPendientesCentro.length;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(
            right: BorderSide(
                color: context.nxt.border,
                width: NexusSizes.borderWidth)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: const NexusLogo(height: 26),
          ),
          const SizedBox(height: 10),
          _NavBtn(
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            tooltip: 'Alumnos',
            isActive: mode == _Mode.alumnos,
            onTap: () => onChangeMode(_Mode.alumnos),
          ),
          const SizedBox(height: 4),
          _NavBadgeBtn(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            tooltip: 'Partes pendientes',
            isActive: mode == _Mode.partes,
            badgeCount: partesPendientes,
            badgeColor: NexusColors.warning,
            onTap: () => onChangeMode(_Mode.partes),
          ),
          const SizedBox(height: 4),
          _NavBadgeBtn(
            icon: Icons.warning_amber_outlined,
            activeIcon: Icons.warning_amber,
            tooltip: 'Incidencias',
            isActive: mode == _Mode.incidencias,
            badgeCount: incAbiertos,
            badgeColor: NexusColors.danger,
            onTap: () => onChangeMode(_Mode.incidencias),
          ),
          const SizedBox(height: 4),
          _NavBtn(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            tooltip: 'Chat',
            isActive: mode == _Mode.chat,
            onTap: () => onChangeMode(_Mode.chat),
          ),
          const Spacer(),
          // Perfil
          Tooltip(
            message: 'Mi perfil',
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen())),
              child: Container(
                width: double.infinity,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    NexusAvatar(
                      userId: auth.user!.id,
                      nombre: auth.user!.nombreCompleto,
                      radius: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.user!.nombreCompleto.split(' ').first,
                        style: NexusText.small.copyWith(
                          color: context.nxt.inkSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Notificaciones
          Consumer<NotificacionProvider>(
            builder: (ctx, notifProv, _) {
              final count = notifProv.noLeidas;
              return Tooltip(
                message: 'Notificaciones',
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                          value: notifProv,
                          child: const NotificacionesScreen(),
                        )));
                    notifProv.cargar();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Badge(
                          isLabelVisible: count > 0,
                          label: Text(count > 9 ? '9+' : '$count',
                              style: const TextStyle(fontSize: 10)),
                          child: Icon(Icons.notifications_none_outlined,
                              size: 16, color: ctx.nxt.inkSecondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notificaciones',
                            style: NexusText.small.copyWith(
                              color: ctx.nxt.inkSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          // Tema y logout
          Builder(builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final iconColor = ctx.nxt.inkSecondary;
            return Column(children: [
              Tooltip(
                message: isDark ? 'Modo claro' : 'Modo oscuro',
                child: GestureDetector(
                  onTap: () => ctx.read<ThemeProvider>().toggle(),
                  child: Container(
                    width: double.infinity,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isDark ? 'Modo claro' : 'Modo oscuro',
                            style: NexusText.small.copyWith(color: iconColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Tooltip(
                message: 'Cerrar sesión',
                child: GestureDetector(
                  onTap: () => auth.logout(),
                  child: Container(
                    width: double.infinity,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(Icons.logout_outlined, size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cerrar sesión',
                            style: NexusText.small.copyWith(color: iconColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getInitials(String nombre) {
    final parts =
        nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? activeBgColor;

  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
    this.activeColor,
    this.activeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? NexusColors.primary;
    final bgColor = activeBgColor ?? NexusColors.primaryLight;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? bgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 16,
                color: isActive ? color : context.nxt.inkSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tooltip,
                  style: NexusText.small.copyWith(
                    color: isActive ? color : context.nxt.inkSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBadgeBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final bool isActive;
  final int badgeCount;
  final Color badgeColor;
  final VoidCallback onTap;

  const _NavBadgeBtn({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.isActive,
    required this.badgeCount,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? NexusColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 16,
                    color: isActive
                        ? NexusColors.primary
                        : context.nxt.inkSecondary,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: -4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: context.nxt.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tooltip,
                  style: NexusText.small.copyWith(
                    color: isActive
                        ? NexusColors.primary
                        : context.nxt.inkSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Student list ───────────────────────────────────────────────────────────────

class _StudentList extends StatelessWidget {
  final TutorCentroProvider provider;
  final bool isMobile;
  const _StudentList({required this.provider, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Container(
        width: isMobile ? double.infinity : 220,
        color: context.nxt.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final practicas = provider.practicas;

    return Container(
      width: isMobile ? double.infinity : 220,
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(
          right: BorderSide(
              color: context.nxt.border, width: NexusSizes.borderWidth),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: context.nxt.border,
                      width: NexusSizes.borderWidth)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mis alumnos',
                    style: NexusText.small
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${practicas.length} en prácticas activas',
                  style: NexusText.caption
                      .copyWith(color: context.nxt.inkSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: practicas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(NexusSizes.spaceLG),
                      child: Text('Sin alumnos asignados',
                          style: NexusText.caption
                              .copyWith(color: context.nxt.inkSecondary),
                          textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    itemCount: practicas.length,
                    itemBuilder: (context, i) {
                      final p = practicas[i];
                      return _StudentItem(
                        practica: p,
                        isSelected: provider.selectedPracticaId == p.id,
                        pendientesCentro:
                            provider.pendientesCentroDe(p.id).length,
                        incidenciasAbiertas: provider
                            .incidenciasDe(p.id)
                            .where((x) => x.estaAbierta)
                            .length,
                        ausenciasInjustificadas:
                            provider.ausenciasInjustificadasDe(p.id).length,
                        onTap: () => provider.seleccionar(p.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentItem extends StatelessWidget {
  final Practica practica;
  final bool isSelected;
  final int pendientesCentro;
  final int incidenciasAbiertas;
  final int ausenciasInjustificadas;
  final VoidCallback onTap;

  const _StudentItem({
    required this.practica,
    required this.isSelected,
    required this.pendientesCentro,
    required this.incidenciasAbiertas,
    required this.ausenciasInjustificadas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge;
    final alertaTotal = incidenciasAbiertas + ausenciasInjustificadas;
    if (alertaTotal > 0) {
      badge = _MiniPill(
          label: '!$alertaTotal',
          bg: NexusColors.dangerLight,
          textColor: NexusColors.dangerText);
    } else if (pendientesCentro > 0) {
      badge = _MiniPill(
          label: 'Rev.',
          bg: NexusColors.warningLight,
          textColor: NexusColors.warningText);
    } else {
      badge = _MiniPill(
          label: 'OK',
          bg: NexusColors.successLight,
          textColor: NexusColors.successText);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: isSelected ? NexusColors.primary.withAlpha(14) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(isSelected ? 9 : 12, 11, 12, 11),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: isSelected ? NexusColors.primary : Colors.transparent,
                  width: 3),
              bottom: BorderSide(
                  color: context.nxt.border,
                  width: NexusSizes.borderWidth),
            ),
          ),
          child: Row(
            children: [
              NexusAvatar(
                userId: practica.alumnoId,
                nombre: practica.alumnoNombre,
                radius: 14,
                backgroundColor: NexusColors.primaryLight,
                textColor: NexusColors.primaryText,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(practica.alumnoNombre,
                        style: NexusText.small.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? NexusColors.primary : context.nxt.ink),
                        overflow: TextOverflow.ellipsis),
                    Text(practica.empresaNombre,
                        style: NexusText.caption.copyWith(
                            fontSize: 10,
                            color: context.nxt.inkSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              badge,
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String nombre) {
    final parts =
        nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _MiniPill(
      {required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

// ── Detail panel ───────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final TutorCentroProvider provider;
  final AuthProvider auth;
  final void Function(int) onValidar;
  final void Function(Incidencia) onCambiarEstadoIncidencia;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onChatTap;
  final VoidCallback? onChatTutoresTap;

  const _DetailPanel({
    required this.provider,
    required this.auth,
    required this.onValidar,
    required this.onCambiarEstadoIncidencia,
    this.showBackButton = false,
    this.onBack,
    this.onChatTap,
    this.onChatTutoresTap,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return _ErrorState(
          message: provider.error!,
          onRetry: () => context.read<TutorCentroProvider>().cargar());
    }

    final practica = provider.selectedPractica;
    if (practica == null) {
      return const _SelectPrompt();
    }

    final pendientes = provider.pendientesCentroDe(practica.id);
    final incidencias = provider.incidenciasDe(practica.id);
    final ausenciasInjustificadas = provider.ausenciasInjustificadasDe(practica.id);
    final horasCompletadas = provider.horasCompletadasDe(practica.id);
    final horasTotales = practica.horasTotales ?? 240;
    final progreso = horasTotales > 0
        ? (horasCompletadas / horasTotales).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progreso * 100).round();

    final incAbiertasCount = incidencias.where((i) => i.estaAbierta).length;

    return RefreshIndicator(
      onRefresh: () => context.read<TutorCentroProvider>().cargar(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: LayoutBuilder(
            builder: (ctx, cst) {
              final twoCol = cst.maxWidth > 650;

              // ── Header alumno ──────────────────────────────────────────
              final alumnoHeader = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBackButton) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                  ],
                  NexusAvatar(
                    userId: practica.alumnoId,
                    nombre: practica.alumnoNombre,
                    radius: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(practica.alumnoNombre,
                            style: NexusText.heading2.copyWith(letterSpacing: -0.3),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          '${practica.empresaNombre} · ${practica.codigo}',
                          style: NexusText.body.copyWith(color: ctx.nxt.inkSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    label: practica.estado == 'ACTIVA' ? 'En curso' : practica.estado,
                    color: practica.estado == 'ACTIVA' ? NexusColors.primary : ctx.nxt.inkSecondary,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    tooltip: 'Ver ficha completa',
                    color: NexusColors.primary,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FichaAlumnoScreen(practica: practica)),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              );

              // ── Mini stats ─────────────────────────────────────────────
              final miniStats = Row(
                children: [
                  Expanded(
                    child: _MiniStatBadge(
                      label: 'Horas completadas',
                      value: '${fmtH(horasCompletadas)} / ${horasTotales}h',
                      color: NexusColors.primary,
                      icon: Icons.access_time_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatBadge(
                      label: 'Partes pendientes',
                      value: '${pendientes.length}',
                      color: pendientes.isNotEmpty ? NexusColors.warning : NexusColors.success,
                      icon: Icons.pending_actions_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatBadge(
                      label: 'Incidencias abiertas',
                      value: '$incAbiertasCount',
                      color: incAbiertasCount > 0 ? NexusColors.danger : NexusColors.success,
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                ],
              );

              // ── Progreso FCT ───────────────────────────────────────────
              final progresoCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ctx.nxt.surface,
                  border: Border.all(color: ctx.nxt.border, width: NexusSizes.borderWidth),
                  borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Progreso FCT',
                                  style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                              Text('$pct% del total completado',
                                  style: NexusText.caption.copyWith(color: ctx.nxt.inkSecondary)),
                            ],
                          ),
                        ),
                        Text(
                          '${fmtH(horasCompletadas)} / ${horasTotales}h',
                          style: NexusText.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: ctx.nxt.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progreso,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: pct >= 80
                                  ? NexusColors.success
                                  : pct >= 40
                                      ? NexusColors.primary
                                      : NexusColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              // ── Contenido principal ────────────────────────────────────
              final mainContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  alumnoHeader,
                  const SizedBox(height: 20),
                  miniStats,
                  const SizedBox(height: 20),
                  // En desktop: progresoCard + comunicación en la misma fila
                  if (twoCol)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: progresoCard),
                        const SizedBox(width: 16),
                        SizedBox(width: 210, child: _buildComunicacionCard(ctx, practica)),
                      ],
                    )
                  else
                    progresoCard,

                  if (pendientes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                        label: 'PENDIENTE DE VALIDAR',
                        count: pendientes.length,
                        countColor: NexusColors.warning),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: ctx.nxt.surface,
                        border: Border.all(color: ctx.nxt.border, width: NexusSizes.borderWidth),
                        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                      ),
                      child: Column(
                        children: pendientes.asMap().entries.map((e) {
                          return _ParteRow(
                            seguimiento: e.value,
                            isLast: e.key == pendientes.length - 1,
                            onValidar: () => onValidar(e.value.id),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  if (incAbiertasCount > 0) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                        label: 'INCIDENCIAS ABIERTAS',
                        count: incAbiertasCount,
                        countColor: NexusColors.danger),
                    const SizedBox(height: 10),
                    ...incidencias.where((i) => i.estaAbierta).map((inc) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _IncidenciaDetailCard(
                            incidencia: inc,
                            onGestionar: () => onCambiarEstadoIncidencia(inc),
                          ),
                        )),
                  ],

                  if (ausenciasInjustificadas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                        label: 'AUSENCIAS INJUSTIFICADAS',
                        count: ausenciasInjustificadas.length,
                        countColor: NexusColors.danger),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: ctx.nxt.surface,
                        border: Border.all(color: ctx.nxt.border, width: NexusSizes.borderWidth),
                        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                      ),
                      child: Column(
                        children: ausenciasInjustificadas.asMap().entries.map((e) {
                          return _AusenciaInjustificadaRow(
                            ausencia: e.value,
                            isLast: e.key == ausenciasInjustificadas.length - 1,
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // En móvil (una columna), comunicación va al final
                  if (!twoCol) ...[
                    const SizedBox(height: 24),
                    _buildComunicacionCard(ctx, practica),
                  ],
                ],
              );

              return mainContent;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildComunicacionCard(BuildContext context, Practica practica) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comunicación', style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ChatCard(
            icon: Icons.chat_bubble_outline,
            label: 'Chat alumno',
            subtitle: practica.alumnoNombre,
            color: NexusColors.primary,
            bgColor: NexusColors.primaryLight,
            onTap: onChatTap,
          ),
          const SizedBox(height: 8),
          _ChatCard(
            icon: Icons.supervisor_account_outlined,
            label: 'Chat empresa',
            subtitle: practica.empresaNombre,
            color: NexusColors.success,
            bgColor: NexusColors.successLight,
            onTap: onChatTutoresTap,
          ),
        ],
      ),
    );
  }

  String _getInitials(String nombre) {
    final parts =
        nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── All partes panel ───────────────────────────────────────────────────────────

class _AllPartesPanel extends StatelessWidget {
  final TutorCentroProvider provider;
  final void Function(int) onValidar;
  const _AllPartesPanel({required this.provider, required this.onValidar});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: NexusColors.primary));
    }
    final pendientes = provider.todosPendientesCentro;
    if (pendientes.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline,
        mensaje: 'Sin partes pendientes',
        detalle: 'Todos los partes han sido procesados.',
        iconColor: Color.fromRGBO(59, 109, 17, 0.5),
      );
    }
    final incAbiertas = provider.todasIncidencias.where((i) => i.estaAbierta).length;
    final totalAlumnos = provider.practicas.length;
    final ultimo = pendientes.isNotEmpty ? pendientes.first : null;
    final ultimoPractica = ultimo != null ? provider.practicaDe(ultimo.practicaId) : null;

    return RefreshIndicator(
      onRefresh: () => context.read<TutorCentroProvider>().cargar(),
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
                      Text('Validación de Partes',
                              style: NexusText.heading2.copyWith(letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(
                            'Tienes ${pendientes.length} ${pendientes.length == 1 ? 'parte pendiente' : 'partes pendientes'} de validación hoy.',
                            style: NexusText.body.copyWith(color: context.nxt.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NexusSizes.space2XL),
                // Tabla
                Container(
                  decoration: BoxDecoration(
                    color: context.nxt.surface,
                    border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                    borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(builder: (ctx, cst) {
                        final isMobile = cst.maxWidth < 600;
                        return Container(
                          decoration: BoxDecoration(
                            color: context.nxt.surfaceAlt,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(NexusSizes.radiusLG - 1)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: NexusSizes.space2XL, vertical: 10),
                          child: Row(
                            children: [
                              const _ColH('Alumno', flex: 3),
                              if (!isMobile) const _ColH('Empresa', flex: 3),
                              const _ColH('Fecha', flex: 2),
                              const _ColH('Horas', flex: 2),
                              if (!isMobile) const _ColH('Descripción', flex: 3),
                              _ColH('Acción', flex: isMobile ? 2 : 2),
                            ],
                          ),
                        );
                      }),
                      Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),
                      ...pendientes.map((s) {
                        final p = provider.practicaDe(s.practicaId);
                        return _ParteTableRow(
                          seguimiento: s,
                          alumnoNombre: p?.alumnoNombre ?? 'Alumno',
                          alumnoId: p?.alumnoId ?? 0,
                          empresaNombre: p?.empresaNombre ?? '',
                          onValidar: () => onValidar(s.id),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            NexusSizes.space2XL, NexusSizes.spaceMD,
                            NexusSizes.space2XL, NexusSizes.spaceMD),
                        child: Text(
                          'Mostrando ${pendientes.length} ${pendientes.length == 1 ? 'registro' : 'registros'}',
                          style: NexusText.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Bottom row: Detalle + Resumen Semanal
                LayoutBuilder(builder: (ctx, cst) {
                  final wide = cst.maxWidth > 600;
                  final detalle = ultimo == null
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.nxt.surface,
                            border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                            borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                          ),
                          child: Text('Sin actividad reciente',
                              style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
                        )
                      : Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.nxt.surface,
                            border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                            borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: NexusColors.warningLight,
                                      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                                    ),
                                    child: Text('Pendiente validación',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: NexusColors.warningText)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Detalle de Última Actividad',
                                  style: NexusText.small.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                ultimo.descripcion?.isNotEmpty == true ? ultimo.descripcion! : 'Sin descripción.',
                                style: NexusText.body.copyWith(color: context.nxt.inkSecondary),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 13, color: context.nxt.inkTertiary),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      ultimo.esSemanal
                                          ? 'Sem. ${DateFormat('d MMM', 'es_ES').format(ultimo.fechaRegistro)} - ${DateFormat('d MMM', 'es_ES').format(ultimo.fechaRegistro.add(const Duration(days: 4)))}'
                                          : DateFormat('d MMM yyyy', 'es_ES').format(ultimo.fechaRegistro),
                                      style: NexusText.caption,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.access_time, size: 13, color: context.nxt.inkTertiary),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text('${fmtH(ultimo.horasRealizadas)}h',
                                        style: NexusText.caption, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (ultimoPractica != null) ...[
                                    const SizedBox(width: 10),
                                    Icon(Icons.person_outline, size: 13, color: context.nxt.inkTertiary),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(ultimoPractica.alumnoNombre,
                                          style: NexusText.caption, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );

                  final resumen = Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.nxt.surface,
                      border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen',
                            style: NexusText.small.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        _ResumenItem(
                          icon: Icons.pending_actions_outlined,
                          color: NexusColors.warning,
                          label: 'Partes pendientes',
                          value: '${pendientes.length}',
                        ),
                        const SizedBox(height: 12),
                        _ResumenItem(
                          icon: Icons.people_outline,
                          color: NexusColors.primary,
                          label: 'Total alumnos',
                          value: '$totalAlumnos',
                        ),
                        const SizedBox(height: 12),
                        _ResumenItem(
                          icon: Icons.warning_amber_outlined,
                          color: NexusColors.danger,
                          label: 'Incidencias abiertas',
                          value: '$incAbiertas',
                        ),
                      ],
                    ),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: detalle),
                        const SizedBox(width: 16),
                        SizedBox(width: 220, child: resumen),
                      ],
                    );
                  }
                  return Column(children: [detalle, const SizedBox(height: 16), resumen]);
                }),
              ],
            ),
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _ResumenItem({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: NexusText.caption.copyWith(color: context.nxt.inkSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: context.nxt.ink)),
      ],
    );
  }
}

// ── All incidencias panel ──────────────────────────────────────────────────────

class _AllIncidenciasPanel extends StatefulWidget {
  final TutorCentroProvider provider;
  final void Function(Incidencia) onCambiarEstado;
  const _AllIncidenciasPanel(
      {required this.provider, required this.onCambiarEstado});

  @override
  State<_AllIncidenciasPanel> createState() => _AllIncidenciasPanelState();
}

class _AllIncidenciasPanelState extends State<_AllIncidenciasPanel> {
  int _tab = 0; // 0=Todas, 1=Pendientes, 2=Resueltas, 3=Cerradas

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: NexusColors.primary));
    }
    final todas = provider.todasIncidencias;
    final pendientes = todas.where((i) => i.estado == 'ABIERTA' || i.estado == 'EN_PROCESO').toList();
    final resueltas = todas.where((i) => i.estado == 'RESUELTA').toList();
    final cerradas = todas.where((i) => i.estado == 'CERRADA').toList();

    final filtered = switch (_tab) {
      1 => pendientes,
      2 => resueltas,
      3 => cerradas,
      _ => todas,
    };

    final abiertas = todas.where((i) => i.estado == 'ABIERTA').length;
    final enProceso = todas.where((i) => i.estado == 'EN_PROCESO').length;

    return RefreshIndicator(
      onRefresh: () => context.read<TutorCentroProvider>().cargar(),
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
                      Text('Gestión de Incidencias',
                              style: NexusText.heading2.copyWith(letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(
                            'Monitoriza y resuelve las incidencias reportadas.',
                            style: NexusText.body.copyWith(color: context.nxt.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stat cards (responsive)
                LayoutBuilder(builder: (ctx, cst) {
                  if (cst.maxWidth < 480) {
                    return Row(
                      children: [
                        Expanded(child: _IncStatCard(valor: '$abiertas', label: 'ABIERTAS', color: NexusColors.danger, icon: Icons.warning_amber_outlined)),
                        const SizedBox(width: 6),
                        Expanded(child: _IncStatCard(valor: '$enProceso', label: 'EN PROCESO', color: NexusColors.primary, icon: Icons.sync_outlined)),
                        const SizedBox(width: 6),
                        Expanded(child: _IncStatCard(valor: '${resueltas.length}', label: 'RESUELTAS', color: NexusColors.success, icon: Icons.check_circle_outline_rounded)),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _IncStatCard(valor: '$abiertas', label: 'INCIDENCIAS ABIERTAS', color: NexusColors.danger, icon: Icons.warning_amber_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _IncStatCard(valor: '$enProceso', label: 'EN PROCESO', color: NexusColors.primary, icon: Icons.sync_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _IncStatCard(valor: '${resueltas.length}', label: 'RESUELTAS', color: NexusColors.success, icon: Icons.check_circle_outline_rounded)),
                    ],
                  );
                }),
                const SizedBox(height: NexusSizes.space2XL),
                Container(
                  decoration: BoxDecoration(
                    color: context.nxt.surface,
                    border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                    borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: context.nxt.border,
                                  width: NexusSizes.borderWidth)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: NexusSizes.space2XL),
                          child: Row(
                            children: [
                              _IncTab('Todas', todas.length, 0, _tab, (i) => setState(() => _tab = i)),
                              _IncTab('Pendientes', pendientes.length, 1, _tab,
                                  (i) => setState(() => _tab = i),
                                  accent: NexusColors.danger),
                              _IncTab('Resueltas', resueltas.length, 2, _tab,
                                  (i) => setState(() => _tab = i)),
                              _IncTab('Cerradas', cerradas.length, 3, _tab,
                                  (i) => setState(() => _tab = i)),
                            ],
                          ),
                        ),
                      ),
                      // Table header — responsive: oculta columna Tipo en móvil
                      LayoutBuilder(builder: (ctx, cst) {
                        final isMobile = cst.maxWidth < 600;
                        return Container(
                          color: context.nxt.surfaceAlt,
                          padding: const EdgeInsets.symmetric(
                              horizontal: NexusSizes.space2XL, vertical: 10),
                          child: Row(
                            children: [
                              const _ColH('Alumno / Incidencia', flex: 4),
                              if (!isMobile) const _ColH('Tipo', flex: 2),
                              const _ColH('Estado', flex: 2),
                              const _ColH('Fecha', flex: 2),
                              const _ColH('Acción', flex: 2),
                            ],
                          ),
                        );
                      }),
                      Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: NexusSizes.space3XL),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.shield_outlined,
                                    size: 32, color: context.nxt.inkTertiary),
                                const SizedBox(height: NexusSizes.spaceMD),
                                Text('Sin incidencias en este filtro',
                                    style: NexusText.small
                                        .copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filtered.map((inc) {
                          final practica = provider.practicaDe(inc.practicaId);
                          return _IncidenciaTableRow(
                            incidencia: inc,
                            alumnoId: practica?.alumnoId ?? 0,
                            alumnoNombre: practica?.alumnoNombre ?? 'Alumno',
                            onGestionar: inc.estado == 'CERRADA'
                                ? null
                                : () => widget.onCambiarEstado(inc),
                          );
                        }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            NexusSizes.space2XL, NexusSizes.spaceMD,
                            NexusSizes.space2XL, NexusSizes.spaceMD),
                        child: Text('${filtered.length} registros',
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
}

// ── Stat card de incidencias ──────────────────────────────────────────────────

class _IncStatCard extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;
  final IconData icon;
  const _IncStatCard({required this.valor, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.3)),
                Text(label,
                    style: NexusText.caption.copyWith(
                        color: context.nxt.inkSecondary, letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab de incidencias ────────────────────────────────────────────────────────

class _IncTab extends StatelessWidget {
  final String label;
  final int count;
  final int index;
  final int current;
  final void Function(int) onTap;
  final Color? accent;

  const _IncTab(this.label, this.count, this.index, this.current, this.onTap,
      {this.accent});

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final color = isSelected
        ? (accent ?? NexusColors.primary)
        : context.nxt.inkTertiary;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: isSelected ? (accent ?? NexusColors.primary) : Colors.transparent,
                  width: 2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (accent ?? NexusColors.primary).withAlpha(20)
                      : context.nxt.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Fila de tabla de incidencia ───────────────────────────────────────────────

class _IncidenciaTableRow extends StatelessWidget {
  final Incidencia incidencia;
  final int alumnoId;
  final String alumnoNombre;
  final VoidCallback? onGestionar;

  const _IncidenciaTableRow({
    required this.incidencia,
    required this.alumnoId,
    required this.alumnoNombre,
    this.onGestionar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fecha = DateFormat('d MMM', 'es_ES').format(incidencia.fechaCreacion);

    Color estadoBg, estadoFg;
    String estadoLabel;
    switch (incidencia.estado) {
      case 'ABIERTA':
        estadoBg = isDark ? const Color(0xFF4A1515) : NexusColors.dangerLight;
        estadoFg = isDark ? const Color(0xFFFF8A80) : NexusColors.dangerText;
        estadoLabel = 'Abierta';
      case 'EN_PROCESO':
        estadoBg = isDark ? const Color(0xFF0D2B4F) : NexusColors.primaryLight;
        estadoFg = isDark ? const Color(0xFF7AB5F5) : NexusColors.primaryText;
        estadoLabel = 'En proceso';
      case 'RESUELTA':
        estadoBg = isDark ? const Color(0xFF1E3D10) : NexusColors.successLight;
        estadoFg = isDark ? const Color(0xFF86C962) : NexusColors.successText;
        estadoLabel = 'Resuelta';
      default:
        estadoBg = isDark ? const Color(0xFF252B3D) : NexusColors.neutralLight;
        estadoFg = isDark ? const Color(0xFFA4AABC) : NexusColors.neutralText;
        estadoLabel = 'Cerrada';
    }

    final tipoBg = isDark ? const Color(0xFF1A2440) : const Color(0xFFEEF2FF);
    final tipoFg = isDark ? const Color(0xFF93A8F4) : const Color(0xFF3F52C7);
    final tipoLabel = incidencia.tipo ?? 'General';

    return LayoutBuilder(builder: (ctx, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return Container(
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: NexusSizes.space2XL, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  NexusAvatar(userId: alumnoId, nombre: alumnoNombre, radius: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alumnoNombre,
                            style: NexusText.small
                                .copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                        Text(incidencia.descripcion,
                            style: NexusText.caption
                                .copyWith(color: context.nxt.inkSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tipoBg,
                      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                    ),
                    child: Text(tipoLabel,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: tipoFg),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                  ),
                  child: Text(estadoLabel,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: estadoFg),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(fecha,
                  style: NexusText.small.copyWith(color: context.nxt.inkSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ),
            Expanded(
              flex: 2,
              child: onGestionar != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: onGestionar,
                        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: NexusColors.dangerLight,
                            borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isMobile ? 'Ver' : 'Gestionar',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NexusColors.dangerText, fontFamily: 'Inter'),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 11, color: NexusColors.dangerText),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }
}

// ── Fila de tabla de partes (para validación) ─────────────────────────────────

class _ParteTableRow extends StatelessWidget {
  final Seguimiento seguimiento;
  final String alumnoNombre;
  final int alumnoId;
  final String empresaNombre;
  final VoidCallback onValidar;

  const _ParteTableRow({
    required this.seguimiento,
    required this.alumnoNombre,
    required this.alumnoId,
    required this.empresaNombre,
    required this.onValidar,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = seguimiento.esSemanal
        ? 'Sem. ${DateFormat('d MMM', 'es_ES').format(seguimiento.fechaRegistro)} - ${DateFormat('d MMM', 'es_ES').format(seguimiento.fechaRegistro.add(const Duration(days: 4)))}'
        : DateFormat('d MMM', 'es_ES').format(seguimiento.fechaRegistro);

    return LayoutBuilder(builder: (ctx, constraints) {
      final isMobile = constraints.maxWidth < 600;
      final horasChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: NexusColors.primaryLight,
          borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
        ),
        child: Text(
          fmtH(seguimiento.horasRealizadas),
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NexusColors.primaryText),
          textAlign: TextAlign.center,
        ),
      );
      final validarBtn = isMobile
          ? IconButton(
              onPressed: onValidar,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              color: NexusColors.success,
              tooltip: 'Validar',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            )
          : InkWell(
              onTap: onValidar,
              borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: NexusColors.successLight,
                  borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 12, color: NexusColors.successText),
                    SizedBox(width: 4),
                    Text('Validar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NexusColors.successText, fontFamily: 'Inter')),
                  ],
                ),
              ),
            );

      return Container(
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: NexusSizes.space2XL, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  NexusAvatar(userId: alumnoId, nombre: alumnoNombre, radius: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(alumnoNombre,
                        style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              Expanded(
                flex: 3,
                child: Text(empresaNombre,
                    style: NexusText.small.copyWith(color: context.nxt.inkSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
            Expanded(
              flex: 2,
              child: Text(fecha, style: NexusText.small, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: horasChip)),
            if (!isMobile)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    seguimiento.descripcion?.isNotEmpty == true
                        ? seguimiento.descripcion!
                        : '—',
                    style: NexusText.small.copyWith(color: context.nxt.inkSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: validarBtn)),
          ],
        ),
      );
    });
  }
}

// ── Column header helper ──────────────────────────────────────────────────────

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

// ── Parte row inline (en detail panel) ────────────────────────────────────────

class _ParteRow extends StatelessWidget {
  final Seguimiento seguimiento;
  final bool isLast;
  final VoidCallback onValidar;

  const _ParteRow({
    required this.seguimiento,
    required this.isLast,
    required this.onValidar,
  });

  @override
  Widget build(BuildContext context) {
    final fecha =
        DateFormat('d/MM', 'es_ES').format(seguimiento.fechaRegistro);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: context.nxt.border,
                    width: NexusSizes.borderWidth)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: NexusColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seguimiento.descripcion ?? 'Parte de seguimiento',
                  style: NexusText.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$fecha · ${fmtH(seguimiento.horasRealizadas)} · Validado por empresa',
                  style: NexusText.caption.copyWith(
                      color: context.nxt.inkSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onValidar,
            borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: NexusColors.successLight,
                borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 12, color: NexusColors.successText),
                  SizedBox(width: 4),
                  Text('Validar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NexusColors.successText, fontFamily: 'Inter')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Incidencia card en detalle ─────────────────────────────────────────────────

class _IncidenciaDetailCard extends StatelessWidget {
  final Incidencia incidencia;
  final VoidCallback onGestionar;
  const _IncidenciaDetailCard(
      {required this.incidencia, required this.onGestionar});

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d MMM', 'es_ES').format(incidencia.fechaCreacion);
    return InkWell(
      onTap: onGestionar,
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.nxt.surface,
          border: Border(
            left: const BorderSide(color: NexusColors.danger, width: 3),
            top: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth),
            right: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth),
            bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth),
          ),
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: NexusColors.dangerLight,
                borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
              ),
              child: const Icon(Icons.warning_amber_rounded, size: 14, color: NexusColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incidencia.descripcion,
                    style: NexusText.small.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reportada $fecha · ${_labelEstado(incidencia.estado)}',
                    style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: NexusColors.dangerLight,
                borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Gestionar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: NexusColors.danger,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 11, color: NexusColors.danger),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelEstado(String e) {
    switch (e) {
      case 'ABIERTA': return 'Sin resolver';
      case 'EN_PROCESO': return 'En proceso';
      case 'RESUELTA': return 'Resuelta';
      case 'CERRADA': return 'Cerrada';
      default: return e;
    }
  }
}

// ── Mobile bottom nav ──────────────────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChangeMode;
  final int pendientePartes;
  final int pendienteIncidencias;

  const _MobileBottomNav({
    required this.mode,
    required this.onChangeMode,
    required this.pendientePartes,
    required this.pendienteIncidencias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(
            top: BorderSide(
                color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      child: Row(
        children: [
          _BottomItem(
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            label: 'Alumnos',
            isActive: mode == _Mode.alumnos,
            onTap: () => onChangeMode(_Mode.alumnos),
          ),
          _BottomItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Partes',
            badge: pendientePartes,
            isActive: mode == _Mode.partes,
            onTap: () => onChangeMode(_Mode.partes),
          ),
          _BottomItem(
            icon: Icons.warning_amber_outlined,
            activeIcon: Icons.warning_amber,
            label: 'Alertas',
            badge: pendienteIncidencias,
            isActive: mode == _Mode.incidencias,
            onTap: () => onChangeMode(_Mode.incidencias),
          ),
          _BottomItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chat',
            isActive: mode == _Mode.chat,
            onTap: () => onChangeMode(_Mode.chat),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  const _BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 22,
                    color: isActive ? NexusColors.primary : context.nxt.inkTertiary,
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -3,
                      right: -5,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: NexusColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.nxt.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: isActive ? NexusColors.primary : context.nxt.inkTertiary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chat dual pane ─────────────────────────────────────────────────────────────

class _ChatDualPane extends StatelessWidget {
  final int? practicaId;
  final String canalActivo;
  final ValueChanged<String> onCanalChanged;
  final String alumnoNombre;
  final String empresaNombre;

  const _ChatDualPane({
    required this.practicaId,
    required this.canalActivo,
    required this.onCanalChanged,
    required this.alumnoNombre,
    required this.empresaNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Canal switcher
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: context.nxt.surface,
            border: Border(
              bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth),
            ),
          ),
          child: Row(
            children: [
              _CanalTab(
                label: 'Con alumno',
                icon: Icons.chat_bubble_outline,
                activo: canalActivo == 'ALUMNO',
                accentColor: NexusColors.primary,
                onTap: () => onCanalChanged('ALUMNO'),
              ),
              _CanalTab(
                label: 'Con empresa',
                icon: Icons.supervisor_account_outlined,
                activo: canalActivo == 'TUTORES',
                accentColor: NexusColors.success,
                onTap: () => onCanalChanged('TUTORES'),
              ),
            ],
          ),
        ),
        // Chat activo
        Expanded(
          child: IndexedStack(
            index: canalActivo == 'ALUMNO' ? 0 : 1,
            children: [
              ChatPlaceholderScreen(
                key: ValueKey('alumno-$practicaId'),
                practicaId: practicaId,
                canal: 'ALUMNO',
              ),
              ChatPlaceholderScreen(
                key: ValueKey('tutores-$practicaId'),
                practicaId: practicaId,
                canal: 'TUTORES',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CanalTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool activo;
  final Color accentColor;
  final VoidCallback onTap;

  const _CanalTab({
    required this.label,
    required this.icon,
    required this.activo,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: activo ? accentColor.withAlpha(18) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: activo ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14,
                  color: activo ? accentColor : context.nxt.inkTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: NexusText.small.copyWith(
                  color: activo ? accentColor : context.nxt.inkTertiary,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile header ──────────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  final AuthProvider auth;
  const _MobileHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(
            bottom: BorderSide(
                color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: NexusColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.star_outline,
                size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Tutor Centro',
                  style: NexusText.small
                      .copyWith(fontWeight: FontWeight.w600))),
          Builder(builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20, color: context.nxt.inkSecondary),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () => ctx.read<ThemeProvider>().toggle(),
            );
          }),
          IconButton(
            icon: Icon(Icons.logout_outlined,
                size: 20, color: context.nxt.inkSecondary),
            tooltip: 'Cerrar sesión',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int? count;
  final Color? countColor;

  const _SectionLabel({required this.label, this.count, this.countColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: NexusText.label.copyWith(
                color: context.nxt.inkTertiary, letterSpacing: 1.0)),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: countColor?.withAlpha(26) ?? NexusColors.border,
              borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: countColor ?? context.nxt.inkSecondary)),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(77), width: 0.5),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color)),
    );
  }
}

class _SelectPrompt extends StatelessWidget {
  const _SelectPrompt();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TutorCentroProvider>();
    final activos = provider.practicas.where((p) => p.estado == 'ACTIVA').length;
    final pendPartes = provider.todosPendientesCentro.length;
    final incAbiertas = provider.todasIncidencias.where((i) => i.estaAbierta).length;
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.nombreCompleto.split(' ').first ?? 'Tutor';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Text('Hola, $firstName 👋',
              style: NexusText.heading2.copyWith(letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text('Resumen de hoy · ${_fmtHoy()}',
              style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
          const SizedBox(height: 24),

          // Mini stat cards — responsive: Row en desktop, Column en móvil
          LayoutBuilder(builder: (ctx, cst) {
            final miniStats = [
              _MiniStat(
                  valor: '$activos',
                  label: 'Alumnos activos',
                  color: NexusColors.success,
                  icon: Icons.people_outline),
              _MiniStat(
                  valor: '$pendPartes',
                  label: 'Partes por validar',
                  color: NexusColors.warning,
                  icon: Icons.pending_actions_outlined),
              _MiniStat(
                  valor: '$incAbiertas',
                  label: 'Incidencias abiertas',
                  color: NexusColors.danger,
                  icon: Icons.warning_amber_outlined),
            ];
            if (cst.maxWidth < 600) {
              return Column(
                children: [
                  miniStats[0],
                  const SizedBox(height: 10),
                  miniStats[1],
                  const SizedBox(height: 10),
                  miniStats[2],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: miniStats[0]),
                const SizedBox(width: 12),
                Expanded(child: miniStats[1]),
                const SizedBox(width: 12),
                Expanded(child: miniStats[2]),
              ],
            );
          }),
          const SizedBox(height: 32),

          // Prompt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NexusColors.primary.withAlpha(8),
              border: Border.all(color: NexusColors.primary.withAlpha(40)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NexusColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.touch_app_outlined,
                      size: 22, color: NexusColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selecciona un alumno',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 3),
                      Text('Elige un alumno de la lista para ver su seguimiento, validar partes y gestionar incidencias.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: NexusColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.valor, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(valor,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
              maxLines: 2),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: NexusColors.danger),
          const SizedBox(height: NexusSizes.spaceLG),
          Text(message, style: NexusText.body),
          const SizedBox(height: NexusSizes.spaceLG),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// ── Ausencia injustificada row ─────────────────────────────────────────────────

class _AusenciaInjustificadaRow extends StatelessWidget {
  final Ausencia ausencia;
  final bool isLast;

  const _AusenciaInjustificadaRow({
    required this.ausencia,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d/MM/yyyy', 'es_ES').format(ausencia.fecha);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: context.nxt.border,
                    width: NexusSizes.borderWidth)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: NexusColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ausencia.motivo,
                  style: NexusText.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$fecha · Revisada por ${ausencia.revisadaPorNombre ?? 'tutor empresa'}',
                  style: NexusText.caption.copyWith(
                      color: context.nxt.inkSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _ChatCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: color.withAlpha(40)),
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: NexusText.small.copyWith(
                          fontWeight: FontWeight.w600, color: color)),
                  Text(subtitle,
                      style: NexusText.caption
                          .copyWith(color: color.withAlpha(160)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: color.withAlpha(130)),
          ],
        ),
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MiniStatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  final String detalle;
  final Color? iconColor;

  const _EmptyState({
    required this.icon,
    required this.mensaje,
    required this.detalle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NexusSizes.space3XL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 64,
                color: iconColor ??
                    Color.fromRGBO(24, 95, 165, 0.4)),
            const SizedBox(height: NexusSizes.spaceLG),
            Text(mensaje, style: NexusText.heading2),
            const SizedBox(height: NexusSizes.spaceSM),
            Text(detalle,
                style: NexusText.body
                    .copyWith(color: context.nxt.inkSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _fmtHoy() {
  final now = DateTime.now();
  const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${now.day} ${meses[now.month - 1]}. ${now.year}';
}

