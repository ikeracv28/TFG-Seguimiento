// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/models/evaluacion_final_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/services/ausencia_service.dart';
import '../providers/auth_provider.dart';
import '../providers/tutor_empresa_provider.dart';
import 'chat_placeholder_screen.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import '../widgets/nexus_avatar.dart';
import '../providers/notificacion_provider.dart';
import '../widgets/nexus_logo.dart';

class PanelTutorEmpresaScreen extends StatefulWidget {
  const PanelTutorEmpresaScreen({super.key});

  @override
  State<PanelTutorEmpresaScreen> createState() =>
      _PanelTutorEmpresaScreenState();
}

class _PanelTutorEmpresaScreenState extends State<PanelTutorEmpresaScreen> {
  int _tab = 0; // 0 = pendientes, 1 = progreso, 2 = chat
  int? _chatPracticaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorEmpresaProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<TutorEmpresaProvider>();

    return Scaffold(
      backgroundColor: context.nxt.surfaceAlt,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Row(
            children: [
              if (isWide) _Sidebar(auth: auth, tab: _tab, onTab: (t) => setState(() => _tab = t)),
              Expanded(child: _buildContent(auth, provider)),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) return const SizedBox.shrink();
          return _MobileBar(auth: auth, tab: _tab, onTab: (t) => setState(() => _tab = t));
        },
      ),
    );
  }

  Widget _buildContent(AuthProvider auth, TutorEmpresaProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: NexusColors.danger),
            const SizedBox(height: NexusSizes.spaceLG),
            Text(provider.error!, style: NexusText.body),
            const SizedBox(height: NexusSizes.spaceLG),
            OutlinedButton(
              onPressed: () => context.read<TutorEmpresaProvider>().cargar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_tab == 2) return _buildChat(provider);

  return RefreshIndicator(
      onRefresh: () => context.read<TutorEmpresaProvider>().cargar(),
      child: _tab == 0
          ? _buildPendientes(auth, provider)
          : _buildProgreso(provider),
    );
  }

  // ── TAB 0: Partes pendientes ───────────────────────────────────────────────

  Widget _buildPendientes(AuthProvider auth, TutorEmpresaProvider provider) {
    final pendientes = provider.todosPendientes;
    final ausenciasPendientes = provider.ausenciasPendientes;
    final empresa = provider.practicas.isNotEmpty
        ? provider.practicas.first.empresaNombre
        : '';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partes pendientes',
                        style: NexusText.heading2.copyWith(letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(
                      '${auth.user?.nombreCompleto ?? ''} · $empresa',
                      style: NexusText.body.copyWith(color: context.nxt.inkSecondary),
                    ),
                  ],
                ),
              ),
              _RefreshBtn(onPressed: () => context.read<TutorEmpresaProvider>().cargar()),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats — responsive: Row en desktop, Column en móvil ────────
          LayoutBuilder(builder: (ctx, cst) {
            final tiles = [
              _StatTile(
                value: '${pendientes.length}',
                label: 'Pendientes',
                accent: NexusColors.warning,
                bg: NexusColors.warningLight,
                labelColor: NexusColors.warningText,
              ),
              _StatTile(
                value: fmtH(provider.totalHorasValidadasEmpresa),
                label: 'Horas validadas',
                accent: NexusColors.success,
                bg: NexusColors.successLight,
                labelColor: NexusColors.successText,
              ),
              _StatTile(
                value: provider.totalHorasConvenio > 0
                    ? fmtH(provider.totalHorasRestantes)
                    : '—',
                label: 'Horas restantes',
                accent: context.nxt.inkSecondary,
                bg: context.nxt.surfaceAlt,
                labelColor: context.nxt.inkSecondary,
              ),
            ];
            if (cst.maxWidth < 600) {
              return Column(
                children: [
                  tiles[0],
                  const SizedBox(height: 10),
                  tiles[1],
                  const SizedBox(height: 10),
                  tiles[2],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 10),
                Expanded(child: tiles[1]),
                const SizedBox(width: 10),
                Expanded(child: tiles[2]),
              ],
            );
          }),
          const SizedBox(height: 28),

          // ── Contenido principal ────────────────────────────────────────
          if (pendientes.isEmpty && ausenciasPendientes.isEmpty)
            _EmptyCard()
          else ...[
            if (pendientes.isNotEmpty) ...[
              Text(
                'FIRMA PENDIENTE',
                style: NexusText.label.copyWith(
                    color: context.nxt.inkTertiary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              ...pendientes.map((s) {
                final practica = provider.practicaDe(s.practicaId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ParteCard(
                    seguimiento: s,
                    alumnoId: practica?.alumnoId ?? 0,
                    alumnoNombre: practica?.alumnoNombre ?? 'Alumno',
                    onValidar: () => _confirmarValidar(s.id),
                    onRechazar: () => _mostrarModalRechazo(s.id),
                  ),
                );
              }),
              const SizedBox(height: 4),
              _InfoBanner(
                  text: 'Al rechazar deberás indicar el motivo. El tutor del centro será notificado.'),
            ],
            if (ausenciasPendientes.isNotEmpty) ...[
              if (pendientes.isNotEmpty) const SizedBox(height: 28),
              Text(
                'AUSENCIAS PENDIENTES · ${ausenciasPendientes.length}',
                style: NexusText.label.copyWith(
                    color: context.nxt.inkTertiary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              ...ausenciasPendientes.map((ausencia) {
                final practica = provider.practicaDe(ausencia.practicaId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AusenciaEmpresaCard(
                    ausencia: ausencia,
                    alumnoId: practica?.alumnoId ?? 0,
                    alumnoNombre: practica?.alumnoNombre ?? 'Alumno',
                    onJustificar: () => _revisarAusencia(ausencia.id, 'JUSTIFICADA'),
                    onInjustificar: () => _revisarAusencia(ausencia.id, 'INJUSTIFICADA'),
                    onVerJustificante: ausencia.tieneJustificante
                        ? () => _verJustificante(ausencia.id)
                        : null,
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  // ── TAB 1: Progreso del alumno ─────────────────────────────────────────────

  Widget _buildProgreso(TutorEmpresaProvider provider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progreso del alumno',
                        style: NexusText.heading2.copyWith(letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text('Seguimiento de horas y estado del convenio',
                        style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
                  ],
                ),
              ),
              _RefreshBtn(onPressed: () => context.read<TutorEmpresaProvider>().cargar()),
            ],
          ),
          const SizedBox(height: 28),
          if (provider.practicas.isEmpty)
            _EmptyCard()
          else
            ...provider.practicas.map((p) {
              final seguimientos = provider.seguimientosDe(p.id);
              final evaluacion = provider.evaluacionDe(p.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgresoCard(practica: p, seguimientos: seguimientos),
                    const SizedBox(height: 12),
                    _EvaluacionResumenCard(
                      practica: p,
                      evaluacion: evaluacion,
                      onEvaluar: () => _mostrarFormEvaluacion(p.id, evaluacion),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── TAB 2: Chat ───────────────────────────────────────────────────────────

  Widget _buildChat(TutorEmpresaProvider provider) {
    final practicas = provider.practicas;
    if (practicas.isEmpty) {
      return Center(
        child: Text('Sin prácticas asignadas', style: NexusText.body),
      );
    }
    final practicaId = _chatPracticaId ?? practicas.first.id;
    final practica = practicas.firstWhere((p) => p.id == practicaId,
        orElse: () => practicas.first);

    return Column(
      children: [
        // ── Header de contexto ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: context.nxt.surface,
            border: Border(
                bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: NexusColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.supervisor_account_outlined,
                        size: 16, color: NexusColors.success),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat con tutor de centro',
                          style: NexusText.small
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${practica.tutorCentroNombre} · ${practica.codigo} · ${practica.alumnoNombre}',
                          style: NexusText.caption
                              .copyWith(color: context.nxt.inkSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (practicas.length > 1)
                    PopupMenuButton<int>(
                      tooltip: 'Cambiar práctica',
                      icon: Icon(Icons.swap_horiz_outlined,
                          size: 18, color: context.nxt.inkSecondary),
                      onSelected: (id) =>
                          setState(() => _chatPracticaId = id),
                      itemBuilder: (_) => practicas
                          .map((p) => PopupMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.codigo} — ${p.alumnoNombre}',
                                  style: NexusText.small,
                                ),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ChatPlaceholderScreen(
            key: ValueKey(practicaId),
            practicaId: practicaId,
            canal: 'TUTORES',
          ),
        ),
      ],
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  void _mostrarFormEvaluacion(int practicaId, EvaluacionFinalModel? actual) {
    showDialog<void>(
      context: context,
      builder: (_) => _EvaluarDialog(
        practicaId: practicaId,
        actual: actual,
        provider: context.read<TutorEmpresaProvider>(),
      ),
    );
  }

  Future<void> _confirmarValidar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validar parte'),
        content: const Text(
            '¿Confirmas que las horas y actividades descritas son correctas?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NexusColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Validar y firmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ok = await context.read<TutorEmpresaProvider>().validar(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Parte validado correctamente' : 'Error al validar el parte'),
        backgroundColor: ok ? NexusColors.success : NexusColors.danger,
      ));
    }
  }

  Future<void> _verJustificante(int ausenciaId) async {
    try {
      final result = await AusenciaService().descargarJustificante(ausenciaId);
      final blob = html.Blob([result.bytes], result.mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      Future.delayed(const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir el justificante'),
          backgroundColor: NexusColors.danger,
        ));
      }
    }
  }

  Future<void> _revisarAusencia(int id, String tipo) async {
    final esJustificada = tipo == 'JUSTIFICADA';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esJustificada ? 'Justificar ausencia' : 'Marcar como injustificada'),
        content: Text(esJustificada
            ? '¿Confirmas que la ausencia queda justificada?'
            : '¿Confirmas que la ausencia es injustificada?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: esJustificada ? NexusColors.success : NexusColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(esJustificada ? 'Justificar' : 'Injustificar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ok = await context.read<TutorEmpresaProvider>().justificarAusencia(id, tipo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Ausencia marcada como ${esJustificada ? 'justificada' : 'injustificada'}'
            : 'Error al revisar la ausencia'),
        backgroundColor: ok
            ? (esJustificada ? NexusColors.success : NexusColors.warning)
            : NexusColors.danger,
      ));
    }
  }

  Future<void> _mostrarModalRechazo(int id) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.nxt.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(NexusSizes.radiusLG)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rechazar parte', style: NexusText.heading2),
                const SizedBox(height: 6),
                Text(
                  'El alumno recibirá una incidencia automática con el motivo indicado.',
                  style: NexusText.body.copyWith(color: context.nxt.inkSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: motivoController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del rechazo *',
                    hintText: 'Describe qué debe corregir el alumno...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'El motivo es obligatorio' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: NexusColors.danger),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          final ok = await context
                              .read<TutorEmpresaProvider>()
                              .rechazar(id, motivoController.text.trim());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Parte rechazado. Se notificará al alumno.'
                                  : 'Error al rechazar el parte'),
                              backgroundColor:
                                  ok ? NexusColors.warning : NexusColors.danger,
                            ));
                          }
                        },
                        child: const Text('Rechazar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      motivoController.dispose();
    }
  }
}

// ── Progreso card ──────────────────────────────────────────────────────────────

class _ProgresoCard extends StatelessWidget {
  final Practica practica;
  final List<Seguimiento> seguimientos;

  const _ProgresoCard({required this.practica, required this.seguimientos});

  @override
  Widget build(BuildContext context) {
    final horasValidadas = seguimientos
        .where((s) => s.estado == 'PENDIENTE_CENTRO' || s.estado == 'COMPLETADO')
        .fold(0.0, (sum, s) => sum + s.horasRealizadas);
    final horasRegistradas = seguimientos.fold(0.0, (sum, s) => sum + s.horasRealizadas);
    final horasTotales = practica.horasTotales ?? 0;
    final horasRestantes = (horasTotales - horasValidadas).clamp(0.0, horasTotales.toDouble());
    final progreso = horasTotales > 0 ? (horasValidadas / horasTotales).clamp(0.0, 1.0) : 0.0;
    final pct = (progreso * 100).round();

    final fmt = DateFormat('d MMM yyyy', 'es_ES');
    final inicio = practica.fechaInicio != null ? fmt.format(practica.fechaInicio!) : '—';
    final fin = practica.fechaFin != null ? fmt.format(practica.fechaFin!) : '—';

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera alumno ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
            ),
            child: Row(
              children: [
                NexusAvatar(
                  userId: practica.alumnoId,
                  nombre: practica.alumnoNombre,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(practica.alumnoNombre,
                          style: NexusText.body.copyWith(fontWeight: FontWeight.w600)),
                      Text('${practica.codigo} · ${practica.empresaNombre}',
                          style: NexusText.small.copyWith(color: context.nxt.inkSecondary)),
                    ],
                  ),
                ),
                _EstadoPill(estado: practica.estado),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fechas ───────────────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: context.nxt.inkSecondary),
                    const SizedBox(width: 6),
                    Text('$inicio  →  $fin',
                        style: NexusText.small.copyWith(color: context.nxt.inkSecondary)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Barra de progreso ────────────────────────────────────
                Row(
                  children: [
                    Text('Progreso del convenio',
                        style: NexusText.small.copyWith(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('$pct%',
                        style: NexusText.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _colorProgreso(pct))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 8,
                    backgroundColor: context.nxt.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(_colorProgreso(pct)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Desglose de horas ────────────────────────────────────
                Row(
                  children: [
                    _HorasStat(
                      label: 'Registradas\npor el alumno',
                      value: fmtH(horasRegistradas),
                      color: context.nxt.inkSecondary,
                    ),
                    _Divider(),
                    _HorasStat(
                      label: 'Validadas\npor ti',
                      value: fmtH(horasValidadas),
                      color: NexusColors.success,
                    ),
                    _Divider(),
                    _HorasStat(
                      label: 'Restantes\ndel convenio',
                      value: horasTotales > 0 ? fmtH(horasRestantes) : '—',
                      color: horasRestantes == 0 && horasTotales > 0
                          ? NexusColors.success
                          : NexusColors.warning,
                    ),
                    if (horasTotales > 0) ...[
                      _Divider(),
                      _HorasStat(
                        label: 'Total\ndel convenio',
                        value: '${horasTotales}h',
                        color: context.nxt.inkTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorProgreso(int pct) {
    if (pct >= 100) return NexusColors.success;
    if (pct >= 60) return NexusColors.primary;
    return NexusColors.warning;
  }
}

class _HorasStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HorasStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: color, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: context.nxt.inkSecondary, height: 1.3)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: context.nxt.border, margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}

class _EstadoPill extends StatelessWidget {
  final String estado;
  const _EstadoPill({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      'ACTIVA'     => ('Activa', NexusColors.success),
      'FINALIZADA' => ('Finalizada', NexusColors.inkSecondary),
      _            => ('Borrador', NexusColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
        border: Border.all(color: color.withAlpha(77), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final AuthProvider auth;
  final int tab;
  final ValueChanged<int> onTab;
  const _Sidebar({required this.auth, required this.tab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(right: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo marca
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: NexusLogo(height: 26),
          ),
          Divider(height: 1, color: context.nxt.border),
          const SizedBox(height: 6),
          _NavItem(
            icon: Icons.list_alt_outlined,
            label: 'Partes pendientes',
            selected: tab == 0,
            onTap: () => onTab(0),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Progreso',
            selected: tab == 1,
            onTap: () => onTab(1),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat tutores',
            selected: tab == 2,
            onTap: () => onTab(2),
          ),
          const Spacer(),
          Divider(height: 1, color: context.nxt.border),
          // Perfil
          InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerfilScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  NexusAvatar(
                    userId: auth.user!.id,
                    nombre: auth.user!.nombreCompleto,
                    radius: 13,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(auth.user!.nombreCompleto,
                        style: TextStyle(fontSize: 12, color: context.nxt.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          Consumer<NotificacionProvider>(
            builder: (ctx, notifProv, _) {
              final count = notifProv.noLeidas;
              return InkWell(
                onTap: () async {
                  await Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                        value: notifProv,
                        child: const NotificacionesScreen(),
                      )));
                  notifProv.cargar();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Badge(
                        isLabelVisible: count > 0,
                        label: Text(count > 9 ? '9+' : '$count',
                            style: const TextStyle(fontSize: 10)),
                        child: Icon(Icons.notifications_none_outlined,
                            size: 17, color: ctx.nxt.inkSecondary),
                      ),
                      const SizedBox(width: 10),
                      Text('Notificaciones',
                          style: TextStyle(fontSize: 12, color: context.nxt.inkSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
          InkWell(
            onTap: () => context.read<ThemeProvider>().toggle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 17, color: context.nxt.inkSecondary),
                  const SizedBox(width: 10),
                  Text(isDark ? 'Modo claro' : 'Modo oscuro',
                      style: TextStyle(fontSize: 12, color: context.nxt.inkSecondary)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => auth.logout(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.logout_outlined, size: 17, color: context.nxt.inkSecondary),
                  const SizedBox(width: 10),
                  Text('Cerrar sesión',
                      style: TextStyle(fontSize: 12, color: context.nxt.inkSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? NexusColors.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16,
                color: selected ? NexusColors.primary : context.nxt.inkSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? NexusColors.primary : context.nxt.inkSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile bar ─────────────────────────────────────────────────────────────────

class _MobileBar extends StatelessWidget {
  final AuthProvider auth;
  final int tab;
  final ValueChanged<int> onTab;
  const _MobileBar({required this.auth, required this.tab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border(top: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onTab(0),
            child: _MobileTab(
                icon: Icons.list_alt_outlined,
                label: 'Pendientes',
                selected: tab == 0),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onTab(1),
            child: _MobileTab(
                icon: Icons.bar_chart_rounded,
                label: 'Progreso',
                selected: tab == 1),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onTab(2),
            child: _MobileTab(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                selected: tab == 2),
          ),
          const Spacer(),
          Builder(builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 18, color: context.nxt.inkSecondary),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () => ctx.read<ThemeProvider>().toggle(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            );
          }),
          TextButton.icon(
            onPressed: () => auth.logout(),
            icon: Icon(Icons.logout_outlined,
                size: 16, color: context.nxt.inkSecondary),
            label: Text('Salir',
                style: NexusText.small.copyWith(color: context.nxt.inkSecondary)),
          ),
        ],
      ),
    );
  }
}

class _MobileTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _MobileTab({required this.icon, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16,
            color: selected ? NexusColors.success : NexusColors.inkSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: NexusText.small.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? NexusColors.success : context.nxt.inkSecondary)),
      ],
    );
  }
}

// ── Info banner ────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: NexusColors.primaryLight,
        border: Border.all(color: const Color(0xFFB5D4F4), width: 0.5),
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: NexusColors.primaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: NexusText.small.copyWith(color: NexusColors.primaryText)),
          ),
        ],
      ),
    );
  }
}

// ── Refresh button ─────────────────────────────────────────────────────────────

class _RefreshBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _RefreshBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Recargar',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.refresh_rounded,
              size: 16, color: context.nxt.inkSecondary),
        ),
      ),
    );
  }
}

// ── Stat tile ──────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final Color bg;
  final Color labelColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
    required this.bg,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600,
                  color: accent, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        ],
      ),
    );
  }
}

// ── Parte card ─────────────────────────────────────────────────────────────────

class _ParteCard extends StatelessWidget {
  final Seguimiento seguimiento;
  final int alumnoId;
  final String alumnoNombre;
  final VoidCallback onValidar;
  final VoidCallback onRechazar;

  const _ParteCard({
    required this.seguimiento,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.onValidar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = seguimiento.esSemanal
        ? 'Sem. ${DateFormat('d MMM', 'es_ES').format(seguimiento.fechaRegistro)} - ${DateFormat('d MMM yyyy', 'es_ES').format(seguimiento.fechaRegistro.add(const Duration(days: 4)))}'
        : DateFormat('d MMM yyyy', 'es_ES').format(seguimiento.fechaRegistro);

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
            ),
            child: Row(
              children: [
                NexusAvatar(userId: alumnoId, nombre: alumnoNombre, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alumnoNombre,
                          style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                      Text(fecha,
                          style: NexusText.caption.copyWith(color: context.nxt.inkSecondary)),
                    ],
                  ),
                ),
                _HoursPill(hours: seguimiento.horasRealizadas, esSemanal: seguimiento.esSemanal),
                const SizedBox(width: 8),
                _StatusPill(label: 'Pendiente', color: NexusColors.warning),
              ],
            ),
          ),
          if (seguimiento.descripcion != null && seguimiento.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.nxt.surfaceAlt,
                  borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                  border: Border(left: BorderSide(color: context.nxt.border, width: 3)),
                ),
                child: Text(
                  '"${seguimiento.descripcion}"',
                  style: NexusText.body.copyWith(
                      color: context.nxt.inkSecondary, fontStyle: FontStyle.italic),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexusColors.danger,
                      side: const BorderSide(color: NexusColors.danger, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Rechazar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onValidar,
                    icon: const Icon(Icons.draw_outlined, size: 15),
                    label: const Text('Validar y firmar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    style: FilledButton.styleFrom(
                      backgroundColor: NexusColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ausencia card ──────────────────────────────────────────────────────────────

class _AusenciaEmpresaCard extends StatelessWidget {
  final Ausencia ausencia;
  final int alumnoId;
  final String alumnoNombre;
  final VoidCallback onJustificar;
  final VoidCallback onInjustificar;
  final VoidCallback? onVerJustificante;

  const _AusenciaEmpresaCard({
    required this.ausencia,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.onJustificar,
    required this.onInjustificar,
    this.onVerJustificante,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d MMM yyyy', 'es_ES').format(ausencia.fecha);

    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.nxt.border, width: NexusSizes.borderWidth)),
            ),
            child: Row(
              children: [
                NexusAvatar(userId: alumnoId, nombre: alumnoNombre, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alumnoNombre,
                          style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                      Text(fecha,
                          style: NexusText.caption.copyWith(color: context.nxt.inkSecondary)),
                    ],
                  ),
                ),
                if (ausencia.tieneJustificante && onVerJustificante != null) ...[
                  GestureDetector(
                    onTap: onVerJustificante,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NexusColors.successLight,
                        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                        border: Border.all(color: NexusColors.success.withAlpha(60), width: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 11, color: NexusColors.successText),
                          SizedBox(width: 3),
                          Text('Ver justificante',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: NexusColors.successText)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                _StatusPill(label: 'Pendiente', color: NexusColors.warning),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.nxt.surfaceAlt,
                borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                border: const Border(left: BorderSide(color: NexusColors.warning, width: 3)),
              ),
              child: Text(ausencia.motivo,
                  style: NexusText.body.copyWith(color: context.nxt.inkSecondary),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onInjustificar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexusColors.danger,
                      side: const BorderSide(color: NexusColors.danger, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Injustificada',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onJustificar,
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: const Text('Justificada',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    style: FilledButton.styleFrom(
                      backgroundColor: NexusColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty card ─────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: context.nxt.surface,
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: NexusColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 28, color: NexusColors.success),
          ),
          const SizedBox(height: 16),
          Text('Todo al día', style: NexusText.heading3),
          const SizedBox(height: 6),
          Text('No hay partes pendientes de firma.',
              style: NexusText.body.copyWith(color: context.nxt.inkSecondary)),
        ],
      ),
    );
  }
}

// ── Pills ──────────────────────────────────────────────────────────────────────

class _HoursPill extends StatelessWidget {
  final double hours;
  final bool esSemanal;
  const _HoursPill({required this.hours, this.esSemanal = false});

  @override
  Widget build(BuildContext context) {
    final label = hours == hours.truncateToDouble() ? '${hours.toInt()}h' : '${hours.truncate()}h 30min';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.nxt.surfaceAlt,
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
      ),
      child: Text(esSemanal ? '$label/sem' : label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: context.nxt.inkSecondary)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
        border: Border.all(color: color.withAlpha(77), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ── Evaluación resumen card ────────────────────────────────────────────────────

class _EvaluacionResumenCard extends StatelessWidget {
  final Practica practica;
  final EvaluacionFinalModel? evaluacion;
  final VoidCallback onEvaluar;

  const _EvaluacionResumenCard({
    required this.practica,
    required this.evaluacion,
    required this.onEvaluar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nxt.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.grade_outlined,
              color: evaluacion != null ? NexusColors.warning : context.nxt.inkTertiary,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: evaluacion == null
                ? Text('Sin evaluación final — puedes registrarla ahora',
                    style: NexusText.body.copyWith(color: context.nxt.inkSecondary))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evaluación registrada',
                          style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                      Text('Nota global: ${evaluacion!.notaGlobal.toStringAsFixed(2)}/10',
                          style: NexusText.caption.copyWith(color: context.nxt.inkSecondary)),
                    ],
                  ),
          ),
          TextButton(
            onPressed: onEvaluar,
            child: Text(evaluacion == null ? 'Evaluar' : 'Modificar'),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo cuestionario de evaluación ────────────────────────────────────────

class _EvaluarDialog extends StatefulWidget {
  final int practicaId;
  final EvaluacionFinalModel? actual;
  final TutorEmpresaProvider provider;

  const _EvaluarDialog({
    required this.practicaId,
    required this.actual,
    required this.provider,
  });

  @override
  State<_EvaluarDialog> createState() => _EvaluarDialogState();
}

class _EvaluarDialogState extends State<_EvaluarDialog> {
  // Criterios opcionales — null = no incluido
  late bool _actitudEnabled;
  late double _actitud;
  late bool _tecnicaEnabled;
  late double _tecnica;
  late bool _iniciativaEnabled;
  late double _iniciativa;
  late bool _equipoEnabled;
  late double _equipo;
  late bool _cumplimientoEnabled;
  late double _cumplimiento;

  late double _global;
  final _comentarioCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _actitudEnabled      = a?.actitudPuntualidad != null;
    _actitud             = a?.actitudPuntualidad ?? 7.0;
    _tecnicaEnabled      = a?.competenciaTecnica != null;
    _tecnica             = a?.competenciaTecnica ?? 7.0;
    _iniciativaEnabled   = a?.iniciativaAutonomia != null;
    _iniciativa          = a?.iniciativaAutonomia ?? 7.0;
    _equipoEnabled       = a?.trabajoEquipo != null;
    _equipo              = a?.trabajoEquipo ?? 7.0;
    _cumplimientoEnabled = a?.cumplimientoTareas != null;
    _cumplimiento        = a?.cumplimientoTareas ?? 7.0;
    _global              = a?.notaGlobal ?? 7.0;
    _comentarioCtrl.text = a?.comentario ?? '';
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Color _color(double v) {
    if (v >= 7) return NexusColors.success;
    if (v >= 5) return NexusColors.warning;
    return NexusColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.actual == null ? 'Evaluar al alumno' : 'Modificar evaluación',
        style: NexusText.heading3,
      ),
      content: LayoutBuilder(builder: (ctx, constraints) {
        final dialogWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : (MediaQuery.of(ctx).size.width * 0.9).clamp(0.0, 520.0);
        return SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criterios de evaluación (opcionales — activa con el interruptor)',
                  style: NexusText.caption.copyWith(color: context.nxt.inkSecondary)),
              const SizedBox(height: 16),

              _CriterioSlider(
                label: 'Actitud y puntualidad',
                icon: Icons.access_time_rounded,
                enabled: _actitudEnabled,
                value: _actitud,
                color: _color(_actitud),
                onToggle: (v) => setState(() => _actitudEnabled = v),
                onChanged: (v) => setState(() => _actitud = v),
              ),
              _CriterioSlider(
                label: 'Competencia técnica',
                icon: Icons.build_outlined,
                enabled: _tecnicaEnabled,
                value: _tecnica,
                color: _color(_tecnica),
                onToggle: (v) => setState(() => _tecnicaEnabled = v),
                onChanged: (v) => setState(() => _tecnica = v),
              ),
              _CriterioSlider(
                label: 'Iniciativa y autonomía',
                icon: Icons.lightbulb_outline,
                enabled: _iniciativaEnabled,
                value: _iniciativa,
                color: _color(_iniciativa),
                onToggle: (v) => setState(() => _iniciativaEnabled = v),
                onChanged: (v) => setState(() => _iniciativa = v),
              ),
              _CriterioSlider(
                label: 'Trabajo en equipo',
                icon: Icons.group_outlined,
                enabled: _equipoEnabled,
                value: _equipo,
                color: _color(_equipo),
                onToggle: (v) => setState(() => _equipoEnabled = v),
                onChanged: (v) => setState(() => _equipo = v),
              ),
              _CriterioSlider(
                label: 'Cumplimiento de tareas',
                icon: Icons.task_alt_outlined,
                enabled: _cumplimientoEnabled,
                value: _cumplimiento,
                color: _color(_cumplimiento),
                onToggle: (v) => setState(() => _cumplimientoEnabled = v),
                onChanged: (v) => setState(() => _cumplimiento = v),
              ),

              const SizedBox(height: 8),
              Divider(height: 1, thickness: 0.5, color: context.nxt.border),
              const SizedBox(height: 20),

              // ── Nota global obligatoria ───────────────────────────────────
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 18, color: _color(_global)),
                  const SizedBox(width: 8),
                  Text('Nota global *',
                      style: NexusText.small.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _color(_global).withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _global.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _color(_global)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: _color(_global),
                  inactiveTrackColor: _color(_global).withAlpha(40),
                  thumbColor: _color(_global),
                  overlayColor: _color(_global).withAlpha(30),
                ),
                child: Slider(
                  value: _global,
                  min: 0,
                  max: 10,
                  divisions: 100,
                  onChanged: (v) => setState(() => _global = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: NexusText.label.copyWith(color: context.nxt.inkTertiary)),
                    Text('5', style: NexusText.label.copyWith(color: context.nxt.inkTertiary)),
                    Text('10', style: NexusText.label.copyWith(color: context.nxt.inkTertiary)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _comentarioCtrl,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  hintText: 'Valoración general del desempeño del alumno...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      );
      }),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar evaluación'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final ok = await widget.provider.evaluar(
      widget.practicaId,
      actitudPuntualidad: _actitudEnabled ? _actitud : null,
      competenciaTecnica: _tecnicaEnabled ? _tecnica : null,
      iniciativaAutonomia: _iniciativaEnabled ? _iniciativa : null,
      trabajoEquipo: _equipoEnabled ? _equipo : null,
      cumplimientoTareas: _cumplimientoEnabled ? _cumplimiento : null,
      notaGlobal: _global,
      comentario: _comentarioCtrl.text.trim().isEmpty ? null : _comentarioCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Evaluación guardada correctamente' : 'Error al guardar'),
        backgroundColor: ok ? NexusColors.success : NexusColors.danger,
      ));
    }
  }
}

class _CriterioSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final double value;
  final Color color;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

  const _CriterioSlider({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.value,
    required this.color,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 15,
                  color: enabled ? color : context.nxt.inkTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: NexusText.small.copyWith(
                    color: enabled ? context.nxt.ink : context.nxt.inkTertiary,
                    fontWeight: enabled ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (enabled)
                Container(
                  width: 42,
                  height: 26,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: NexusColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (enabled)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: color,
                inactiveTrackColor: color.withAlpha(35),
                thumbColor: color,
                overlayColor: color.withAlpha(25),
              ),
              child: Slider(
                value: value,
                min: 1,
                max: 10,
                divisions: 18,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}
