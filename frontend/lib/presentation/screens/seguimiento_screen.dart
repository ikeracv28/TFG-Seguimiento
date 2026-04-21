import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/practica_provider.dart';
import '../../data/services/seguimiento_service.dart';

/**
 * Pantalla de registro de un parte semanal de prácticas.
 *
 * El alumno introduce:
 *   - Fecha del parte (DatePicker — no puede ser futura)
 *   - Horas realizadas ese día/semana (1 – 24)
 *   - Descripción de las tareas (texto libre, obligatoria)
 *
 * Al enviar se llama POST /api/v1/seguimientos con el JWT en cabecera.
 * Si el servidor responde 201, se añade el seguimiento al provider
 * sin necesidad de recargar todo el dashboard desde la red.
 */
class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _horasCtrl = TextEditingController();
  final _seguimientoService = SeguimientoService();

  DateTime _fechaSeleccionada = DateTime.now();
  bool _enviando = false;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _horasCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Selección de fecha con DatePicker nativo
  // ──────────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // No se puede registrar una fecha futura
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        // Aplicamos el color primario Nexus al DatePicker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: NexusColors.primary,
              onPrimary: Colors.white,
              surface: NexusColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  // ──────────────────────────────────────────────
  // Envío del formulario
  // ──────────────────────────────────────────────
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PracticaProvider>(context, listen: false);
    final practica = provider.practicaActiva;

    if (practica == null) {
      _mostrarError('No tienes una práctica activa asignada.');
      return;
    }

    setState(() => _enviando = true);

    try {
      final nuevo = await _seguimientoService.registrar(
        practicaId: practica.id,
        fechaRegistro: _fechaSeleccionada,
        horasRealizadas: int.parse(_horasCtrl.text.trim()),
        descripcion: _descripcionCtrl.text.trim(),
      );

      // Actualiza el estado local sin llamada extra a la red
      provider.agregarSeguimiento(nuevo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Parte registrado correctamente'),
            backgroundColor: NexusColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: NexusColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: NexusColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Registrar seguimiento', style: NexusText.heading3),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: NexusColors.border),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas anchas el formulario se centra y limita a 500px
          final isWide = constraints.maxWidth > 700;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NexusSizes.space2XL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Fecha ──────────────────────────────
                      _FieldLabel('Fecha del parte'),
                      const SizedBox(height: NexusSizes.spaceSM),
                      _FechaPicker(
                        fecha: _fechaSeleccionada,
                        onTap: _seleccionarFecha,
                      ),
                      const SizedBox(height: NexusSizes.spaceLG),

                      // ── Horas ──────────────────────────────
                      _FieldLabel('Horas realizadas'),
                      const SizedBox(height: NexusSizes.spaceSM),
                      TextFormField(
                        controller: _horasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ej. 8',
                          suffixText: 'h',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Introduce las horas realizadas';
                          }
                          final horas = int.tryParse(value.trim());
                          if (horas == null || horas < 1 || horas > 24) {
                            return 'Introduce un valor entre 1 y 24';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: NexusSizes.spaceLG),

                      // ── Descripción ────────────────────────
                      _FieldLabel('Descripcion de las tareas'),
                      const SizedBox(height: NexusSizes.spaceSM),
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 5,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe brevemente las tareas realizadas durante este periodo...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripcion es obligatoria';
                          }
                          if (value.trim().length < 10) {
                            return 'Minimo 10 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: NexusSizes.space2XL),

                      // ── Botón de envío ─────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _enviando ? null : _enviar,
                          child: _enviando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Registrar parte'),
                        ),
                      ),
                      const SizedBox(height: NexusSizes.spaceMD),

                      // ── Nota informativa ──────────────────
                      Container(
                        padding: const EdgeInsets.all(NexusSizes.spaceMD),
                        decoration: BoxDecoration(
                          color: NexusColors.primaryLight,
                          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 15,
                              color: NexusColors.primary,
                            ),
                            const SizedBox(width: NexusSizes.spaceSM),
                            Expanded(
                              child: Text(
                                'El parte quedará pendiente de validacion por tu tutor de empresa. Una vez validado, tu tutor del centro dara el visto bueno final.',
                                style: NexusText.caption.copyWith(
                                  color: NexusColors.primaryText,
                                ),
                              ),
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
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: NexusText.small.copyWith(fontWeight: FontWeight.w500),
    );
  }
}

class _FechaPicker extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;
  const _FechaPicker({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final texto =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: NexusColors.surface,
          border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
          borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: NexusColors.inkSecondary,
            ),
            const SizedBox(width: NexusSizes.spaceSM),
            Text(texto, style: NexusText.small),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: NexusColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
