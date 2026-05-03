import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/services/ausencia_service.dart';
import '../providers/practica_provider.dart';
import '../widgets/ausencia_tile.dart';

class AusenciasScreen extends StatelessWidget {
  const AusenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final ausencias = provider.ausencias;
        return Scaffold(
          backgroundColor: NexusColors.surfaceAlt,
          body: RefreshIndicator(
            color: NexusColors.primary,
            onRefresh: provider.cargarDashboard,
            child: ListView(
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              children: [
                if (provider.practicaActiva != null)
                  _BotonRegistrar(
                    practicaId: provider.practicaActiva!.id,
                    onRegistrada: (ausencia) => provider.agregarAusencia(ausencia),
                  ),
                const SizedBox(height: NexusSizes.space2XL),
                if (ausencias.isEmpty)
                  const _EmptyAusencias()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                    ),
                    child: Column(
                      children: ausencias.asMap().entries.map((entry) {
                        final ausencia = entry.value;
                        final isLast = entry.key == ausencias.length - 1;
                        return Column(
                          children: [
                            AusenciaTile(
                              ausencia: ausencia,
                              onEliminar: ausencia.estaPendiente
                                  ? () => _confirmarEliminar(context, ausencia.id, provider)
                                  : null,
                              onAdjuntarFichero: ausencia.estaPendiente && !ausencia.tieneJustificante
                                  ? () => _adjuntarJustificante(context, ausencia.id, provider)
                                  : null,
                            ),
                            if (!isLast)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: NexusSizes.spaceLG),
                                child: Divider(height: 1, thickness: 0.5, color: NexusColors.border),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
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
        content: const Text('Esta ausencia aun no fue revisada. ¿Seguro que quieres eliminarla?'),
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

class _BotonRegistrar extends StatelessWidget {
  final int practicaId;
  final Function(Ausencia) onRegistrada;

  const _BotonRegistrar({required this.practicaId, required this.onRegistrada});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _mostrarBottomSheet(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Registrar ausencia'),
      style: OutlinedButton.styleFrom(
        foregroundColor: NexusColors.warning,
        side: const BorderSide(color: NexusColors.warning, width: NexusSizes.borderWidth),
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
      builder: (_) => _RegistrarAusenciaSheet(
        practicaId: practicaId,
        onRegistrada: onRegistrada,
      ),
    );
  }
}

class _RegistrarAusenciaSheet extends StatefulWidget {
  final int practicaId;
  final Function(Ausencia) onRegistrada;

  const _RegistrarAusenciaSheet({
    required this.practicaId,
    required this.onRegistrada,
  });

  @override
  State<_RegistrarAusenciaSheet> createState() => _RegistrarAusenciaSheetState();
}

class _RegistrarAusenciaSheetState extends State<_RegistrarAusenciaSheet> {
  DateTime _fechaSeleccionada = DateTime.now();
  final _motivoController = TextEditingController();
  // Fichero opcional seleccionado antes de enviar
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
              Text('Registrar ausencia', style: NexusText.heading3),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: NexusColors.inkSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
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
            decoration: _inputDecoration(hint: 'Explica el motivo de la ausencia...'),
            style: NexusText.small,
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
                foregroundColor: NexusColors.surface,
                padding: const EdgeInsets.symmetric(vertical: NexusSizes.spaceMD),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar'),
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
      // 1. Registrar ausencia
      Ausencia ausencia = await AusenciaService().registrar(
        practicaId: widget.practicaId,
        fecha: _fechaSeleccionada,
        motivo: motivo,
      );

      // 2. Si hay fichero, adjuntarlo inmediatamente
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
        Navigator.pop(context);
        widget.onRegistrada(ausencia);
      }
    } catch (e) {
      setState(() {
        _enviando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
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
              child: const Icon(Icons.close, size: 16, color: NexusColors.inkSecondary),
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
        padding: const EdgeInsets.all(NexusSizes.spaceMD),
        decoration: BoxDecoration(
          color: NexusColors.surfaceAlt,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
          border: Border.all(
            color: NexusColors.border,
            width: NexusSizes.borderWidth,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file_outlined, size: 16, color: NexusColors.inkSecondary),
            const SizedBox(width: NexusSizes.spaceSM),
            Text(
              'Adjuntar PDF, JPG o PNG (max. 5 MB)',
              style: NexusText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: NexusColors.surfaceAlt,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
          border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: NexusColors.inkSecondary),
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

class _EmptyAusencias extends StatelessWidget {
  const _EmptyAusencias();

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
          const Icon(Icons.event_available_outlined, size: 36, color: NexusColors.inkTertiary),
          const SizedBox(height: NexusSizes.spaceMD),
          Text('Sin ausencias registradas', style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(
            'Si faltaste un dia, registra la ausencia para que quede documentada.',
            style: NexusText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
