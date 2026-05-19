import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/mensaje_model.dart';
import '../providers/auth_provider.dart';
import '../providers/practica_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/nexus_avatar.dart';

class ChatPlaceholderScreen extends StatefulWidget {
  final int? practicaId;
  final String canal; // 'ALUMNO' | 'TUTORES'

  const ChatPlaceholderScreen({
    super.key,
    this.practicaId,
    this.canal = 'ALUMNO',
  });

  @override
  State<ChatPlaceholderScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPlaceholderScreen> {
  // Cada instancia de ChatPlaceholderScreen tiene su propio provider/conexión.
  final ChatProvider _chat = ChatProvider();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _subiendoAdjunto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.practicaId != null) {
        _chat.iniciar(widget.practicaId!, canal: widget.canal);
        _chat.addListener(_onChatUpdate);
        return;
      }
      // Para el alumno, practicaActiva puede tardar en cargarse.
      final id = context.read<PracticaProvider>().practicaActiva?.id;
      if (id != null) {
        _chat.iniciar(id, canal: widget.canal);
        _chat.addListener(_onChatUpdate);
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
      _chat.iniciar(id, canal: widget.canal);
      _chat.addListener(_onChatUpdate);
    }
  }

  void _onChatUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    context.read<PracticaProvider>().removeListener(_onPracticaLoaded);
    _chat.removeListener(_onChatUpdate);
    _chat.dispose();
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
    _chat.enviar(texto);
    _inputCtrl.clear();
    _scrollAlFinal();
  }

  Future<void> _enviarAdjunto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _subiendoAdjunto = true);
    try {
      await _chat.enviarAdjunto(
        bytes: file.bytes!,
        nombre: file.name,
        mimeType: 'application/pdf',
      );
      _scrollAlFinal();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el adjunto')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoAdjunto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final practicaActiva = context.watch<PracticaProvider>().practicaActiva;
    final codigoChat = practicaActiva?.codigo ?? 'Práctica #${widget.practicaId}';
    final esCanalTutores = widget.canal == 'TUTORES';

    if (widget.practicaId == null && practicaActiva == null) {
      return Center(
        child: Text(
          'Selecciona un alumno para abrir el chat.',
          style: TextStyle(color: context.nxt.inkSecondary),
        ),
      );
    }

    if (_chat.mensajes.isNotEmpty) _scrollAlFinal();

    final accentColor = esCanalTutores ? NexusColors.success : NexusColors.primary;

    final chatColumn = Column(
      children: [
        // ---- Header ----
        Container(
          color: context.nxt.surface,
          padding: const EdgeInsets.symmetric(horizontal: NexusSizes.spaceLG, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: esCanalTutores ? NexusColors.successLight : NexusColors.primaryLight,
                  borderRadius: BorderRadius.circular(NexusSizes.radiusSM),
                ),
                child: Icon(
                  esCanalTutores ? Icons.supervisor_account_outlined : Icons.chat_bubble_outline,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: NexusSizes.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esCanalTutores ? 'Chat tutores — $codigoChat' : 'Chat — $codigoChat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.nxt.ink,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _chat.conectado ? NexusColors.success : context.nxt.inkTertiary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _chat.conectado ? 'Conectado' : 'Conectando…',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: _chat.conectado ? NexusColors.success : context.nxt.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

        // ---- Lista de mensajes ----
        Expanded(
          child: Container(
            color: context.nxt.surfaceAlt,
            child: _chat.cargando
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: NexusColors.primary))
                : _chat.mensajes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 36, color: context.nxt.inkTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'Sin mensajes todavía.',
                              style: TextStyle(color: context.nxt.inkSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sé el primero en escribir.',
                              style: TextStyle(color: context.nxt.inkTertiary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(
                            NexusSizes.spaceLG, NexusSizes.spaceLG, NexusSizes.spaceLG, NexusSizes.spaceMD),
                        itemCount: _chat.mensajes.length,
                        itemBuilder: (_, i) {
                          final msg = _chat.mensajes[i];
                          final esMio = msg.remitenteId == auth.user?.id;
                          final showDate = i == 0 ||
                              !_sameDay(_chat.mensajes[i - 1].fechaEnvio, msg.fechaEnvio);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(msg.fechaEnvio),
                              _MensajeBurbuja(mensaje: msg, esMio: esMio, accentColor: accentColor),
                            ],
                          );
                        },
                      ),
          ),
        ),

        Divider(height: 1, thickness: NexusSizes.borderWidth, color: context.nxt.border),

        // ---- Input ----
        Container(
          color: context.nxt.surface,
          padding: const EdgeInsets.symmetric(horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceSM),
          child: Row(
            children: [
              _subiendoAdjunto
                  ? const SizedBox(
                      width: 36, height: 36,
                      child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      onPressed: _chat.conectado ? _enviarAdjunto : null,
                      icon: Icon(Icons.attach_file_rounded, color: context.nxt.inkSecondary, size: 20),
                      tooltip: 'Adjuntar PDF',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
              const SizedBox(width: NexusSizes.spaceXS),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLength: 1000,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  decoration: InputDecoration(
                    hintText: esCanalTutores
                        ? 'Escribe un mensaje para los tutores…'
                        : 'Escribe un mensaje para el tutor…',
                    hintStyle: TextStyle(color: context.nxt.inkTertiary, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                      borderSide: BorderSide(color: context.nxt.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                      borderSide: BorderSide(color: context.nxt.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NexusSizes.radiusFull),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: NexusSizes.spaceLG, vertical: NexusSizes.spaceSM),
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: NexusSizes.spaceSM),
              FilledButton(
                onPressed: _chat.conectado ? _enviar : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );

    return chatColumn;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime fecha;
  const _DateDivider(this.fecha);

  @override
  Widget build(BuildContext context) {
    const dias = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final label = '${dias[fecha.weekday - 1]}, ${fecha.day} de ${meses[fecha.month - 1]}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexusSizes.spaceMD),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.nxt.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NexusSizes.spaceMD),
            child: Text(label, style: NexusText.caption),
          ),
          Expanded(child: Divider(color: context.nxt.border, thickness: 1)),
        ],
      ),
    );
  }
}

class _MensajeBurbuja extends StatelessWidget {
  final MensajeModel mensaje;
  final bool esMio;
  final Color accentColor;

  const _MensajeBurbuja({
    required this.mensaje,
    required this.esMio,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hora =
        '${mensaje.fechaEnvio.hour.toString().padLeft(2, '0')}:${mensaje.fechaEnvio.minute.toString().padLeft(2, '0')}';
    final auth = context.read<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: NexusSizes.spaceSM),
      child: Row(
        mainAxisAlignment: esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esMio) ...[
            NexusAvatar(userId: mensaje.remitenteId, nombre: mensaje.nombreCompleto, radius: 14),
            const SizedBox(width: NexusSizes.spaceXS),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!esMio)
                  Padding(
                    padding: const EdgeInsets.only(left: NexusSizes.spaceXS, bottom: 2),
                    child: Text(
                      mensaje.nombreCompleto,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: context.nxt.inkSecondary),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceSM),
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: esMio ? accentColor : context.nxt.surface,
                    border: esMio ? null : Border.all(color: context.nxt.border),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(NexusSizes.radiusMD),
                      topRight: const Radius.circular(NexusSizes.radiusMD),
                      bottomLeft: Radius.circular(esMio ? NexusSizes.radiusMD : 4),
                      bottomRight: Radius.circular(esMio ? 4 : NexusSizes.radiusMD),
                    ),
                  ),
                  child: mensaje.esAdjunto
                      ? _AdjuntoCard(mensaje: mensaje, esMio: esMio, accentColor: accentColor)
                      : Text(
                          mensaje.contenido,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: esMio ? Colors.white : context.nxt.ink),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: NexusSizes.spaceXS, right: NexusSizes.spaceXS),
                  child: Text(hora, style: TextStyle(fontSize: 10, color: context.nxt.inkTertiary)),
                ),
              ],
            ),
          ),
          if (esMio) ...[
            const SizedBox(width: NexusSizes.spaceXS),
            NexusAvatar(userId: auth.user!.id, nombre: auth.user!.nombreCompleto, radius: 14),
          ],
        ],
      ),
    );
  }
}

class _AdjuntoCard extends StatelessWidget {
  final MensajeModel mensaje;
  final bool esMio;
  final Color accentColor;

  const _AdjuntoCard({required this.mensaje, required this.esMio, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatProvider>();
    final nombre = mensaje.adjuntoNombre ?? 'documento.pdf';
    final iconColor = esMio ? Colors.white70 : accentColor;
    final textColor = esMio ? Colors.white : context.nxt.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.picture_as_pdf_outlined, size: 28, color: iconColor),
        const SizedBox(width: NexusSizes.spaceSM),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => chat.descargarAdjunto(mensaje.id, nombre),
                child: Text(
                  'Descargar',
                  style: TextStyle(
                    fontSize: 11,
                    color: esMio ? Colors.white70 : accentColor,
                    decoration: TextDecoration.underline,
                    decorationColor: esMio ? Colors.white70 : accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

