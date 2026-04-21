import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/incidencia_model.dart';

class IncidenciaTile extends StatelessWidget {
  final Incidencia incidencia;
  const IncidenciaTile({super.key, required this.incidencia});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NexusSizes.spaceLG, NexusSizes.spaceMD, NexusSizes.spaceLG, 0,
      ),
      child: Row(
        children: [
          _EstadoDot(estado: incidencia.estado),
          const SizedBox(width: NexusSizes.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incidencia.tipo ?? 'OTROS',
                  style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: NexusSizes.spaceXS),
                Text(
                  incidencia.descripcion,
                  style: NexusText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NexusSizes.spaceSM),
          nexusEstadoBadge(
            _labelEstado(incidencia.estado),
            bg: _bgEstado(incidencia.estado),
            textColor: _textEstado(incidencia.estado),
          ),
        ],
      ),
    );
  }

  String _labelEstado(String e) {
    switch (e) {
      case 'ABIERTA': return 'Abierta';
      case 'EN_PROCESO': return 'En proceso';
      case 'RESUELTA': return 'Resuelta';
      case 'CERRADA': return 'Cerrada';
      default: return e;
    }
  }

  Color _bgEstado(String e) {
    switch (e) {
      case 'ABIERTA': return NexusColors.dangerLight;
      case 'EN_PROCESO': return NexusColors.warningLight;
      case 'RESUELTA':
      case 'CERRADA': return NexusColors.successLight;
      default: return NexusColors.neutralLight;
    }
  }

  Color _textEstado(String e) {
    switch (e) {
      case 'ABIERTA': return NexusColors.dangerText;
      case 'EN_PROCESO': return NexusColors.warningText;
      case 'RESUELTA':
      case 'CERRADA': return NexusColors.successText;
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
      case 'ABIERTA': color = NexusColors.danger; break;
      case 'EN_PROCESO': color = NexusColors.warning; break;
      default: color = NexusColors.success;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
