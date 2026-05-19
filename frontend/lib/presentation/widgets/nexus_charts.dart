import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/seguimiento_model.dart';

// ── Donut de progreso FCT ──────────────────────────────────────────────────────

class ProgresoDonutChart extends StatelessWidget {
  final double horasCompletadas;
  final int horasTotales;

  const ProgresoDonutChart({
    super.key,
    required this.horasCompletadas,
    required this.horasTotales,
  });

  @override
  Widget build(BuildContext context) {
    final pct = horasTotales > 0
        ? (horasCompletadas / horasTotales).clamp(0.0, 1.0)
        : 0.0;
    final restantes = (horasTotales - horasCompletadas).clamp(0.0, horasTotales.toDouble());

    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 30,
                  startDegreeOffset: -90,
                  sections: [
                    if (horasCompletadas > 0)
                      PieChartSectionData(
                        value: horasCompletadas.toDouble(),
                        color: NexusColors.primary,
                        radius: 18,
                        showTitle: false,
                      ),
                    PieChartSectionData(
                      value: restantes > 0 ? restantes.toDouble() : (horasCompletadas == 0 ? 1 : 0),
                      color: context.nxt.border,
                      radius: 16,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.nxt.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fmtH(horasCompletadas),
                style: NexusText.heading2.copyWith(
                  color: NexusColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'de ${horasTotales}h completadas',
                style: NexusText.caption.copyWith(color: context.nxt.inkSecondary),
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: NexusColors.primary,
                label: 'Validadas',
                value: fmtH(horasCompletadas),
              ),
              const SizedBox(height: 4),
              _LegendRow(
                color: context.nxt.border,
                label: 'Restantes',
                value: fmtH(restantes),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: NexusText.caption.copyWith(color: context.nxt.inkSecondary)),
        const Spacer(),
        Text(
          value,
          style: NexusText.small.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Bar chart: horas por semana ────────────────────────────────────────────────

class HorasSemanaChart extends StatelessWidget {
  final List<Seguimiento> seguimientos;
  final DateTime? fechaInicio;

  const HorasSemanaChart({
    super.key,
    required this.seguimientos,
    this.fechaInicio,
  });

  @override
  Widget build(BuildContext context) {
    // Solo seguimientos completados
    final completados = seguimientos.where((s) => s.cuentaParaProgreso).toList();

    if (completados.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Sin horas validadas aún',
            style: NexusText.caption.copyWith(color: context.nxt.inkTertiary),
          ),
        ),
      );
    }

    final base = fechaInicio ??
        completados
            .map((s) => s.fechaRegistro)
            .reduce((a, b) => a.isBefore(b) ? a : b);

    final Map<int, double> horasPorSemana = {};
    for (final s in completados) {
      final semana = s.fechaRegistro.difference(base).inDays ~/ 7;
      horasPorSemana[semana] = (horasPorSemana[semana] ?? 0) + s.horasRealizadas;
    }

    final sortedKeys = horasPorSemana.keys.toList()..sort();
    final maxY = (horasPorSemana.values.reduce((a, b) => a > b ? a : b) * 1.3)
        .ceilToDouble()
        .clamp(8.0, double.infinity);

    final bars = sortedKeys.map((semana) {
      return BarChartGroupData(
        x: semana,
        barRods: [
          BarChartRodData(
            toY: horasPorSemana[semana]!,
            gradient: LinearGradient(
              colors: [
                NexusColors.primary,
                NexusColors.primary.withAlpha(180),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: context.nxt.border.withAlpha(60),
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.nxt.border.withAlpha(80),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'S${value.toInt() + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.nxt.inkTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.nxt.surface,
              tooltipBorder: BorderSide(color: context.nxt.border, width: 0.5),
              tooltipRoundedRadius: 6,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toInt()}h',
                TextStyle(
                  color: NexusColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
