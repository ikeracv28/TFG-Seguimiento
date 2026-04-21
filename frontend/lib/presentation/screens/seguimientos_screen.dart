import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/practica_provider.dart';
import '../widgets/seguimiento_tile.dart';
import 'seguimiento_screen.dart';

class SeguimientosScreen extends StatelessWidget {
  const SeguimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticaProvider>(
      builder: (_, provider, __) {
        final seguimientos = provider.seguimientos;
        final horasCompletadas = provider.horasCompletadas;
        final horasTotales = provider.practicaActiva?.horasTotales ?? 0;

        return Scaffold(
          backgroundColor: NexusColors.surfaceAlt,
          body: RefreshIndicator(
            color: NexusColors.primary,
            onRefresh: provider.cargarDashboard,
            child: ListView(
              padding: const EdgeInsets.all(NexusSizes.space2XL),
              children: [
                _HeaderHoras(
                  completadas: horasCompletadas,
                  totales: horasTotales,
                ),
                const SizedBox(height: NexusSizes.space2XL),
                if (seguimientos.isEmpty)
                  const _EmptySeguimientos()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
                      borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                    ),
                    child: Column(
                      children: [
                        ...seguimientos.asMap().entries.map((entry) {
                          final isLast = entry.key == seguimientos.length - 1;
                          return Column(
                            children: [
                              SeguimientoTile(seguimiento: entry.value),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SeguimientoScreen()),
            ).then((_) => provider.cargarDashboard()),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo parte'),
            backgroundColor: NexusColors.primary,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}

class _HeaderHoras extends StatelessWidget {
  final int completadas;
  final int totales;
  const _HeaderHoras({required this.completadas, required this.totales});

  @override
  Widget build(BuildContext context) {
    final pct = totales > 0 ? (completadas / totales).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(NexusSizes.space2XL),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progreso de horas', style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: NexusSizes.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Completadas', style: NexusText.caption),
              Text(
                '$completadas / $totales h',
                style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: NexusSizes.spaceSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: NexusColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(NexusColors.primary),
            ),
          ),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%  ·  ${totales - completadas} h restantes',
            style: NexusText.caption,
          ),
        ],
      ),
    );
  }
}

class _EmptySeguimientos extends StatelessWidget {
  const _EmptySeguimientos();

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
          const Icon(Icons.list_alt_outlined, size: 36, color: NexusColors.inkTertiary),
          const SizedBox(height: NexusSizes.spaceMD),
          Text(
            'Aun no has registrado ningun parte',
            style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: NexusSizes.spaceXS),
          Text(
            'Pulsa el boton para registrar tu primer seguimiento.',
            style: NexusText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
