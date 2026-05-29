import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Barra de paginación reutilizable — paginación en cliente.
/// Uso:
///   PaginationBar(pagina: _pagina, total: lista.length, porPagina: _porPagina,
///       onAnterior: () => setState(() => _pagina--),
///       onSiguiente: () => setState(() => _pagina++))
class PaginationBar extends StatelessWidget {
  final int pagina;
  final int total;
  final int porPagina;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const PaginationBar({
    super.key,
    required this.pagina,
    required this.total,
    required this.porPagina,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final totalPaginas = (total / porPagina).ceil().clamp(1, 9999);
    final inicio = pagina * porPagina + 1;
    final fin = ((pagina + 1) * porPagina).clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.space2XL, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      child: Row(
        children: [
          Text(
            total == 0
                ? 'Sin resultados'
                : 'Mostrando $inicio–$fin de $total',
            style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
          ),
          const Spacer(),
          Text(
            'Pág. ${pagina + 1} / $totalPaginas',
            style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
          ),
          const SizedBox(width: 12),
          _PageBtn(
            icon: Icons.chevron_left,
            enabled: pagina > 0,
            onTap: onAnterior,
          ),
          const SizedBox(width: 4),
          _PageBtn(
            icon: Icons.chevron_right,
            enabled: (pagina + 1) < totalPaginas,
            onTap: onSiguiente,
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: enabled ? context.nxt.surfaceAlt : Colors.transparent,
          border: Border.all(color: context.nxt.border),
          borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
        ),
        child: Icon(
          icon, size: 16,
          color: enabled ? context.nxt.ink : context.nxt.inkTertiary,
        ),
      ),
    );
  }
}

/// Chips de filtro reutilizables para filtrar por estado.
class EstadoFilterBar extends StatelessWidget {
  final List<String> opciones;
  final String seleccionado;
  final ValueChanged<String> onSeleccionado;
  final Map<String, String> etiquetas;
  final Map<String, Color> colores;

  const EstadoFilterBar({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionado,
    this.etiquetas = const {},
    this.colores = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.space2XL, vertical: 10),
      child: Row(
        children: opciones.map((op) {
          final activo = op == seleccionado;
          final label = etiquetas[op] ?? op;
          final color = colores[op] ?? NexusColors.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSeleccionado(op),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: activo ? color.withAlpha(26) : context.nxt.surfaceAlt,
                  border: Border.all(
                      color: activo ? color : context.nxt.border,
                      width: activo ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    color: activo ? color : context.nxt.inkSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
