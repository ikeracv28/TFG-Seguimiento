import 'package:flutter/material.dart';
import '../../data/models/mensaje_model.dart';
import '../../data/services/mensaje_service.dart';

class ChatProvider extends ChangeNotifier {
  final MensajeService _service = MensajeService();

  List<MensajeModel> _mensajes = [];
  bool _cargando = false;
  bool _conectado = false;
  int? _practicaId;

  List<MensajeModel> get mensajes => _mensajes;
  bool get cargando => _cargando;
  bool get conectado => _conectado;

  Future<void> iniciar(int practicaId) async {
    if (_practicaId == practicaId && _conectado) return;
    _practicaId = practicaId;
    _cargando = true;
    notifyListeners();

    try {
      _mensajes = await _service.getHistorial(practicaId);
    } catch (_) {
      _mensajes = [];
    }

    await _service.conectar(
      practicaId: practicaId,
      onMensaje: (mensaje) {
        if (_mensajes.any((m) => m.id == mensaje.id)) return;
        _mensajes.add(mensaje);
        notifyListeners();
      },
      onConectado: () {
        _conectado = true;
        notifyListeners();
      },
      onDesconectado: () {
        _conectado = false;
        notifyListeners();
      },
    );

    _cargando = false;
    notifyListeners();
  }

  void enviar(String contenido) {
    if (_practicaId == null || contenido.trim().isEmpty) return;
    _service.enviarMensaje(
      practicaId: _practicaId!,
      contenido: contenido.trim(),
    );
  }

  void limpiar() {
    _service.desconectar();
    _mensajes = [];
    _conectado = false;
    _practicaId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.desconectar();
    super.dispose();
  }
}
