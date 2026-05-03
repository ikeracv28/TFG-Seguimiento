// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/services/ausencia_service.dart';
import '../providers/auth_provider.dart';
import '../providers/tutor_empresa_provider.dart';

class PanelTutorEmpresaScreen extends StatefulWidget {
  const PanelTutorEmpresaScreen({super.key});

  @override
  State<PanelTutorEmpresaScreen> createState() =>
      _PanelTutorEmpresaScreenState();
}

class _PanelTutorEmpresaScreenState extends State<PanelTutorEmpresaScreen> {
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
      backgroundColor: NexusColors.surfaceAlt,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Row(
            children: [
              if (isWide) _Sidebar(auth: auth),
              Expanded(child: _buildContent(auth, provider)),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) return const SizedBox.shrink();
          return _MobileBar(auth: auth);
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

    final pendientes = provider.todosPendientes;
    final ausenciasPendientes = provider.ausenciasPendientes;
    final empresa = provider.practicas.isNotEmpty
        ? provider.practicas.first.empresaNombre
        : '';

    return RefreshIndicator(
      onRefresh: () => context.read<TutorEmpresaProvider>().cargar(),
      child: SingleChildScrollView(
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
                          style: NexusText.heading2
                              .copyWith(letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text(
                        '${auth.user?.nombreCompleto ?? ''} · $empresa',
                        style: NexusText.body
                            .copyWith(color: NexusColors.inkSecondary),
                      ),
                    ],
                  ),
                ),
                _RefreshBtn(
                    onPressed: () =>
                        context.read<TutorEmpresaProvider>().cargar()),
              ],
            ),
            const SizedBox(height: 24),

            // ── Stats ──────────────────────────────────────────────────────
            Row(
              children: [
                _StatTile(
                  value: '${pendientes.length}',
                  label: 'Pendientes',
                  accent: NexusColors.warning,
                  bg: NexusColors.warningLight,
                  labelColor: NexusColors.warningText,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  value: '${provider.totalValidados}',
                  label: 'Procesados',
                  accent: NexusColors.success,
                  bg: NexusColors.successLight,
                  labelColor: NexusColors.successText,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  value: '${provider.totalHoras}h',
                  label: 'Horas totales',
                  accent: NexusColors.inkSecondary,
                  bg: const Color(0xFFF1EFE8),
                  labelColor: NexusColors.inkSecondary,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Contenido principal ────────────────────────────────────────
            if (pendientes.isEmpty && ausenciasPendientes.isEmpty)
              _EmptyCard()
            else ...[
              // Partes de seguimiento pendientes
              if (pendientes.isNotEmpty) ...[
                Text(
                  'FIRMA PENDIENTE',
                  style: NexusText.label.copyWith(
                    color: NexusColors.inkTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ...pendientes.asMap().entries.map((e) {
                  final practica =
                      provider.practicaDe(e.value.practicaId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ParteCard(
                      seguimiento: e.value,
                      alumnoNombre: practica?.alumnoNombre ?? 'Alumno',
                      onValidar: () => _confirmarValidar(e.value.id),
                      onRechazar: () => _mostrarModalRechazo(e.value.id),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: NexusColors.primaryLight,
                    border: Border.all(
                        color: const Color(0xFFB5D4F4), width: 0.5),
                    borderRadius:
                        BorderRadius.circular(NexusSizes.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: NexusColors.primaryText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Al rechazar deberás indicar el motivo. El tutor del centro será notificado.',
                          style: NexusText.small
                              .copyWith(color: NexusColors.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Ausencias pendientes
              if (ausenciasPendientes.isNotEmpty) ...[
                if (pendientes.isNotEmpty) const SizedBox(height: 28),
                Text(
                  'AUSENCIAS PENDIENTES · ${ausenciasPendientes.length}',
                  style: NexusText.label.copyWith(
                    color: NexusColors.inkTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ...ausenciasPendientes.map((ausencia) {
                  final practica = provider.practicaDe(ausencia.practicaId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AusenciaEmpresaCard(
                      ausencia: ausencia,
                      alumnoNombre: practica?.alumnoNombre ?? 'Alumno',
                      onJustificar: () =>
                          _revisarAusencia(ausencia.id, 'JUSTIFICADA'),
                      onInjustificar: () =>
                          _revisarAusencia(ausencia.id, 'INJUSTIFICADA'),
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
            style:
                FilledButton.styleFrom(backgroundColor: NexusColors.success),
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
        content: Text(
            ok ? 'Parte validado correctamente' : 'Error al validar el parte'),
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
                backgroundColor:
                    esJustificada ? NexusColors.success : NexusColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(esJustificada ? 'Justificar' : 'Injustificar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ok = await context
        .read<TutorEmpresaProvider>()
        .justificarAusencia(id, tipo);
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
        backgroundColor: NexusColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(NexusSizes.radiusLG)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                  style:
                      NexusText.body.copyWith(color: NexusColors.inkSecondary),
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
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El motivo es obligatorio'
                      : null,
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
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Parte rechazado. Se notificará al alumno.'
                                  : 'Error al rechazar el parte'),
                              backgroundColor: ok
                                  ? NexusColors.warning
                                  : NexusColors.danger,
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

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final AuthProvider auth;
  const _Sidebar({required this.auth});

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(auth.user?.nombreCompleto ?? '');
    return Container(
      width: 52,
      decoration: const BoxDecoration(
        color: NexusColors.surface,
        border: Border(
            right: BorderSide(
                color: NexusColors.border, width: NexusSizes.borderWidth)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: NexusColors.success,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.star_outline, size: 13, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: 'Partes pendientes',
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: NexusColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.list_alt_outlined,
                  size: 17, color: NexusColors.success),
            ),
          ),
          const Spacer(),
          Tooltip(
            message: auth.user?.nombreCompleto ?? '',
            child: CircleAvatar(
              radius: 15,
              backgroundColor: NexusColors.successLight,
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: NexusColors.successText)),
            ),
          ),
          const SizedBox(height: 4),
          Tooltip(
            message: 'Cerrar sesión',
            child: IconButton(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout_outlined,
                  size: 18, color: NexusColors.inkSecondary),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getInitials(String nombre) {
    final parts =
        nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Mobile bar ─────────────────────────────────────────────────────────────────

class _MobileBar extends StatelessWidget {
  final AuthProvider auth;
  const _MobileBar({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NexusColors.surface,
        border: Border(
            top: BorderSide(
                color: NexusColors.border, width: NexusSizes.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: NexusColors.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child:
                const Icon(Icons.star_outline, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Partes pendientes',
                style:
                    NexusText.small.copyWith(fontWeight: FontWeight.w500)),
          ),
          TextButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_outlined,
                size: 16, color: NexusColors.inkSecondary),
            label: Text('Salir',
                style: NexusText.small
                    .copyWith(color: NexusColors.inkSecondary)),
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
            border: Border.all(
                color: NexusColors.border, width: NexusSizes.borderWidth),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.refresh_rounded,
              size: 16, color: NexusColors.inkSecondary),
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
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: labelColor)),
          ],
        ),
      ),
    );
  }
}

// ── Parte card ─────────────────────────────────────────────────────────────────

class _ParteCard extends StatelessWidget {
  final Seguimiento seguimiento;
  final String alumnoNombre;
  final VoidCallback onValidar;
  final VoidCallback onRechazar;

  const _ParteCard({
    required this.seguimiento,
    required this.alumnoNombre,
    required this.onValidar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d MMM yyyy', 'es_ES')
        .format(seguimiento.fechaRegistro);
    final initials = alumnoNombre
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera de la card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: NexusColors.border,
                      width: NexusSizes.borderWidth)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: NexusColors.primaryLight,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NexusColors.primaryText)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alumnoNombre,
                          style: NexusText.small
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(fecha,
                          style: NexusText.caption.copyWith(
                              color: NexusColors.inkSecondary)),
                    ],
                  ),
                ),
                _HoursPill(hours: seguimiento.horasRealizadas),
                const SizedBox(width: 8),
                _StatusPill(label: 'Pendiente', color: NexusColors.warning),
              ],
            ),
          ),

          // ── Descripción ───────────────────────────────────────────────
          if (seguimiento.descripcion != null &&
              seguimiento.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NexusColors.surfaceAlt,
                  borderRadius:
                      BorderRadius.circular(NexusSizes.radiusSM),
                  border: const Border(
                    left: BorderSide(
                        color: NexusColors.border, width: 3),
                  ),
                ),
                child: Text(
                  '"${seguimiento.descripcion}"',
                  style: NexusText.body.copyWith(
                    color: NexusColors.inkSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // ── Acciones ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexusColors.danger,
                      side: const BorderSide(
                          color: NexusColors.danger, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Rechazar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onValidar,
                    icon: const Icon(Icons.draw_outlined, size: 15),
                    label: const Text('Validar y firmar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
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

// ── Ausencia empresa card ──────────────────────────────────────────────────────

class _AusenciaEmpresaCard extends StatelessWidget {
  final Ausencia ausencia;
  final String alumnoNombre;
  final VoidCallback onJustificar;
  final VoidCallback onInjustificar;
  final VoidCallback? onVerJustificante;

  const _AusenciaEmpresaCard({
    required this.ausencia,
    required this.alumnoNombre,
    required this.onJustificar,
    required this.onInjustificar,
    this.onVerJustificante,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('d MMM yyyy', 'es_ES').format(ausencia.fecha);
    final initials = alumnoNombre
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: NexusColors.border,
                      width: NexusSizes.borderWidth)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: NexusColors.warningLight,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NexusColors.warningText)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alumnoNombre,
                          style: NexusText.small
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(fecha,
                          style: NexusText.caption
                              .copyWith(color: NexusColors.inkSecondary)),
                    ],
                  ),
                ),
                if (ausencia.tieneJustificante && onVerJustificante != null) ...[
                  GestureDetector(
                    onTap: onVerJustificante,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NexusColors.successLight,
                        borderRadius:
                            BorderRadius.circular(NexusSizes.radiusFull),
                        border: Border.all(
                            color: NexusColors.success.withAlpha(60),
                            width: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new,
                              size: 11, color: NexusColors.successText),
                          SizedBox(width: 3),
                          Text('Ver justificante',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
          // Motivo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NexusColors.surfaceAlt,
                borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                border: const Border(
                  left: BorderSide(color: NexusColors.warning, width: 3),
                ),
              ),
              child: Text(
                ausencia.motivo,
                style: NexusText.body
                    .copyWith(color: NexusColors.inkSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Acciones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onInjustificar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexusColors.danger,
                      side: const BorderSide(
                          color: NexusColors.danger, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Injustificada',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onJustificar,
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: const Text('Justificada',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
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
        color: NexusColors.surface,
        border: Border.all(
            color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NexusColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 28, color: NexusColors.success),
          ),
          const SizedBox(height: 16),
          Text('Todo al día', style: NexusText.heading3),
          const SizedBox(height: 6),
          Text('No hay partes pendientes de firma.',
              style:
                  NexusText.body.copyWith(color: NexusColors.inkSecondary)),
        ],
      ),
    );
  }
}

// ── Pills ──────────────────────────────────────────────────────────────────────

class _HoursPill extends StatelessWidget {
  final int hours;
  const _HoursPill({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
      ),
      child: Text('${hours}h',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NexusColors.inkSecondary)),
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
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}
