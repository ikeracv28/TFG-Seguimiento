import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/mensaje_model.dart';
import '../../core/config/api_client.dart';

class MensajeService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _suscrito = false;

  Future<List<MensajeModel>> getHistorial(int practicaId, {String canal = 'ALUMNO'}) async {
    final response = await _apiClient.dio
        .get('/mensajes/practica/$practicaId', queryParameters: {'canal': canal});
    return (response.data as List)
        .map((j) => MensajeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<MensajeModel> subirAdjunto({
    required int practicaId,
    required String canal,
    required Uint8List bytes,
    required String nombre,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'fichero': MultipartFile.fromBytes(
        bytes,
        filename: nombre,
        contentType: MediaType.parse(mimeType),
      ),
    });
    final response = await _apiClient.dio.post(
      '/mensajes/practica/$practicaId/adjunto',
      queryParameters: {'canal': canal},
      data: formData,
    );
    return MensajeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> descargarAdjunto(int mensajeId, String nombre) async {
    final response = await _apiClient.dio.get(
      '/mensajes/$mensajeId/adjunto',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data as Uint8List;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', nombre)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> conectar({
    required int practicaId,
    required String canal,
    required void Function(MensajeModel) onMensaje,
    void Function()? onConectado,
    void Function()? onDesconectado,
  }) async {
    await desconectar();

    final token = await _storage.read(key: 'jwt_token') ?? '';
    final topic = canal == 'TUTORES'
        ? '/topic/practica/$practicaId/tutores'
        : '/topic/practica/$practicaId';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiClient.wsBaseUrl));

      _sub = _channel!.stream.listen(
        (data) => _onFrame(
          data.toString(),
          topic: topic,
          practicaId: practicaId,
          canal: canal,
          onMensaje: onMensaje,
          onConectado: onConectado,
          onDesconectado: onDesconectado,
        ),
        onError: (_) => onDesconectado?.call(),
        onDone: () => onDesconectado?.call(),
        cancelOnError: false,
      );

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
    required String topic,
    required int practicaId,
    required String canal,
    required void Function(MensajeModel) onMensaje,
    void Function()? onConectado,
    void Function()? onDesconectado,
  }) {
    if (raw.trim().isEmpty) return;

    if (raw.startsWith('CONNECTED')) {
      _suscrito = true;
      _channel!.sink.add('SUBSCRIBE\nid:sub-0\ndestination:$topic\n\n\x00');
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
      final body = raw.substring(bodyStart + 2).replaceAll('\x00', '').trim();
      if (body.isEmpty) return;
      final json = jsonDecode(body) as Map<String, dynamic>;
      onMensaje(MensajeModel.fromJson(json));
    } catch (_) {}
  }

  void enviarMensaje({required int practicaId, required String contenido, String canal = 'ALUMNO'}) {
    if (_channel == null || !_suscrito) return;
    final destination = canal == 'TUTORES'
        ? '/app/chat/$practicaId/tutores'
        : '/app/chat/$practicaId';
    final body = jsonEncode({'contenido': contenido, 'canal': canal});
    _channel!.sink.add(
      'SEND\ndestination:$destination\n'
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
