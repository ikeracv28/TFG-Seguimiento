import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ausencia_model.dart';

class AusenciaTile extends StatelessWidget {
  final Ausencia ausencia;
  final VoidCallback? onEliminar;
  final VoidCallback? onAdjuntarFichero;

  const AusenciaTile({
    super.key,
    required this.ausencia,
    this.onEliminar,
    this.onAdjuntarFichero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NexusSizes.spaceLG, NexusSizes.spaceMD, NexusSizes.spaceSM, NexusSizes.spaceMD,
      ),
      child: Row(
        children: [
          _TipoDot(tipo: ausencia.tipo),
          const SizedBox(width: NexusSizes.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFecha(ausencia.fecha),
                  style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: NexusSizes.spaceXS),
                Text(
                  ausencia.motivo,
                  style: NexusText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ausencia.tieneJustificante)
                  Padding(
                    padding: const EdgeInsets.only(top: NexusSizes.spaceXS),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 12, color: NexusColors.inkTertiary),
                        const SizedBox(width: 2),
                        Text(
                          ausencia.nombreFichero ?? 'Justificante adjunto',
                          style: NexusText.caption.copyWith(color: NexusColors.inkTertiary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: NexusSizes.spaceSM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              nexusEstadoBadge(
                _labelTipo(ausencia.tipo),
                bg: _bgTipo(ausencia.tipo),
                textColor: _textTipo(ausencia.tipo),
              ),
              if (ausencia.estaPendiente && onAdjuntarFichero != null && !ausencia.tieneJustificante)
                GestureDetector(
                  onTap: onAdjuntarFichero,
                  child: Padding(
                    padding: const EdgeInsets.only(top: NexusSizes.spaceXS),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 11, color: NexusColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          'Adjuntar',
                          style: NexusText.caption.copyWith(color: NexusColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              if (ausencia.estaPendiente && onEliminar != null)
                GestureDetector(
                  onTap: onEliminar,
                  child: Padding(
                    padding: const EdgeInsets.only(top: NexusSizes.spaceXS),
                    child: Text(
                      'Eliminar',
                      style: NexusText.caption.copyWith(color: NexusColors.danger),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _labelTipo(String t) {
    switch (t) {
      case 'PENDIENTE': return 'Pendiente';
      case 'JUSTIFICADA': return 'Justificada';
      case 'INJUSTIFICADA': return 'Injustificada';
      default: return t;
    }
  }

  Color _bgTipo(String t) {
    switch (t) {
      case 'PENDIENTE': return NexusColors.warningLight;
      case 'JUSTIFICADA': return NexusColors.successLight;
      case 'INJUSTIFICADA': return NexusColors.dangerLight;
      default: return NexusColors.neutralLight;
    }
  }

  Color _textTipo(String t) {
    switch (t) {
      case 'PENDIENTE': return NexusColors.warningText;
      case 'JUSTIFICADA': return NexusColors.successText;
      case 'INJUSTIFICADA': return NexusColors.dangerText;
      default: return NexusColors.neutralText;
    }
  }
}

class _TipoDot extends StatelessWidget {
  final String tipo;
  const _TipoDot({required this.tipo});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (tipo) {
      case 'PENDIENTE': color = NexusColors.warning; break;
      case 'JUSTIFICADA': color = NexusColors.success; break;
      default: color = NexusColors.danger;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
