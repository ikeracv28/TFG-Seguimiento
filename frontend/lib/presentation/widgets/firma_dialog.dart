import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/seguimiento_service.dart';

/// Dialog de firma electrónica manuscrita.
/// [seguimientoId] — ID del parte a firmar.
/// [rol] — 'ALUMNO' o 'TUTOR_EMPRESA'.
/// [onFirmado] — callback con el seguimiento actualizado.
class FirmaDialog extends StatefulWidget {
  final int seguimientoId;
  final String rol;
  final Future<void> Function(dynamic seguimientoActualizado) onFirmado;

  const FirmaDialog({
    super.key,
    required this.seguimientoId,
    required this.rol,
    required this.onFirmado,
  });

  @override
  State<FirmaDialog> createState() => _FirmaDialogState();
}

class _FirmaDialogState extends State<FirmaDialog> {
  final _controller = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_controller.isEmpty) {
      setState(() => _error = 'Dibuja tu firma antes de confirmar.');
      return;
    }

    setState(() { _enviando = true; _error = null; });

    try {
      final bytes = await _controller.toPngBytes();
      if (bytes == null) throw Exception('No se pudo exportar la firma.');
      final base64 = 'data:image/png;base64,${base64Encode(bytes)}';

      final actualizado = await SeguimientoService().firmar(
        widget.seguimientoId,
        imagenBase64: base64,
        rol: widget.rol,
      );

      if (mounted) {
        Navigator.pop(context);
        await widget.onFirmado(actualizado);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.rol == 'ALUMNO' ? 'Firma del alumno' : 'Firma del tutor de empresa';

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
              border: Border.all(color: context.nxt.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
                  child: Row(
                    children: [
                      const Icon(Icons.draw_outlined, size: 20, color: NexusColors.primary),
                      const SizedBox(width: 10),
                      Text(label,
                          style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.nxt.border),
                // Canvas
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: context.nxt.border),
                        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                        color: Colors.white,
                      ),
                      child: Signature(
                        controller: _controller,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: NexusColors.danger),
                        const SizedBox(width: 6),
                        Flexible(child: Text(_error!,
                            style: NexusText.caption.copyWith(color: NexusColors.danger))),
                      ],
                    ),
                  ),
                // Botones
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => setState(() { _controller.clear(); _error = null; }),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Limpiar'),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _enviando ? null : _confirmar,
                        style: FilledButton.styleFrom(backgroundColor: NexusColors.primary),
                        child: _enviando
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Confirmar firma'),
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
