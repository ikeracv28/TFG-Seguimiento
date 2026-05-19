import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/services/seguimiento_service.dart';
import '../providers/practica_provider.dart';

class SeguimientosScreen extends StatefulWidget {
  const SeguimientosScreen({super.key});

  @override
  State<SeguimientosScreen> createState() => _SeguimientosScreenState();
}

class _SeguimientosScreenState extends State<SeguimientosScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final seguimientos = provider.seguimientos;
        final horasCompletadas = provider.horasCompletadas;
        final horasTotales = provider.practicaActiva?.horasTotales ?? 0;
        final pct = horasTotales > 0
            ? (horasCompletadas / horasTotales * 100).round()
            : 0;

        final now = DateTime.now();
        final horasMes = seguimientos
            .where((s) => s.fechaRegistro.year == now.year && s.fechaRegistro.month == now.month)
            .fold(0.0, (sum, s) => sum + s.horasRealizadas);

        final pendientes = seguimientos
            .where((s) => s.estado == 'PENDIENTE_EMPRESA' || s.estado == 'PENDIENTE_CENTRO')
            .length;

        final filtered = _query.isEmpty
            ? seguimientos
            : seguimientos.where((s) {
                final q = _query.toLowerCase();
                return (s.descripcion ?? '').toLowerCase().contains(q) ||
                    s.estado.toLowerCase().contains(q);
              }).toList();

        return Scaffold(
          backgroundColor: context.nxt.surfaceAlt,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.45),
              builder: (_) => NuevoParteDialog(onGuardado: provider.cargarDashboard),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo parte'),
            backgroundColor: NexusColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: RefreshIndicator(
            color: NexusColors.primary,
            onRefresh: provider.cargarDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PageHeader(),
                      const SizedBox(height: NexusSizes.space2XL),
                      _KpiRow(
                        horasCompletadas: horasCompletadas,
                        horasTotales: horasTotales,
                        pct: pct,
                        horasMes: horasMes,
                        pendientes: pendientes,
                      ),
                      const SizedBox(height: NexusSizes.space2XL),
                      _HistorialCard(
                        seguimientos: filtered,
                        query: _query,
                        searchCtrl: _searchCtrl,
                        onSearch: (v) => setState(() => _query = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Cabecera de página ────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seguimiento de Horas',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.nxt.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text('Visualiza y gestiona tus partes de trabajo diarios.', style: NexusText.caption),
      ],
    );
  }
}

// ─── KPI Cards ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final double horasCompletadas;
  final int horasTotales;
  final int pct;
  final double horasMes;
  final int pendientes;

  const _KpiRow({
    required this.horasCompletadas,
    required this.horasTotales,
    required this.pct,
    required this.horasMes,
    required this.pendientes,
  });

  static String _fmtHDisplay(num h) {
    final d = h.toDouble();
    if (d == d.truncateToDouble()) return '${d.toInt()}h';
    return '${d.truncate()}h 30min';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          _KpiCard(
            label: 'TOTAL ACUMULADO',
            icon: Icons.schedule_outlined,
            iconColor: NexusColors.primary,
            iconBg: NexusColors.primaryLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _fmtHDisplay(horasCompletadas),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: context.nxt.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('/ $horasTotales objetivo', style: NexusText.caption),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: horasTotales > 0
                        ? (horasCompletadas / horasTotales).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 4,
                    backgroundColor: NexusColors.primaryLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(NexusColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$pct% Completado', style: NexusText.caption.copyWith(color: NexusColors.primary)),
                    Text('${_fmtHDisplay(horasTotales - horasCompletadas)} restantes', style: NexusText.caption),
                  ],
                ),
              ],
            ),
          ),
          _KpiCard(
            label: 'ESTE MES',
            icon: Icons.calendar_month_outlined,
            iconColor: NexusColors.success,
            iconBg: NexusColors.successLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _fmtHDisplay(horasMes),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: context.nxt.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Horas registradas este mes.',
                  style: NexusText.caption,
                ),
              ],
            ),
          ),
          _KpiCard(
            label: 'PENDIENTES',
            icon: Icons.error_outline,
            iconColor: NexusColors.danger,
            iconBg: NexusColors.dangerLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pendientes',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: context.nxt.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text('partes por corregir', style: NexusText.caption),
                if (pendientes > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: NexusColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                    ),
                    child: const Text(
                      'Revisión requerida',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: NexusColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ];

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: NexusSizes.spaceLG),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: NexusSizes.spaceMD),
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  const _KpiCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexusSizes.space2XL),
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
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: context.nxt.inkTertiary,
                ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(NexusSizes.radiusMD)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: NexusSizes.spaceMD),
          child,
        ],
      ),
    );
  }
}

// ─── Tabla historial ───────────────────────────────────────────────────────────

class _HistorialCard extends StatelessWidget {
  final List<Seguimiento> seguimientos;
  final String query;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const _HistorialCard({
    required this.seguimientos,
    required this.query,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                NexusSizes.space2XL, NexusSizes.spaceLG, NexusSizes.spaceLG, NexusSizes.spaceLG),
            child: Row(
              children: [
                Text('Historial de Partes',
                    style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: onSearch,
                    style: NexusText.small,
                    decoration: InputDecoration(
                      hintText: 'Buscar partes...',
                      hintStyle: NexusText.caption,
                      prefixIcon: Icon(Icons.search, size: 16, color: context.nxt.inkTertiary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                        borderSide: const BorderSide(color: NexusColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),
          // Cabecera tabla
          Container(
            color: context.nxt.surfaceAlt,
            padding: const EdgeInsets.symmetric(
                horizontal: NexusSizes.space2XL, vertical: 10),
            child: Row(
              children: [
                _TH('Fecha', flex: 2),
                _TH('Horas', flex: 1),
                _TH('Descripción de Tarea', flex: 5),
                _TH('Estado', flex: 2),
              ],
            ),
          ),
          Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

          if (seguimientos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NexusSizes.space3XL),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.list_alt_outlined, size: 32, color: context.nxt.inkTertiary),
                    const SizedBox(height: NexusSizes.spaceMD),
                    Text(
                      query.isEmpty ? 'Aún no has registrado ningún parte' : 'Sin resultados',
                      style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final s in seguimientos) _SeguimientoRow(s),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                NexusSizes.space2XL, NexusSizes.spaceMD, NexusSizes.space2XL, NexusSizes.spaceMD),
            child: Text(
              'Mostrando ${seguimientos.length} registros',
              style: NexusText.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH(this.label, {required this.flex});

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

class _SeguimientoRow extends StatelessWidget {
  final Seguimiento s;
  const _SeguimientoRow(this.s);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.space2XL, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(fmtSeguimientoFecha(s), style: NexusText.small)),
          Expanded(flex: 1, child: Text(s.esSemanal ? '${_fmtH(s.horasRealizadas)}/sem' : _fmtH(s.horasRealizadas), style: NexusText.small)),
          Expanded(
            flex: 5,
            child: Text(
              s.descripcion?.isNotEmpty == true
                  ? s.descripcion!
                  : '${_fmtH(s.horasRealizadas)} de trabajo',
              style: NexusText.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: _EstadoBadge(s.estado)),
        ],
      ),
    );
  }

  static String _fmtH(double h) {
    if (h == h.truncateToDouble()) return '${h.toInt()}h';
    final e = h.truncate();
    return e == 0 ? '30min' : '${e}h 30min';
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
      case 'COMPLETADO':
        fg = isDark ? const Color(0xFF86C962) : NexusColors.successText;
        bg = isDark ? const Color(0xFF1E3D10) : NexusColors.successLight;
        dot = isDark ? const Color(0xFF86C962) : NexusColors.success; label = 'Completado';
      case 'RECHAZADO':
        fg = isDark ? const Color(0xFFFF8A80) : NexusColors.dangerText;
        bg = isDark ? const Color(0xFF4A1515) : NexusColors.dangerLight;
        dot = isDark ? const Color(0xFFFF8A80) : NexusColors.danger; label = 'Rechazado';
      case 'PENDIENTE_EMPRESA':
        fg = isDark ? const Color(0xFFFFB74D) : NexusColors.warningText;
        bg = isDark ? const Color(0xFF3D2A06) : NexusColors.warningLight;
        dot = isDark ? const Color(0xFFFFB74D) : NexusColors.warning; label = 'Pend. Empresa';
      default:
        fg = isDark ? const Color(0xFF7AB5F5) : NexusColors.primaryText;
        bg = isDark ? const Color(0xFF0D2B4F) : NexusColors.primaryLight;
        dot = isDark ? const Color(0xFF7AB5F5) : NexusColors.primary; label = 'Pend. Centro';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NexusSizes.radiusFull)),
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dialog nuevo parte ───────────────────────────────────────────────────────

class NuevoParteDialog extends StatefulWidget {
  final VoidCallback onGuardado;
  const NuevoParteDialog({super.key, required this.onGuardado});

  @override
  State<NuevoParteDialog> createState() => _NuevoParteDialogState();
}

class _NuevoParteDialogState extends State<NuevoParteDialog> {
  String _tipo = 'DIARIO'; // 'DIARIO' o 'SEMANAL'
  DateTime _fecha = DateTime.now();
  double _horas = 8.0;
  // SEMANAL: entrada desglosada
  double _horasDia = 8.0;
  int _diasSemana = 5;
  final _descripcionCtrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: NexusColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fecha = _tipo == 'SEMANAL'
            ? picked.subtract(Duration(days: picked.weekday - 1))
            : picked;
      });
    }
  }

  Future<void> _enviar() async {
    final desc = _descripcionCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = 'La descripción debe tener al menos 10 caracteres.');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    try {
      final provider = context.read<PracticaProvider>();
      final practica = provider.practicaActiva;
      if (practica == null) throw Exception('No tienes una práctica activa.');
      final nuevo = await SeguimientoService().registrar(
        practicaId: practica.id,
        fechaRegistro: _fecha,
        horasRealizadas: _tipo == 'SEMANAL' ? _horasDia * _diasSemana : _horas,
        descripcion: desc,
        tipo: _tipo,
      );
      provider.agregarSeguimiento(nuevo);
      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
      }
    } catch (e) {
      setState(() { _enviando = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  static String _fmtSemana(DateTime lunes) {
    final viernes = lunes.add(const Duration(days: 4));
    const m = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
                'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    if (lunes.month == viernes.month) {
      return '${lunes.day}–${viernes.day} ${m[lunes.month]} ${lunes.year}';
    }
    return '${lunes.day} ${m[lunes.month]}–${viernes.day} ${m[viernes.month]} ${viernes.year}';
  }

  static String _fmtHoras(double h) {
    if (h == h.truncateToDouble()) return '${h.toInt()}h';
    final enteras = h.truncate();
    return enteras == 0 ? '30min' : '${enteras}h 30min';
  }

  static String _fmtFecha(DateTime d) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: context.nxt.surface,
              borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
              border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D2B4F) : NexusColors.primaryLight,
                          borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                        ),
                        child: Icon(Icons.edit_note_rounded, size: 20,
                          color: isDark ? const Color(0xFF7AB5F5) : NexusColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nuevo parte de trabajo',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                                fontWeight: FontWeight.w600, color: context.nxt.ink)),
                            const SizedBox(height: 2),
                            Text('Registra las horas y tareas realizadas.', style: NexusText.caption),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: context.nxt.inkTertiary),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Toggle Diario / Semanal ──────────────────────
                      Row(
                        children: [
                          _TipoChip(
                            label: 'Diario',
                            icon: Icons.today_outlined,
                            active: _tipo == 'DIARIO',
                            onTap: () => setState(() {
                              _tipo = 'DIARIO';
                              _horas = _horas.clamp(0.5, 24.0);
                            }),
                          ),
                          const SizedBox(width: 8),
                          _TipoChip(
                            label: 'Semanal',
                            icon: Icons.date_range_outlined,
                            active: _tipo == 'SEMANAL',
                            onTap: () => setState(() {
                              _tipo = 'SEMANAL';
                              _fecha = _fecha.subtract(Duration(days: _fecha.weekday - 1));
                              if (_horas < 1) _horas = 8.0;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Fecha / Semana + Horas ───────────────────────
                      if (_tipo == 'SEMANAL') ...[
                        // Selector de semana (ancho completo)
                        Text('Semana', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                          fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _seleccionarFecha,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: context.nxt.surfaceAlt,
                              border: Border.all(color: context.nxt.border),
                              borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.date_range_outlined, size: 15, color: context.nxt.inkSecondary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_fmtSemana(_fecha),
                                  style: NexusText.small, overflow: TextOverflow.ellipsis)),
                                Icon(Icons.unfold_more, size: 15, color: context.nxt.inkTertiary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Steppers: horas/día + días + total calculado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Horas por día
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Horas / día', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                                  fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: context.nxt.surfaceAlt,
                                    border: Border.all(color: context.nxt.border),
                                    borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _StepBtn(
                                        icon: Icons.remove,
                                        enabled: _horasDia > 0.5,
                                        onTap: _horasDia > 0.5 ? () => setState(() => _horasDia = (_horasDia - 0.5).clamp(0.5, 12.0)) : null,
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Text(_fmtHoras(_horasDia),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                                            fontWeight: FontWeight.w600, color: context.nxt.ink)),
                                      ),
                                      _StepBtn(
                                        icon: Icons.add,
                                        enabled: _horasDia < 12.0,
                                        onTap: _horasDia < 12.0 ? () => setState(() => _horasDia = (_horasDia + 0.5).clamp(0.5, 12.0)) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Días trabajados
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Días', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                                  fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: context.nxt.surfaceAlt,
                                    border: Border.all(color: context.nxt.border),
                                    borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _StepBtn(
                                        icon: Icons.remove,
                                        enabled: _diasSemana > 1,
                                        onTap: _diasSemana > 1 ? () => setState(() => _diasSemana--) : null,
                                      ),
                                      SizedBox(
                                        width: 36,
                                        child: Text('$_diasSemana',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                                            fontWeight: FontWeight.w600, color: context.nxt.ink)),
                                      ),
                                      _StepBtn(
                                        icon: Icons.add,
                                        enabled: _diasSemana < 5,
                                        onTap: _diasSemana < 5 ? () => setState(() => _diasSemana++) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Total calculado
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total semana', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                                  fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: NexusColors.primaryLight,
                                    borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(_fmtHoras(_horasDia * _diasSemana),
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                                      fontWeight: FontWeight.w700, color: NexusColors.primaryText)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else ...[
                        // DIARIO: fecha + horas en la misma fila
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fecha', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                                    fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _seleccionarFecha,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                      decoration: BoxDecoration(
                                        color: context.nxt.surfaceAlt,
                                        border: Border.all(color: context.nxt.border),
                                        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 15, color: context.nxt.inkSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(_fmtFecha(_fecha),
                                            style: NexusText.small, overflow: TextOverflow.ellipsis)),
                                          Icon(Icons.unfold_more, size: 15, color: context.nxt.inkTertiary),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Horas', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                                  fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: context.nxt.surfaceAlt,
                                    border: Border.all(color: context.nxt.border),
                                    borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _StepBtn(
                                        icon: Icons.remove,
                                        enabled: _horas > 0.5,
                                        onTap: _horas > 0.5 ? () => setState(() => _horas = (_horas - 0.5).clamp(0.5, 24.0)) : null,
                                      ),
                                      SizedBox(
                                        width: 54,
                                        child: Text(_fmtHoras(_horas),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                                            fontWeight: FontWeight.w600, color: context.nxt.ink)),
                                      ),
                                      _StepBtn(
                                        icon: Icons.add,
                                        enabled: _horas < 24.0,
                                        onTap: _horas < 24.0 ? () => setState(() => _horas = (_horas + 0.5).clamp(0.5, 24.0)) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      Text('Descripción de las tareas', style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                        fontWeight: FontWeight.w500, color: context.nxt.inkSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descripcionCtrl,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: 'Describe brevemente las tareas realizadas...',
                          hintStyle: TextStyle(color: context.nxt.inkTertiary, fontSize: 13),
                          filled: true,
                          fillColor: context.nxt.surfaceAlt,
                          counterStyle: TextStyle(color: context.nxt.inkTertiary, fontSize: 11),
                          contentPadding: const EdgeInsets.all(NexusSizes.spaceMD),
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
                        ),
                        style: NexusText.small,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.error_outline, size: 14, color: NexusColors.danger),
                            const SizedBox(width: 6),
                            Flexible(child: Text(_error!,
                              style: NexusText.caption.copyWith(color: NexusColors.danger))),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D2B4F) : NexusColors.primaryLight,
                          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 14,
                              color: isDark ? const Color(0xFF7AB5F5) : NexusColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tipo == 'SEMANAL'
                                    ? 'El parte semanal agrupa todas las horas de la semana. Quedará pendiente de validación por tu tutor de empresa.'
                                    : 'Quedará pendiente de validación por tu tutor de empresa y, después, por tu tutor del centro.',
                                style: NexusText.caption.copyWith(
                                  color: isDark ? const Color(0xFF7AB5F5) : NexusColors.primaryText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

                // ── Footer ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _enviando ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.nxt.inkSecondary,
                          side: BorderSide(color: context.nxt.border),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                            fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _enviando ? null : _enviar,
                        style: FilledButton.styleFrom(
                          backgroundColor: NexusColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                            fontWeight: FontWeight.w500),
                        ),
                        child: _enviando
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Registrar parte'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stepper button ──────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? NexusColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD - 2),
        ),
        child: Icon(icon, size: 18,
          color: enabled ? NexusColors.primary : context.nxt.border),
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TipoChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? NexusColors.primary : context.nxt.surfaceAlt,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
          border: Border.all(
            color: active ? NexusColors.primary : context.nxt.border,
            width: NexusSizes.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : context.nxt.inkSecondary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              fontFamily: 'Inter', fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : context.nxt.inkSecondary,
            )),
          ],
        ),
      ),
    );
  }
}
