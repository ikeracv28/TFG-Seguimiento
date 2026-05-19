import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/services/incidencia_service.dart';
import '../providers/practica_provider.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final all = provider.incidencias;
        final abiertas = all.where((i) => i.estaAbierta).toList();
        final resueltas = all.where((i) => !i.estaAbierta).toList();

        final filtered = switch (_tabIndex) {
          1 => abiertas,
          2 => resueltas,
          _ => all,
        };

        return Scaffold(
          backgroundColor: context.nxt.surfaceAlt,
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
                      _PageHeader(onReportar: () => _mostrarDialog(context, provider)),
                      const SizedBox(height: NexusSizes.space2XL),
                      _FilterTabs(
                        selectedIndex: _tabIndex,
                        counts: [all.length, abiertas.length, resueltas.length],
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                      const SizedBox(height: NexusSizes.spaceLG),
                      _IncidenciasList(incidencias: filtered),
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

  void _mostrarDialog(BuildContext context, PracticaProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _ReportarIncidenciaDialog(onReportado: provider.cargarDashboard),
    );
  }
}

// ─── Cabecera ─────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final VoidCallback onReportar;
  const _PageHeader({required this.onReportar});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro de Incidencias',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.nxt.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text('Gestiona y revisa el estado de tus reportes técnicos.', style: NexusText.caption),
            ],
          ),
        ),
        const SizedBox(width: NexusSizes.spaceLG),
        FilledButton.icon(
          onPressed: onReportar,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Reportar Incidencia'),
          style: FilledButton.styleFrom(
            backgroundColor: NexusColors.danger,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ─── Pestañas filtro ──────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final List<int> counts;
  final ValueChanged<int> onChanged;

  const _FilterTabs({required this.selectedIndex, required this.counts, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Todas', 'Abiertas', 'Resueltas'];
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selectedIndex == i ? NexusColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                ),
                child: Text(
                  '${labels[i]} (${counts[i]})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedIndex == i ? Colors.white : context.nxt.inkSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Lista incidencias ────────────────────────────────────────────────────────

class _IncidenciasList extends StatelessWidget {
  final List<Incidencia> incidencias;
  const _IncidenciasList({required this.incidencias});

  @override
  Widget build(BuildContext context) {
    if (incidencias.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: NexusSizes.space3XL),
        decoration: BoxDecoration(
          color: context.nxt.surface,
          border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
          borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 36, color: context.nxt.inkTertiary),
              const SizedBox(height: NexusSizes.spaceMD),
              Text('Sin incidencias', style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: NexusSizes.spaceXS),
              Text('No hay incidencias en esta categoría.', style: NexusText.caption),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          for (int i = 0; i < incidencias.length; i++) ...[
            _IncidenciaRow(incidencias[i]),
            if (i < incidencias.length - 1)
              Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),
          ],
        ],
      ),
    );
  }
}

class _IncidenciaRow extends StatelessWidget {
  final Incidencia incidencia;
  const _IncidenciaRow(this.incidencia);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color;
    final Color bgColor;
    if (incidencia.estaAbierta) {
      color = isDark ? const Color(0xFFFF8A80) : NexusColors.danger;
      bgColor = isDark ? const Color(0xFF4A1515) : NexusColors.dangerLight;
    } else {
      color = isDark ? const Color(0xFF86C962) : NexusColors.success;
      bgColor = isDark ? const Color(0xFF1E3D10) : NexusColors.successLight;
    }
    final label = incidencia.estaAbierta ? 'Abierta' : 'Resuelta';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NexusSizes.space2XL, vertical: NexusSizes.spaceLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(NexusSizes.radiusSM)),
            child: Icon(
              incidencia.estaAbierta ? Icons.warning_amber_outlined : Icons.check_circle_outline,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: NexusSizes.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (incidencia.tipo != null)
                      Text(
                        '${incidencia.tipo} · ',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500,
                          color: context.nxt.inkTertiary,
                        ),
                      ),
                    Text(_fmtDate(incidencia.fechaCreacion), style: NexusText.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(incidencia.descripcion, style: NexusText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: NexusSizes.spaceMD),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(NexusSizes.radiusFull)),
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${m[d.month - 1]}, ${d.year}';
  }
}

// ─── Dialog reportar incidencia ───────────────────────────────────────────────

class _ReportarIncidenciaDialog extends StatefulWidget {
  final VoidCallback onReportado;
  const _ReportarIncidenciaDialog({required this.onReportado});

  @override
  State<_ReportarIncidenciaDialog> createState() => _ReportarIncidenciaDialogState();
}

class _ReportarIncidenciaDialogState extends State<_ReportarIncidenciaDialog> {
  static const _tipos = ['ACCESO', 'AUSENCIA', 'COMPORTAMIENTO', 'ACCIDENTE', 'OTROS'];
  static const _tiposLabel = {
    'ACCESO': 'Acceso',
    'AUSENCIA': 'Ausencia',
    'COMPORTAMIENTO': 'Comportamiento',
    'ACCIDENTE': 'Accidente',
    'OTROS': 'Otros',
  };

  String _tipoSeleccionado = 'ACCESO';
  final _descripcionController = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerBg = isDark ? const Color(0xFF4A1515) : NexusColors.dangerLight;
    final dangerFg = isDark ? const Color(0xFFFF8A80) : NexusColors.danger;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: dangerBg,
                          borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                        ),
                        child: Icon(Icons.warning_amber_rounded, size: 20, color: dangerFg),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reportar incidencia',
                              style: TextStyle(
                                fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600,
                                color: context.nxt.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Informa de un problema durante tu práctica.', style: NexusText.caption),
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
                      Text(
                        'Categoría',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
                          color: context.nxt.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tipos.map((t) {
                          final selected = t == _tipoSeleccionado;
                          return GestureDetector(
                            onTap: () => setState(() => _tipoSeleccionado = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? NexusColors.danger : context.nxt.surfaceAlt,
                                borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                                border: Border.all(
                                  color: selected ? NexusColors.danger : context.nxt.border,
                                ),
                              ),
                              child: Text(
                                _tiposLabel[t] ?? t,
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
                                  color: selected ? Colors.white : context.nxt.inkSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
                          color: context.nxt.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descripcionController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Describe con detalle lo que ha ocurrido...',
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
                            borderSide: const BorderSide(color: NexusColors.danger, width: 1.5),
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
                            Flexible(
                              child: Text(_error!, style: NexusText.caption.copyWith(color: NexusColors.danger)),
                            ),
                          ],
                        ),
                      ],
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
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _enviando ? null : _enviar,
                        style: FilledButton.styleFrom(
                          backgroundColor: NexusColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: _enviando
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Enviar reporte'),
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

  Future<void> _enviar() async {
    final descripcion = _descripcionController.text.trim();
    if (descripcion.length < 10) {
      setState(() => _error = 'La descripción debe tener al menos 10 caracteres.');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    try {
      await IncidenciaService().reportar(tipo: _tipoSeleccionado, descripcion: descripcion);
      if (mounted) {
        Navigator.pop(context);
        widget.onReportado();
      }
    } catch (e) {
      setState(() { _enviando = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }
}
