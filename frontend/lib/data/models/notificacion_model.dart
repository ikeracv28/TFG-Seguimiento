class NotificacionItem {
  final int id;
  final String tipo;
  final String mensaje;
  final bool leida;
  final DateTime fechaCreacion;

  const NotificacionItem({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    required this.fechaCreacion,
  });

  factory NotificacionItem.fromJson(Map<String, dynamic> j) => NotificacionItem(
        id: j['id'],
        tipo: j['tipo'] ?? '',
        mensaje: j['mensaje'],
        leida: j['leida'] ?? false,
        fechaCreacion: DateTime.parse(j['fechaCreacion']),
      );
}
