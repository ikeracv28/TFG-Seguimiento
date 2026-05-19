import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/services/ausencia_service.dart';
import '../providers/practica_provider.dart';

class AusenciasScreen extends StatelessWidget {
  const AusenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final ausencias = provider.ausencias;
        final justificadas = ausencias.where((a) => a.estaJustificada).length;
        final pendientes = ausencias.where((a) => a.estaPendiente).length;
        final injustificadas =
            ausencias.where((a) => !a.estaPendiente && !a.estaJustificada).length;

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
                      // Cabecera
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Control de Ausencias',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: context.nxt.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Registra y justifica tus ausencias durante las prácticas.',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13, color: context.nxt.inkTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: NexusSizes.space2XL),

                      // KPI cards
                      _KpiRow(
                        justificadas: justificadas,
                        pendientes: pendientes,
                        injustificadas: injustificadas,
                      ),
                      const SizedBox(height: NexusSizes.space2XL),

                      // Contenido principal
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final isWide = constraints.maxWidth > 720;
                          final form = provider.practicaActiva != null
                              ? _RegistrarForm(
                                  practicaId: provider.practicaActiva!.id,
                                  onRegistrada: (a) => provider.agregarAusencia(a),
                                )
                              : const SizedBox.shrink();

                          final tabla = _HistorialTable(
                            ausencias: ausencias,
                            onEliminar: (id) => _confirmarEliminar(ctx, id, provider),
                            onAdjuntar: (id) => _adjuntarJustificante(ctx, id, provider),
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 300, child: form),
                                const SizedBox(width: NexusSizes.spaceLG),
                                Expanded(child: tabla),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              form,
                              const SizedBox(height: NexusSizes.spaceLG),
                              tabla,
                            ],
                          );
                        },
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

  Future<void> _adjuntarJustificante(
      BuildContext context, int ausenciaId, PracticaProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final mime = _mimeType(file.extension ?? '');
    if (!context.mounted) return;
    try {
      final actualizado = await AusenciaService().adjuntarJustificante(
        id: ausenciaId,
        bytes: file.bytes!,
        filename: file.name,
        mimeType: mime,
      );
      provider.actualizarAusencia(actualizado);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Justificante adjuntado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  Future<void> _confirmarEliminar(
      BuildContext context, int ausenciaId, PracticaProvider provider) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar ausencia'),
        content: const Text('Esta ausencia aún no fue revisada. ¿Seguro que quieres eliminarla?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: NexusColors.danger)),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      try {
        await AusenciaService().eliminar(ausenciaId);
        provider.eliminarAusencia(ausenciaId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }
}

// ─── KPI Cards ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int justificadas;
  final int pendientes;
  final int injustificadas;

  const _KpiRow({
    required this.justificadas,
    required this.pendientes,
    required this.injustificadas,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;
        final cards = [
          _KpiCard(
            label: 'JUSTIFICADAS',
            count: justificadas,
            icon: Icons.check_circle_outline,
            iconColor: NexusColors.success,
            iconBg: NexusColors.successLight,
          ),
          _KpiCard(
            label: 'PENDIENTES',
            count: pendientes,
            icon: Icons.hourglass_empty_outlined,
            iconColor: NexusColors.warning,
            iconBg: NexusColors.warningLight,
          ),
          _KpiCard(
            label: 'INJUSTIFICADAS',
            count: injustificadas,
            icon: Icons.warning_amber_outlined,
            iconColor: NexusColors.danger,
            iconBg: NexusColors.dangerLight,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: NexusSizes.spaceMD),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: NexusSizes.spaceSM),
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _KpiCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexusSizes.spaceLG),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: NexusSizes.spaceMD),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: context.nxt.inkTertiary,
                ),
              ),
              Text(
                count.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.nxt.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Formulario registrar ─────────────────────────────────────────────────────

class _RegistrarForm extends StatefulWidget {
  final int practicaId;
  final Function(Ausencia) onRegistrada;

  const _RegistrarForm({required this.practicaId, required this.onRegistrada});

  @override
  State<_RegistrarForm> createState() => _RegistrarFormState();
}

class _RegistrarFormState extends State<_RegistrarForm> {
  DateTime _fechaSeleccionada = DateTime.now();
  final _motivoController = TextEditingController();
  PlatformFile? _ficheroSeleccionado;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

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
          Text('Registrar Ausencia', style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: NexusSizes.spaceLG),

          Text('Fecha de la ausencia', style: NexusText.caption),
          const SizedBox(height: NexusSizes.spaceSM),
          _SelectorFecha(
            fecha: _fechaSeleccionada,
            onCambiada: (d) => setState(() => _fechaSeleccionada = d),
          ),
          const SizedBox(height: NexusSizes.spaceLG),

          Text('Motivo', style: NexusText.caption),
          const SizedBox(height: NexusSizes.spaceSM),
          TextFormField(
            controller: _motivoController,
            maxLines: 3,
            style: NexusText.small,
            decoration: _inputDeco(hint: 'Explica el motivo de la ausencia...'),
          ),
          const SizedBox(height: NexusSizes.spaceLG),

          Text('Justificante (opcional)', style: NexusText.caption),
          const SizedBox(height: NexusSizes.spaceSM),
          _SelectorFichero(
            fichero: _ficheroSeleccionado,
            onSeleccionado: (f) => setState(() => _ficheroSeleccionado = f),
            onEliminado: () => setState(() => _ficheroSeleccionado = null),
          ),

          if (_error != null) ...[
            const SizedBox(height: NexusSizes.spaceMD),
            Text(_error!, style: NexusText.caption.copyWith(color: NexusColors.danger)),
          ],
          const SizedBox(height: NexusSizes.space2XL),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexusColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar Ausencia'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: NexusText.caption,
    filled: true,
    fillColor: context.nxt.surfaceAlt,
    contentPadding: const EdgeInsets.all(NexusSizes.spaceMD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      borderSide: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      borderSide: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      borderSide: const BorderSide(color: NexusColors.warning, width: 1),
    ),
  );

  Future<void> _enviar() async {
    final motivo = _motivoController.text.trim();
    if (_fechaSeleccionada.isAfter(DateTime.now())) {
      setState(() => _error = 'La fecha no puede ser futura.');
      return;
    }
    if (motivo.length < 10) {
      setState(() => _error = 'El motivo debe tener al menos 10 caracteres.');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    try {
      Ausencia ausencia = await AusenciaService().registrar(
        practicaId: widget.practicaId,
        fecha: _fechaSeleccionada,
        motivo: motivo,
      );
      if (_ficheroSeleccionado != null && _ficheroSeleccionado!.bytes != null) {
        final ext = _ficheroSeleccionado!.extension ?? '';
        ausencia = await AusenciaService().adjuntarJustificante(
          id: ausencia.id,
          bytes: _ficheroSeleccionado!.bytes!,
          filename: _ficheroSeleccionado!.name,
          mimeType: _mimeType(ext),
        );
      }
      if (mounted) {
        Navigator.of(context, rootNavigator: false);
        _motivoController.clear();
        setState(() { _fechaSeleccionada = DateTime.now(); _ficheroSeleccionado = null; _enviando = false; });
        widget.onRegistrada(ausencia);
      }
    } catch (e) {
      setState(() { _enviando = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }
}

// ─── Historial tabla ─────────────────────────────────────────────────────────

class _HistorialTable extends StatelessWidget {
  final List<Ausencia> ausencias;
  final Function(int) onEliminar;
  final Function(int) onAdjuntar;

  const _HistorialTable({
    required this.ausencias,
    required this.onEliminar,
    required this.onAdjuntar,
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
            child: Text('Historial de Ausencias',
                style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
          ),
          Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),
          Container(
            color: context.nxt.surfaceAlt,
            padding: const EdgeInsets.symmetric(
                horizontal: NexusSizes.space2XL, vertical: 10),
            child: Row(
              children: [
                _TH('FECHA', flex: 2),
                _TH('MOTIVO', flex: 4),
                _TH('ESTADO', flex: 2),
                _TH('ACCIÓN', flex: 2),
              ],
            ),
          ),
          Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

          if (ausencias.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NexusSizes.space3XL),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, size: 32, color: context.nxt.inkTertiary),
                    const SizedBox(height: NexusSizes.spaceMD),
                    Text('Sin ausencias registradas',
                        style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )
          else
            for (final a in ausencias) _AusenciaRow(
              ausencia: a,
              onEliminar: a.estaPendiente ? () => onEliminar(a.id) : null,
              onAdjuntar: a.estaPendiente && !a.tieneJustificante ? () => onAdjuntar(a.id) : null,
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                NexusSizes.space2XL, NexusSizes.spaceMD, NexusSizes.space2XL, NexusSizes.spaceMD),
            child: Text(
              'Mostrando ${ausencias.length} ausencias',
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: context.nxt.inkTertiary,
        ),
      ),
    );
  }
}

class _AusenciaRow extends StatelessWidget {
  final Ausencia ausencia;
  final VoidCallback? onEliminar;
  final VoidCallback? onAdjuntar;

  const _AusenciaRow({
    required this.ausencia,
    this.onEliminar,
    this.onAdjuntar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color badgeFg;
    Color badgeBg;
    String estadoLabel;
    switch (ausencia.tipo) {
      case 'JUSTIFICADA':
        badgeFg = isDark ? const Color(0xFF86C962) : NexusColors.successText;
        badgeBg = isDark ? const Color(0xFF1E3D10) : NexusColors.successLight;
        estadoLabel = 'Justificada';
      case 'INJUSTIFICADA':
        badgeFg = isDark ? const Color(0xFFFF8A80) : NexusColors.dangerText;
        badgeBg = isDark ? const Color(0xFF4A1515) : NexusColors.dangerLight;
        estadoLabel = 'Injustificada';
      default:
        badgeFg = isDark ? const Color(0xFFFFB74D) : NexusColors.warningText;
        badgeBg = isDark ? const Color(0xFF3D2A06) : NexusColors.warningLight;
        estadoLabel = 'Pendiente';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.space2XL, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_fmtDate(ausencia.fecha), style: NexusText.small)),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ausencia.motivo, style: NexusText.small, overflow: TextOverflow.ellipsis),
                if (ausencia.tieneJustificante)
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 11, color: NexusColors.success),
                      const SizedBox(width: 2),
                      Text(
                        ausencia.nombreFichero ?? 'Justificante adjunto',
                        style: NexusText.caption.copyWith(color: NexusColors.successText, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                ),
                child: Text(
                  estadoLabel,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: badgeFg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (onAdjuntar != null)
                  TextButton(
                    onPressed: onAdjuntar,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Adjuntar',
                        style: NexusText.caption.copyWith(color: NexusColors.primary)),
                  )
                else if (onEliminar != null)
                  TextButton(
                    onPressed: onEliminar,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Eliminar',
                        style: NexusText.caption.copyWith(color: NexusColors.danger)),
                  )
                else
                  Text('—', style: NexusText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const m = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${m[d.month - 1]}, ${d.year}';
  }
}

// ─── Selector de fecha ────────────────────────────────────────────────────────

class _SelectorFecha extends StatelessWidget {
  final DateTime fecha;
  final ValueChanged<DateTime> onCambiada;

  const _SelectorFecha({required this.fecha, required this.onCambiada});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: NexusColors.warning),
            ),
            child: child!,
          ),
        );
        if (picked != null) onCambiada(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(NexusSizes.spaceMD),
        decoration: BoxDecoration(
          color: context.nxt.surfaceAlt,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
          border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: context.nxt.inkSecondary),
            const SizedBox(width: NexusSizes.spaceMD),
            Text(
              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
              style: NexusText.small,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selector de fichero ──────────────────────────────────────────────────────

class _SelectorFichero extends StatelessWidget {
  final PlatformFile? fichero;
  final ValueChanged<PlatformFile> onSeleccionado;
  final VoidCallback onEliminado;

  const _SelectorFichero({
    required this.fichero,
    required this.onSeleccionado,
    required this.onEliminado,
  });

  @override
  Widget build(BuildContext context) {
    if (fichero != null) {
      return Container(
        padding: const EdgeInsets.all(NexusSizes.spaceMD),
        decoration: BoxDecoration(
          color: NexusColors.successLight,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
          border: Border.all(color: NexusColors.success, width: NexusSizes.borderWidth),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file, size: 16, color: NexusColors.success),
            const SizedBox(width: NexusSizes.spaceSM),
            Expanded(
              child: Text(
                fichero!.name,
                style: NexusText.small.copyWith(color: NexusColors.successText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onEliminado,
              child: Icon(Icons.close, size: 16, color: context.nxt.inkSecondary),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          onSeleccionado(result.files.first);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: NexusSizes.spaceLG),
        decoration: BoxDecoration(
          color: context.nxt.surfaceAlt,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
          border: Border.all(
            color: context.nxt.border,
            width: NexusSizes.borderWidth,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.upload_file_outlined, size: 24, color: context.nxt.inkTertiary),
            const SizedBox(height: NexusSizes.spaceXS),
            Text('Adjuntar PDF, JPG o PNG', style: NexusText.caption),
            Text('Máximo 5 MB', style: NexusText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
