import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/empresa_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/audit_log_model.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

enum _ModoAdmin { dashboard, practicas, usuarios, auditoria }

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
          backgroundColor: NexusColors.surfaceAlt,
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
        backgroundColor: NexusColors.surfaceAlt,
        appBar: AppBar(
          backgroundColor: NexusColors.ink,
          elevation: 0,
          title: Text(
            _modoLabel,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout,
                  color: Colors.white54, size: 20),
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
      case _ModoAdmin.auditoria:
        return 'Auditoría';
    }
  }

  Widget _contenidoPorModo() {
    switch (_modo) {
      case _ModoAdmin.dashboard:
        return const _VistaDashboard();
      case _ModoAdmin.practicas:
        return const _VistaPracticas();
      case _ModoAdmin.usuarios:
        return const _VistaUsuarios();
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
    return Container(
      width: 52,
      color: NexusColors.ink,
      child: Column(
        children: [
          const SizedBox(height: NexusSizes.space2XL),
          _IconBtn(
            icon: Icons.dashboard_outlined,
            activo: modoActivo == _ModoAdmin.dashboard,
            tooltip: 'Dashboard',
            onTap: () => onModoChanged(_ModoAdmin.dashboard),
          ),
          const SizedBox(height: NexusSizes.spaceXS),
          _IconBtn(
            icon: Icons.folder_open_outlined,
            activo: modoActivo == _ModoAdmin.practicas,
            tooltip: 'Prácticas',
            onTap: () => onModoChanged(_ModoAdmin.practicas),
          ),
          const SizedBox(height: NexusSizes.spaceXS),
          _IconBtn(
            icon: Icons.people_alt_outlined,
            activo: modoActivo == _ModoAdmin.usuarios,
            tooltip: 'Usuarios',
            onTap: () => onModoChanged(_ModoAdmin.usuarios),
          ),
          const SizedBox(height: NexusSizes.spaceXS),
          _IconBtn(
            icon: Icons.history_outlined,
            activo: modoActivo == _ModoAdmin.auditoria,
            tooltip: 'Auditoría',
            onTap: () => onModoChanged(_ModoAdmin.auditoria),
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.logout,
            tooltip: 'Cerrar sesión',
            onTap: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(height: NexusSizes.spaceLG),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool activo;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 48,
          color: activo ? NexusColors.primary.withOpacity(0.25) : Colors.transparent,
          child: Icon(icon,
              color: activo ? Colors.white : Colors.white70, size: 20),
        ),
      ),
    );
  }
}

// ---- Vista Dashboard ----

class _VistaDashboard extends StatelessWidget {
  const _VistaDashboard();

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
                              .copyWith(color: NexusColors.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stat cards
              Row(
                children: [
                  _DashStatCard(
                      valor: admin.practicasActivas,
                      label: 'Prácticas activas',
                      color: NexusColors.success),
                  const SizedBox(width: 12),
                  _DashStatCard(
                      valor: admin.empresas.length,
                      label: 'Empresas colaboradoras',
                      color: NexusColors.primary),
                  const SizedBox(width: 12),
                  _DashStatCard(
                      valor: admin.incidenciasAbiertas,
                      label: 'Incidencias abiertas',
                      color: NexusColors.danger),
                  const SizedBox(width: 12),
                  _DashStatCard(
                      valor: admin.alumnos.length,
                      label: 'Alumnos registrados',
                      color: NexusColors.warning),
                ],
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
                                practicas: practicasActivas)),
                        const SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: _IncidenciasRecientes(
                                incidencias: incRecientes,
                                admin: admin)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _PracticasEnCurso(practicas: practicasActivas),
                      const SizedBox(height: 16),
                      _IncidenciasRecientes(
                          incidencias: incRecientes, admin: admin),
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
  final Color color;
  const _DashStatCard(
      {required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NexusColors.surface,
          border: Border.all(
              color: NexusColors.border, width: NexusSizes.borderWidth),
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
            Text(
              '$valor',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(label,
                style:
                    NexusText.caption.copyWith(color: NexusColors.inkSecondary),
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _PracticasEnCurso extends StatelessWidget {
  final List<Practica> practicas;
  const _PracticasEnCurso({required this.practicas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
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
            child: Text('PRÁCTICAS EN CURSO',
                style: NexusText.caption.copyWith(
                    color: NexusColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ),
          if (practicas.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No hay prácticas activas.',
                  style: TextStyle(color: NexusColors.inkSecondary)),
            )
          else
            ...practicas.map((p) {
              final initials = p.alumnoNombre
                  .trim()
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join();
              return Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: NexusColors.primaryLight,
                          child: Text(initials,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: NexusColors.primaryText)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.alumnoNombre,
                                  style: NexusText.small.copyWith(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${p.empresaNombre} · ${p.codigo}',
                                style: NexusText.caption.copyWith(
                                    color: NexusColors.inkSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: NexusColors.successLight,
                            borderRadius:
                                BorderRadius.circular(NexusSizes.radiusSM),
                          ),
                          child: Text('Activa',
                              style: NexusText.caption.copyWith(
                                  color: NexusColors.successText,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  if (p != practicas.last)
                    const Divider(height: 1, color: NexusColors.border),
                ],
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
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
        color: NexusColors.surface,
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
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
                    color: NexusColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ),
          if (incidencias.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('Sin incidencias recientes.',
                  style: TextStyle(color: NexusColors.inkSecondary)),
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
                                color: NexusColors.inkSecondary),
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
            color: NexusColors.surface,
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
          // Filtros
          Container(
            color: NexusColors.surface,
            padding: const EdgeInsets.fromLTRB(NexusSizes.space3XL, 0,
                NexusSizes.space3XL, NexusSizes.spaceMD),
            child: Row(
              children: _filtros.map((f) {
                final activo = _filtro == f;
                return Padding(
                  padding:
                      const EdgeInsets.only(right: NexusSizes.spaceSM),
                  child: FilterChip(
                    label: Text(f),
                    selected: activo,
                    onSelected: (_) => setState(() => _filtro = f),
                    selectedColor: NexusColors.primaryLight,
                    labelStyle: TextStyle(
                        color: activo
                            ? NexusColors.primaryText
                            : NexusColors.inkSecondary,
                        fontSize: 12),
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
                          style: const TextStyle(
                              color: NexusColors.inkSecondary),
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
}

class _PracticaCard extends StatelessWidget {
  final Practica practica;
  final bool compacta;

  const _PracticaCard({required this.practica, this.compacta = false});

  Color get _colorEstado {
    switch (practica.estado) {
      case 'ACTIVA':
        return NexusColors.success;
      case 'BORRADOR':
        return NexusColors.warning;
      case 'FINALIZADA':
        return NexusColors.neutral;
      default:
        return NexusColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      padding: const EdgeInsets.all(NexusSizes.spaceLG),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(practica.codigo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: NexusColors.ink)),
                    const SizedBox(width: NexusSizes.spaceSM),
                    _ChipEstado(
                        estado: practica.estado, color: _colorEstado),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Alumno: ${practica.alumnoNombre}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: NexusColors.inkSecondary)),
                if (!compacta) ...[
                  Text('Empresa: ${practica.empresaNombre}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: NexusColors.inkSecondary)),
                  Text(
                      'Tutor centro: ${practica.tutorCentroNombre}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: NexusColors.inkTertiary)),
                ],
              ],
            ),
          ),
          if (practica.horasTotales != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${practica.horasTotales}h',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: NexusColors.primary)),
                const Text('totales',
                    style: TextStyle(
                        fontSize: 11,
                        color: NexusColors.inkTertiary)),
              ],
            ),
          ],
          const SizedBox(width: NexusSizes.spaceXS),
          Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Editar práctica',
            color: NexusColors.inkSecondary,
            onPressed: () => showDialog(
              context: ctx,
              builder: (_) => ChangeNotifierProvider.value(
                value: ctx.read<AdminProvider>(),
                child: _DialogEditarPractica(practica: practica),
              ),
            ),
          )),
        ],
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
            color: fecha != null ? NexusColors.ink : NexusColors.inkTertiary),
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
          color: NexusColors.surface,
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
        return const Center(
          child: Text('No hay usuarios registrados.',
              style: TextStyle(color: NexusColors.inkSecondary)),
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
        color: NexusColors.surface,
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: NexusColors.ink)),
                const SizedBox(height: 2),
                Text(usuario.email,
                    style: const TextStyle(
                        fontSize: 12, color: NexusColors.inkSecondary)),
                Text(usuario.dni,
                    style: const TextStyle(
                        fontSize: 11, color: NexusColors.inkTertiary)),
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
            color: NexusColors.inkSecondary,
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
          color: NexusColors.surface,
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
          color: NexusColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.space3XL, vertical: NexusSizes.spaceSM),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _modulos.map((m) {
                final activo = _moduloSeleccionado == m;
                final color = m == 'TODOS' ? NexusColors.ink : (_coloresModulo[m] ?? NexusColors.ink);
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
                        color: activo ? color : NexusColors.inkSecondary),
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
              return const Center(
                child: Text('No hay registros de auditoría.',
                    style: TextStyle(color: NexusColors.inkSecondary)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              itemCount: admin.auditLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: NexusSizes.spaceXS),
              itemBuilder: (_, i) => _AuditLogTile(
                log: admin.auditLogs[i],
                color: _coloresModulo[admin.auditLogs[i].modulo] ?? NexusColors.ink,
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
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: NexusColors.ink)),
                    if (log.entidadId != null) ...[
                      const SizedBox(width: NexusSizes.spaceXS),
                      Text('#${log.entidadId}',
                          style: const TextStyle(
                              fontSize: 11, color: NexusColors.inkTertiary)),
                    ],
                    const Spacer(),
                    Text(fechaStr,
                        style: const TextStyle(
                            fontSize: 11, color: NexusColors.inkTertiary)),
                  ],
                ),
                if (log.descripcion != null && log.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.descripcion!,
                      style: const TextStyle(
                          fontSize: 12, color: NexusColors.inkSecondary)),
                ],
                if (log.usuarioEmail != null) ...[
                  const SizedBox(height: 2),
                  Text('por ${log.usuarioEmail}',
                      style: const TextStyle(
                          fontSize: 11, color: NexusColors.inkTertiary)),
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
              const Text(
                'La contraseña no se puede editar desde aquí.',
                style: TextStyle(fontSize: 11, color: NexusColors.inkTertiary),
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
      color: NexusColors.ink,
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
                color: isActive ? Colors.white : Colors.white38,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.white38,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
