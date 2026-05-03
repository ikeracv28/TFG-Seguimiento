import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/mensaje_model.dart';
import '../../core/config/api_client.dart';

class MensajeService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _suscrito = false;

  Future<List<MensajeModel>> getHistorial(int practicaId) async {
    final response =
        await _apiClient.dio.get('/mensajes/practica/$practicaId');
    return (response.data as List)
        .map((j) => MensajeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> conectar({
    required int practicaId,
    required void Function(MensajeModel) onMensaje,
    void Function()? onConectado,
    void Function()? onDesconectado,
  }) async {
    await desconectar();

    final token = await _storage.read(key: 'jwt_token') ?? '';

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080/ws'),
      );

      _sub = _channel!.stream.listen(
        (data) => _onFrame(
          data.toString(),
          practicaId: practicaId,
          onMensaje: onMensaje,
          onConectado: onConectado,
          onDesconectado: onDesconectado,
        ),
        onError: (_) => onDesconectado?.call(),
        onDone: () => onDesconectado?.call(),
        cancelOnError: false,
      );

      // STOMP CONNECT frame
      _channel!.sink.add(
        'CONNECT\naccept-version:1.2\nheart-beat:0,0\n'
        'Authorization:Bearer $token\n\n\x00',
      );
    } catch (_) {
      onDesconectado?.call();
    }
  }

  void _onFrame(
    String raw, {
    required int practicaId,
    required void Function(MensajeModel) onMensaje,
    void Function()? onConectado,
    void Function()? onDesconectado,
  }) {
    // Heartbeat frames son solo '\n'
    if (raw.trim().isEmpty) return;

    if (raw.startsWith('CONNECTED')) {
      _suscrito = true;
      _channel!.sink.add(
        'SUBSCRIBE\nid:sub-0\ndestination:/topic/practica/$practicaId\n\n\x00',
      );
      onConectado?.call();
    } else if (raw.startsWith('MESSAGE')) {
      _parseMensaje(raw, onMensaje);
    } else if (raw.startsWith('ERROR')) {
      onDesconectado?.call();
    }
  }

  void _parseMensaje(String raw, void Function(MensajeModel) onMensaje) {
    try {
      final bodyStart = raw.indexOf('\n\n');
      if (bodyStart == -1) return;
      final body = raw
          .substring(bodyStart + 2)
          .replaceAll('\x00', '')
          .trim();
      if (body.isEmpty) return;
      final json = jsonDecode(body) as Map<String, dynamic>;
      onMensaje(MensajeModel.fromJson(json));
    } catch (_) {}
  }

  void enviarMensaje({required int practicaId, required String contenido}) {
    if (_channel == null || !_suscrito) return;
    final body = jsonEncode({'contenido': contenido});
    _channel!.sink.add(
      'SEND\ndestination:/app/chat/$practicaId\n'
      'content-type:application/json\n'
      'content-length:${body.length}\n\n'
      '$body\x00',
    );
  }

  Future<void> desconectar() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _suscrito = false;
  }
}
