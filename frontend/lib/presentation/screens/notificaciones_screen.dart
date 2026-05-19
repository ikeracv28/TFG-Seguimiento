import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/notificacion_provider.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacionProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nxt = context.nxt;
    return Scaffold(
      backgroundColor: nxt.surfaceAlt,
      appBar: AppBar(
        backgroundColor: nxt.surface,
        foregroundColor: nxt.ink,
        elevation: 0,
        title: Text('Notificaciones',
            style: NexusText.heading3.copyWith(color: nxt.ink)),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificacionProvider>().marcarTodasLeidas(),
            child: Text('Leer todas',
                style: NexusText.small.copyWith(color: NexusColors.primary)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: nxt.border),
        ),
      ),
      body: Consumer<NotificacionProvider>(
        builder: (context, prov, _) {
          if (prov.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 48, color: nxt.inkTertiary),
                  const SizedBox(height: NexusSizes.spaceMD),
                  Text('Sin notificaciones',
                      style: NexusText.small.copyWith(color: nxt.inkSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: prov.items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: nxt.border),
            itemBuilder: (context, index) {
              final n = prov.items[index];
              return _NotificacionTile(item: n, onTap: () => prov.marcarLeida(n.id));
            },
          );
        },
      ),
    );
  }
}

class _NotificacionTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _NotificacionTile({required this.item, required this.onTap});

  IconData _iconForTipo(String tipo) {
    return switch (tipo.toUpperCase()) {
      'CHAT' => Icons.chat_bubble_outline,
      'SEGUIMIENTO' => Icons.assignment_outlined,
      'INCIDENCIA' => Icons.warning_amber_outlined,
      _ => Icons.notifications_none_outlined,
    };
  }

  Color _colorForTipo(String tipo) {
    return switch (tipo.toUpperCase()) {
      'CHAT' => NexusColors.primary,
      'SEGUIMIENTO' => NexusColors.success,
      'INCIDENCIA' => NexusColors.warning,
      _ => NexusColors.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final nxt = context.nxt;
    final color = _colorForTipo(item.tipo);
    final fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(item.fechaCreacion.toLocal());

    return InkWell(
      onTap: item.leida ? null : onTap,
      child: Container(
        color: item.leida ? Colors.transparent : NexusColors.primaryLight.withAlpha(90),
        padding: const EdgeInsets.symmetric(
            horizontal: NexusSizes.spaceLG, vertical: NexusSizes.spaceMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForTipo(item.tipo), size: 18, color: color),
            ),
            const SizedBox(width: NexusSizes.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.mensaje,
                      style: NexusText.small.copyWith(
                          color: nxt.ink,
                          fontWeight: item.leida ? FontWeight.w400 : FontWeight.w600)),
                  const SizedBox(height: NexusSizes.spaceXS),
                  Text(fechaStr,
                      style: NexusText.caption.copyWith(color: nxt.inkTertiary)),
                ],
              ),
            ),
            if (!item.leida)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                    color: NexusColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
