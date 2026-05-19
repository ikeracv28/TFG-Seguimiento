import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/services/notificacion_service.dart';

class NotificacionProvider extends ChangeNotifier {
  final _service = NotificacionService();

  List<NotificacionItem> _items = [];
  int _noLeidas = 0;
  bool _cargando = false;
  bool _cargado = false;
  Timer? _timer;

  List<NotificacionItem> get items => _items;
  int get noLeidas => _noLeidas;
  bool get cargando => _cargando;

  // Llamada por ProxyProvider al autenticarse — solo ejecuta si no ha cargado ya
  Future<void> cargar() async {
    if (_cargado || _cargando) return;
    await _cargarInterno();
  }

  Future<void> _cargarInterno() async {
    _cargando = true;
    notifyListeners();
    try {
      _items = await _service.listar();
      _noLeidas = _items.where((n) => !n.leida).length;
      _cargado = true;
    } catch (_) {
      _items = [];
      _noLeidas = 0;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Polling cada 30 s — llamar al autenticarse
  void iniciarPolling() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _cargarInterno());
  }

  // Llamar al cerrar sesión — limpia estado y para el timer
  void detenerPolling() {
    _timer?.cancel();
    _timer = null;
    _cargado = false;
    _items = [];
    _noLeidas = 0;
    notifyListeners();
  }

  Future<void> marcarLeida(int id) async {
    try {
      await _service.marcarLeida(id);
      _items = _items.map((n) => n.id == id
          ? NotificacionItem(
              id: n.id,
              tipo: n.tipo,
              mensaje: n.mensaje,
              leida: true,
              fechaCreacion: n.fechaCreacion)
          : n).toList();
      _noLeidas = _items.where((n) => !n.leida).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marcarTodasLeidas() async {
    try {
      await _service.marcarTodasLeidas();
      _items = _items.map((n) => NotificacionItem(
              id: n.id,
              tipo: n.tipo,
              mensaje: n.mensaje,
              leida: true,
              fechaCreacion: n.fechaCreacion))
          .toList();
      _noLeidas = 0;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
