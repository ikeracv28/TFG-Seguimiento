import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/incidencia_service.dart';
import '../providers/practica_provider.dart';
import '../widgets/incidencia_tile.dart';

class IncidenciasScreen extends StatelessWidget {
  const IncidenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final incidencias = provider.incidencias;
        return Scaffold(
          backgroundColor: NexusColors.surfaceAlt,
          body: RefreshIndicator(
            color: NexusColors.primary,
            onRefresh: provider.cargarDashboard,
            child: ListView(
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              children: [
                _BotonReportar(onReportado: provider.cargarDashboard),
                const SizedBox(height: NexusSizes.space2XL),
                if (incidencias.isEmpty)
                  const _EmptyIncidencias()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                    ),
                    child: Column(
                      children: [
                        ...incidencias.asMap().entries.map((entry) {
                          final isLast = entry.key == incidencias.length - 1;
                          return Column(
                            children: [
                              IncidenciaTile(incidencia: entry.value),
                              if (!isLast)
                                const Padding(
                                  padding: EdgeInsets.only(
                                    top: NexusSizes.spaceMD,
                                    left: NexusSizes.spaceLG,
                                    right: NexusSizes.spaceLG,
                                  ),
                                  child: Divider(height: 1, thickness: 0.5, color: NexusColors.border),
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: NexusSizes.spaceMD),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BotonReportar extends StatelessWidget {
  final VoidCallback onReportado;
  const _BotonReportar({required this.onReportado});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _mostrarBottomSheet(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Reportar incidencia'),
      style: OutlinedButton.styleFrom(
        foregroundColor: NexusColors.danger,
        side: const BorderSide(color: NexusColors.danger, width: NexusSizes.borderWidth),
        padding: const EdgeInsets.symmetric(vertical: NexusSizes.spaceMD),
      ),
    );
  }

  void _mostrarBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexusColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(NexusSizes.radiusLG)),
      ),
      builder: (_) => _ReportarIncidenciaSheet(onReportado: onReportado),
    );
  }
}

class _ReportarIncidenciaSheet extends StatefulWidget {
  final VoidCallback onReportado;
  const _ReportarIncidenciaSheet({required this.onReportado});

  @override
  State<_ReportarIncidenciaSheet> createState() => _ReportarIncidenciaSheetState();
}

class _ReportarIncidenciaSheetState extends State<_ReportarIncidenciaSheet> {
  static const _tipos = ['ACCESO', 'AUSENCIA', 'COMPORTAMIENTO', 'ACCIDENTE', 'OTROS'];
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        NexusSizes.space2XL, NexusSizes.space2XL,
        NexusSizes.space2XL, NexusSizes.space2XL + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Reportar incidencia', style: NexusText.heading3),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: NexusColors.inkSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: NexusSizes.spaceLG),
          Text('Tipo', style: NexusText.caption),
          const SizedBox(height: NexusSizes.spaceSM),
          DropdownButtonFormField<String>(
            value: _tipoSeleccionado,
            decoration: _inputDecoration(),
            items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _tipoSeleccionado = v!),
          ),
          const SizedBox(height: NexusSizes.spaceLG),
          Text('Descripcion', style: NexusText.caption),
          const SizedBox(height: NexusSizes.spaceSM),
          TextFormField(
            controller: _descripcionController,
            maxLines: 4,
            decoration: _inputDecoration(hint: 'Describe lo que ha ocurrido...'),
            style: NexusText.small,
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
                backgroundColor: NexusColors.danger,
                foregroundColor: NexusColors.surface,
                padding: const EdgeInsets.symmetric(vertical: NexusSizes.spaceMD),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar reporte'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: NexusText.caption,
    filled: true,
    fillColor: NexusColors.surfaceAlt,
    contentPadding: const EdgeInsets.all(NexusSizes.spaceMD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      borderSide: const BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      borderSide: const BorderSide(color: NexusColors.border, width: NexusSizes.borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      borderSide: const BorderSide(color: NexusColors.primary, width: 1),
    ),
  );

  Future<void> _enviar() async {
    final descripcion = _descripcionController.text.trim();
    if (descripcion.length < 10) {
      setState(() => _error = 'La descripcion debe tener al menos 10 caracteres.');
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

class _EmptyIncidencias extends StatelessWidget {
  const _EmptyIncidencias();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: NexusSizes.space3XL),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 36, color: NexusColors.inkTertiary),
          const SizedBox(height: NexusSizes.spaceMD),
          Text('Sin incidencias activas', style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(
            'Usa el boton de arriba si tienes algun problema que reportar.',
            style: NexusText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
