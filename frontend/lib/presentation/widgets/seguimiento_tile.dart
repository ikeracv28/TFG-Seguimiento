import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/seguimiento_model.dart';

class SeguimientoTile extends StatelessWidget {
  final Seguimiento seguimiento;
  const SeguimientoTile({super.key, required this.seguimiento});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NexusSizes.spaceLG, NexusSizes.spaceMD, NexusSizes.spaceLG, 0,
      ),
      child: Row(
        children: [
          _EstadoDot(estado: seguimiento.estado),
          const SizedBox(width: NexusSizes.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(seguimiento.fechaRegistro),
                  style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: NexusSizes.spaceXS),
                Text(
                  '${seguimiento.horasRealizadas}h  ·  ${_labelEstado(seguimiento.estado)}',
                  style: NexusText.caption,
                ),
              ],
            ),
          ),
          nexusEstadoBadge(
            _labelEstado(seguimiento.estado),
            bg: _bgEstado(seguimiento.estado),
            textColor: _textEstado(seguimiento.estado),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _labelEstado(String e) {
    switch (e) {
      case 'COMPLETADO': return 'Completado';
      case 'PENDIENTE_EMPRESA': return 'Pend. empresa';
      case 'PENDIENTE_CENTRO': return 'Pend. centro';
      case 'RECHAZADO': return 'Rechazado';
      default: return e;
    }
  }

  Color _bgEstado(String e) {
    switch (e) {
      case 'COMPLETADO': return NexusColors.successLight;
      case 'PENDIENTE_EMPRESA':
      case 'PENDIENTE_CENTRO': return NexusColors.warningLight;
      case 'RECHAZADO': return NexusColors.dangerLight;
      default: return NexusColors.neutralLight;
    }
  }

  Color _textEstado(String e) {
    switch (e) {
      case 'COMPLETADO': return NexusColors.successText;
      case 'PENDIENTE_EMPRESA':
      case 'PENDIENTE_CENTRO': return NexusColors.warningText;
      case 'RECHAZADO': return NexusColors.dangerText;
      default: return NexusColors.neutralText;
    }
  }
}

class _EstadoDot extends StatelessWidget {
  final String estado;
  const _EstadoDot({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (estado) {
      case 'COMPLETADO': color = NexusColors.success; break;
      case 'RECHAZADO': color = NexusColors.danger; break;
      default: color = NexusColors.warning;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
