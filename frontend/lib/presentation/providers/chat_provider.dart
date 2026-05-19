import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../data/models/mensaje_model.dart';
import '../../data/services/mensaje_service.dart';

class ChatProvider extends ChangeNotifier {
  final MensajeService _service = MensajeService();

  List<MensajeModel> _mensajes = [];
  bool _cargando = false;
  bool _conectado = false;
  int? _practicaId;
  String _canal = 'ALUMNO';

  List<MensajeModel> get mensajes => _mensajes;
  bool get cargando => _cargando;
  bool get conectado => _conectado;

  Future<void> iniciar(int practicaId, {String canal = 'ALUMNO'}) async {
    if (_practicaId == practicaId && _canal == canal && _conectado) return;
    _practicaId = practicaId;
    _canal = canal;
    _cargando = true;
    notifyListeners();

    try {
      _mensajes = await _service.getHistorial(practicaId, canal: canal);
    } catch (_) {
      _mensajes = [];
    }

    await _service.conectar(
      practicaId: practicaId,
      canal: canal,
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
      canal: _canal,
    );
  }

  Future<void> enviarAdjunto({
    required Uint8List bytes,
    required String nombre,
    required String mimeType,
  }) async {
    if (_practicaId == null) return;
    await _service.subirAdjunto(
      practicaId: _practicaId!,
      canal: _canal,
      bytes: bytes,
      nombre: nombre,
      mimeType: mimeType,
    );
    // El backend hace broadcast vía WebSocket → onMensaje lo añadirá a la lista
  }

  Future<void> descargarAdjunto(int mensajeId, String nombre) =>
      _service.descargarAdjunto(mensajeId, nombre);

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
