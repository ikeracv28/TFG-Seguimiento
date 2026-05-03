import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/mensaje_model.dart';
import '../providers/auth_provider.dart';
import '../providers/practica_provider.dart';
import '../providers/chat_provider.dart';

class ChatPlaceholderScreen extends StatefulWidget {
  final int? practicaId;
  const ChatPlaceholderScreen({super.key, this.practicaId});

  @override
  State<ChatPlaceholderScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPlaceholderScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Si practicaId viene por prop (tutor) lo usamos directamente.
      if (widget.practicaId != null) {
        context.read<ChatProvider>().iniciar(widget.practicaId!);
        return;
      }
      // Para el alumno, practicaActiva puede tardar en cargarse.
      // Intentamos inmediatamente y, si es null, escuchamos al provider.
      final id = context.read<PracticaProvider>().practicaActiva?.id;
      if (id != null) {
        context.read<ChatProvider>().iniciar(id);
      } else {
        context.read<PracticaProvider>().addListener(_onPracticaLoaded);
      }
    });
  }

  void _onPracticaLoaded() {
    if (!mounted) return;
    final id = context.read<PracticaProvider>().practicaActiva?.id;
    if (id != null) {
      context.read<PracticaProvider>().removeListener(_onPracticaLoaded);
      context.read<ChatProvider>().iniciar(id);
    }
  }

  @override
  void dispose() {
    // Limpieza defensiva por si se destruye antes de que practicaActiva llegue
    context.read<PracticaProvider>().removeListener(_onPracticaLoaded);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviar() {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty) return;
    context.read<ChatProvider>().enviar(texto);
    _inputCtrl.clear();
    _scrollAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final practicaActiva = context.watch<PracticaProvider>().practicaActiva;
    final codigoChat = practicaActiva?.codigo
        ?? 'Práctica #${widget.practicaId}';

    if (widget.practicaId == null && practicaActiva == null) {
      return const Center(
        child: Text(
          'Selecciona un alumno para abrir el chat.',
          style: TextStyle(color: NexusColors.inkSecondary),
        ),
      );
    }

    if (chat.mensajes.isNotEmpty) _scrollAlFinal();

    return Column(
      children: [
        // ---- Header ----
        Container(
          color: NexusColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.spaceLG, vertical: NexusSizes.spaceMD),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 18, color: NexusColors.primary),
              const SizedBox(width: NexusSizes.spaceSM),
              Expanded(
                child: Text(
                  'Chat — $codigoChat',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: NexusColors.ink),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chat.conectado
                      ? NexusColors.success
                      : NexusColors.neutral,
                ),
              ),
              const SizedBox(width: NexusSizes.spaceXS),
              Text(
                chat.conectado ? 'Conectado' : 'Conectando…',
                style: TextStyle(
                    fontSize: 11,
                    color: chat.conectado
                        ? NexusColors.success
                        : NexusColors.inkTertiary),
              ),
            ],
          ),
        ),
        const Divider(height: 0.5, thickness: 0.5, color: NexusColors.border),

        // ---- Lista de mensajes ----
        Expanded(
          child: chat.cargando
              ? const Center(child: CircularProgressIndicator())
              : chat.mensajes.isEmpty
                  ? const Center(
                      child: Text(
                        'Sé el primero en escribir.',
                        style: TextStyle(
                            color: NexusColors.inkTertiary, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: NexusSizes.spaceLG,
                          vertical: NexusSizes.spaceMD),
                      itemCount: chat.mensajes.length,
                      itemBuilder: (_, i) {
                        final msg = chat.mensajes[i];
                        final esMio = msg.remitenteId == auth.user?.id;
                        return _MensajeBurbuja(mensaje: msg, esMio: esMio);
                      },
                    ),
        ),

        const Divider(height: 0.5, thickness: 0.5, color: NexusColors.border),

        // ---- Input ----
        Container(
          color: NexusColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceSM),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLength: 1000,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje…',
                    hintStyle: const TextStyle(
                        color: NexusColors.inkTertiary, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(NexusSizes.radiusFull),
                      borderSide:
                          const BorderSide(color: NexusColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(NexusSizes.radiusFull),
                      borderSide:
                          const BorderSide(color: NexusColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: NexusSizes.spaceLG,
                        vertical: NexusSizes.spaceSM),
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: NexusSizes.spaceSM),
              FilledButton(
                onPressed: chat.conectado ? _enviar : null,
                style: FilledButton.styleFrom(
                  backgroundColor: NexusColors.primary,
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send_rounded,
                    size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MensajeBurbuja extends StatelessWidget {
  final MensajeModel mensaje;
  final bool esMio;

  const _MensajeBurbuja({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    final hora =
        '${mensaje.fechaEnvio.hour.toString().padLeft(2, '0')}:${mensaje.fechaEnvio.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: NexusSizes.spaceSM),
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esMio) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: NexusColors.primaryLight,
              child: Text(
                mensaje.remitenteNombre.isNotEmpty
                    ? mensaje.remitenteNombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NexusColors.primaryText),
              ),
            ),
            const SizedBox(width: NexusSizes.spaceXS),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: esMio
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!esMio)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: NexusSizes.spaceXS, bottom: 2),
                    child: Text(
                      mensaje.nombreCompleto,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: NexusColors.inkSecondary),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: NexusSizes.spaceMD,
                      vertical: NexusSizes.spaceSM),
                  decoration: BoxDecoration(
                    color: esMio ? NexusColors.primary : NexusColors.surface,
                    border: esMio
                        ? null
                        : Border.all(color: NexusColors.border),
                    borderRadius: BorderRadius.only(
                      topLeft:
                          const Radius.circular(NexusSizes.radiusMD),
                      topRight:
                          const Radius.circular(NexusSizes.radiusMD),
                      bottomLeft: Radius.circular(
                          esMio ? NexusSizes.radiusMD : 4),
                      bottomRight: Radius.circular(
                          esMio ? 4 : NexusSizes.radiusMD),
                    ),
                  ),
                  child: Text(
                    mensaje.contenido,
                    style: TextStyle(
                        fontSize: 13,
                        color: esMio ? Colors.white : NexusColors.ink),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 2,
                      left: NexusSizes.spaceXS,
                      right: NexusSizes.spaceXS),
                  child: Text(hora,
                      style: const TextStyle(
                          fontSize: 10,
                          color: NexusColors.inkTertiary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
