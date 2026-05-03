import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/ausencia_model.dart';
import '../providers/auth_provider.dart';
import '../providers/practica_provider.dart';
import '../widgets/seguimiento_tile.dart';
import '../widgets/incidencia_tile.dart';
import '../widgets/ausencia_tile.dart';
import 'seguimiento_screen.dart';
import 'seguimientos_screen.dart';
import 'incidencias_screen.dart';
import 'ausencias_screen.dart';
import 'chat_placeholder_screen.dart';

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
      // Usamos /me: el JWT identifica al alumno, no necesitamos pasar el ID
      Provider.of<PracticaProvider>(context, listen: false).cargarDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final practica = Provider.of<PracticaProvider>(context);

    return Scaffold(
      backgroundColor: NexusColors.surfaceAlt,
      appBar: _buildAppBar(auth),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final content = IndexedStack(
            index: _navIndex,
            children: [
              _InicioTab(
                auth: auth,
                practica: practica,
                onVerTodosSeguimientos: () => setState(() => _navIndex = 1),
                onReportarIncidencia: () => setState(() => _navIndex = 2),
                onVerAusencias: () => setState(() => _navIndex = 3),
              ),
              const SeguimientosScreen(),
              const IncidenciasScreen(),
              const AusenciasScreen(),
              const ChatPlaceholderScreen(),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                _NexusRail(
                  selectedIndex: _navIndex,
                  onDestinationSelected: (i) => setState(() => _navIndex = i),
                ),
                const VerticalDivider(width: 1, thickness: 0.5, color: NexusColors.border),
                Expanded(child: content),
              ],
            );
          }
          return content;
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

  PreferredSizeWidget _buildAppBar(AuthProvider auth) {
    final initials = _getInitials(auth.user?.nombreCompleto ?? '');
    return AppBar(
      backgroundColor: NexusColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('Nexus', style: NexusText.heading3),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, thickness: 0.5, color: NexusColors.border),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: NexusSizes.spaceSM),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: NexusColors.primaryLight,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NexusColors.primaryText,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, size: 20, color: NexusColors.inkSecondary),
          tooltip: 'Cerrar sesión',
          onPressed: () => auth.logout(),
        ),
        const SizedBox(width: NexusSizes.spaceXS),
      ],
    );
  }

  String _getInitials(String nombre) {
    final parts = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// Tab de inicio del dashboard

class _InicioTab extends StatelessWidget {
  final AuthProvider auth;
  final PracticaProvider practica;
  final VoidCallback onVerTodosSeguimientos;
  final VoidCallback onReportarIncidencia;
  final VoidCallback onVerAusencias;

  const _InicioTab({
    required this.auth,
    required this.practica,
    required this.onVerTodosSeguimientos,
    required this.onReportarIncidencia,
    required this.onVerAusencias,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NexusColors.primary,
      onRefresh: () => practica.cargarDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(NexusSizes.space2XL),
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
            else if (practica.practicaActiva != null)
              _PracticaCard(practica: practica.practicaActiva!)
            else
              const _EmptyState(),
            const SizedBox(height: NexusSizes.space2XL),
            _SectionGrid(
              practica: practica.practicaActiva,
              onVerTodosSeguimientos: onVerTodosSeguimientos,
              onReportarIncidencia: onReportarIncidencia,
              onVerAusencias: onVerAusencias,
            ),
            const SizedBox(height: NexusSizes.space2XL),
            if (practica.practicaActiva != null) const _AccionesRapidas(),
          ],
        ),
      ),
    );
  }
}

// Saludo con fecha

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
        Text('Hola, $firstName', style: NexusText.heading2),
        const SizedBox(height: NexusSizes.spaceXS),
        Text(fecha, style: NexusText.caption),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${dias[d.weekday - 1].substring(0, 1).toUpperCase()}${dias[d.weekday - 1].substring(1)}, '
           '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}

// Card de practica activa

class _PracticaCard extends StatelessWidget {
  final Practica practica;
  const _PracticaCard({required this.practica});

  @override
  Widget build(BuildContext context) {
    final horas = practica.horasTotales ?? 0;

    return Container(
      padding: const EdgeInsets.all(NexusSizes.space2XL),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: empresa + estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practica.empresaNombre,
                      style: NexusText.heading3,
                    ),
                    const SizedBox(height: NexusSizes.spaceXS),
                    Text(
                      practica.codigo,
                      style: NexusText.caption,
                    ),
                  ],
                ),
              ),
              _estadoBadge(practica.estado),
            ],
          ),
          const SizedBox(height: NexusSizes.spaceLG),
          const Divider(height: 1, thickness: 0.5, color: NexusColors.border),
          const SizedBox(height: NexusSizes.spaceLG),

          // Tutores
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Tutor centro',
            value: practica.tutorCentroNombre,
          ),
          const SizedBox(height: NexusSizes.spaceSM),
          _InfoRow(
            icon: Icons.business_center_outlined,
            label: 'Tutor empresa',
            value: practica.tutorEmpresaNombre,
          ),

          if (practica.fechaInicio != null) ...[
            const SizedBox(height: NexusSizes.spaceSM),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Periodo',
              value: _formatPeriodo(practica.fechaInicio, practica.fechaFin),
            ),
          ],

          // Barra de progreso de horas (solo seguimientos COMPLETADOS)
          if (horas > 0) ...[
            const SizedBox(height: NexusSizes.spaceLG),
            const Divider(height: 1, thickness: 0.5, color: NexusColors.border),
            const SizedBox(height: NexusSizes.spaceLG),
            Consumer<PracticaProvider>(
              builder: (_, p, __) => _ProgressBar(
                horasRealizadas: p.horasCompletadas,
                horasTotales: horas,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    switch (estado) {
      case 'ACTIVA':
        return nexusEstadoBadge('Activa', bg: NexusColors.primaryLight, textColor: NexusColors.primaryText);
      case 'FINALIZADA':
        return nexusEstadoBadge('Finalizada', bg: NexusColors.successLight, textColor: NexusColors.successText);
      default:
        return nexusEstadoBadge('Borrador', bg: NexusColors.neutralLight, textColor: NexusColors.neutralText);
    }
  }

  String _formatPeriodo(DateTime? inicio, DateTime? fin) {
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    if (inicio == null) return '-';
    if (fin == null) return 'Desde ${fmt(inicio)}';
    return '${fmt(inicio)} - ${fmt(fin)}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: NexusColors.inkTertiary),
        const SizedBox(width: NexusSizes.spaceSM),
        Text('$label  ', style: NexusText.caption),
        Expanded(
          child: Text(
            value,
            style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int horasRealizadas;
  final int horasTotales;
  const _ProgressBar({required this.horasRealizadas, required this.horasTotales});

  @override
  Widget build(BuildContext context) {
    final pct = horasTotales > 0 ? (horasRealizadas / horasTotales).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Horas completadas', style: NexusText.caption),
            Text(
              '$horasRealizadas / $horasTotales h',
              style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: NexusSizes.spaceSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: NexusColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(NexusColors.primary),
          ),
        ),
        const SizedBox(height: NexusSizes.spaceXS),
        Text(
          '${(pct * 100).toStringAsFixed(0)}%  ·  ${horasTotales - horasRealizadas} h restantes',
          style: NexusText.caption,
        ),
      ],
    );
  }
}

// Grid de seguimientos e incidencias

class _SectionGrid extends StatelessWidget {
  final Practica? practica;
  final VoidCallback onVerTodosSeguimientos;
  final VoidCallback onReportarIncidencia;
  final VoidCallback onVerAusencias;

  const _SectionGrid({
    required this.practica,
    required this.onVerTodosSeguimientos,
    required this.onReportarIncidencia,
    required this.onVerAusencias,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SeguimientosCard(practica: practica, onVerTodos: onVerTodosSeguimientos)),
                  const SizedBox(width: NexusSizes.spaceLG),
                  Expanded(child: _IncidenciasCard(practica: practica, onReportar: onReportarIncidencia)),
                ],
              ),
              const SizedBox(height: NexusSizes.spaceLG),
              _AusenciasCard(practica: practica, onVerAusencias: onVerAusencias),
            ],
          );
        }
        return Column(
          children: [
            _SeguimientosCard(practica: practica, onVerTodos: onVerTodosSeguimientos),
            const SizedBox(height: NexusSizes.spaceLG),
            _IncidenciasCard(practica: practica, onReportar: onReportarIncidencia),
            const SizedBox(height: NexusSizes.spaceLG),
            _AusenciasCard(practica: practica, onVerAusencias: onVerAusencias),
          ],
        );
      },
    );
  }
}

class _SeguimientosCard extends StatelessWidget {
  final Practica? practica;
  final VoidCallback onVerTodos;

  const _SeguimientosCard({required this.practica, required this.onVerTodos});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final seguimientos = provider.seguimientos;
        return _SectionCard(
          title: 'Seguimientos',
          icon: Icons.list_alt_outlined,
          action: practica != null ? 'Ver todos' : null,
          onActionTap: onVerTodos,
          child: practica == null
              ? const _SectionEmpty(mensaje: 'Sin practica activa')
              : seguimientos.isEmpty
                  ? const _SectionEmpty(mensaje: 'Sin seguimientos registrados')
                  : _SeguimientosLista(seguimientos: seguimientos.take(3).toList()),
        );
      },
    );
  }
}

class _SeguimientosLista extends StatelessWidget {
  final List<Seguimiento> seguimientos;
  const _SeguimientosLista({required this.seguimientos});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: seguimientos.map((s) => SeguimientoTile(seguimiento: s)).toList(),
    );
  }
}

class _IncidenciasCard extends StatelessWidget {
  final Practica? practica;
  final VoidCallback onReportar;

  const _IncidenciasCard({required this.practica, required this.onReportar});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final incidencias = provider.incidencias;
        return _SectionCard(
          title: 'Incidencias',
          icon: Icons.warning_amber_outlined,
          action: practica != null ? 'Reportar' : null,
          onActionTap: onReportar,
          child: practica == null
              ? const _SectionEmpty(mensaje: 'Sin practica activa')
              : incidencias.isEmpty
                  ? const _SectionEmpty(mensaje: 'Sin incidencias activas')
                  : _IncidenciasLista(incidencias: incidencias.take(3).toList()),
        );
      },
    );
  }
}

class _IncidenciasLista extends StatelessWidget {
  final List<Incidencia> incidencias;
  const _IncidenciasLista({required this.incidencias});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: incidencias.map((i) => IncidenciaTile(incidencia: i)).toList(),
    );
  }
}

class _AusenciasCard extends StatelessWidget {
  final Practica? practica;
  final VoidCallback onVerAusencias;

  const _AusenciasCard({required this.practica, required this.onVerAusencias});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final ausencias = provider.ausencias;
        return _SectionCard(
          title: 'Ausencias',
          icon: Icons.date_range_outlined,
          action: practica != null ? 'Ver todas' : null,
          onActionTap: onVerAusencias,
          child: practica == null
              ? const _SectionEmpty(mensaje: 'Sin practica activa')
              : ausencias.isEmpty
                  ? const _SectionEmpty(mensaje: 'Sin ausencias registradas')
                  : _AusenciasLista(ausencias: ausencias.take(3).toList()),
        );
      },
    );
  }
}

class _AusenciasLista extends StatelessWidget {
  final List<Ausencia> ausencias;
  const _AusenciasLista({required this.ausencias});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ausencias.map((a) => AusenciaTile(ausencia: a)).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onActionTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NexusSizes.spaceLG, NexusSizes.spaceMD, NexusSizes.spaceSM, NexusSizes.spaceMD,
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: NexusColors.inkSecondary),
                const SizedBox(width: NexusSizes.spaceSM),
                Expanded(
                  child: Text(title, style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
                ),
                if (action != null)
                  TextButton(
                    onPressed: onActionTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: NexusSizes.spaceSM, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      action!,
                      style: NexusText.caption.copyWith(color: NexusColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: NexusColors.border),
          child,
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final String mensaje;
  const _SectionEmpty({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexusSizes.space2XL),
      child: Center(
        child: Text(mensaje, style: NexusText.caption),
      ),
    );
  }
}

// Acciones rapidas

class _AccionesRapidas extends StatelessWidget {
  const _AccionesRapidas();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rapidas',
          style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: NexusSizes.spaceMD),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SeguimientoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar seguimiento'),
          ),
        ),
      ],
    );
  }
}

// Estado vacio (sin practica)

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: NexusSizes.space3XL),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, size: 36, color: NexusColors.inkTertiary),
          const SizedBox(height: NexusSizes.spaceMD),
          Text('Sin practica asignada', style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(
            'Contacta con tu tutor del centro para que te asigne una practica.',
            style: NexusText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Tarjeta de error de API

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
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.dangerLight, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: NexusColors.danger),
          const SizedBox(height: NexusSizes.spaceMD),
          Text(
            'No se pudo cargar la práctica',
            style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
          ),
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

// Skeleton de carga

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: NexusColors.primary,
        ),
      ),
    );
  }
}

// NavigationRail para web/tablet

class _NexusRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _NexusRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: NexusColors.surface,
      indicatorColor: NexusColors.primaryLight,
      selectedIconTheme: const IconThemeData(color: NexusColors.primary),
      unselectedIconTheme: const IconThemeData(color: NexusColors.inkSecondary),
      labelType: NavigationRailLabelType.none,
      minWidth: 56,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: Text('Seguimientos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning_amber),
          label: Text('Incidencias'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.date_range_outlined),
          selectedIcon: Icon(Icons.date_range),
          label: Text('Ausencias'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('Chat'),
        ),
      ],
    );
  }
}

// BottomNavigationBar para movil

class _NexusBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NexusBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: NexusColors.surface,
        selectedItemColor: NexusColors.primary,
        unselectedItemColor: NexusColors.inkTertiary,
        selectedLabelStyle: NexusText.caption.copyWith(color: NexusColors.primary),
        unselectedLabelStyle: NexusText.caption,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Seguimientos'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_outlined), activeIcon: Icon(Icons.warning_amber), label: 'Incidencias'),
          BottomNavigationBarItem(icon: Icon(Icons.date_range_outlined), activeIcon: Icon(Icons.date_range), label: 'Ausencias'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
      ),
    );
  }
}
