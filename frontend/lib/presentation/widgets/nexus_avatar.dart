import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/foto_cache.dart';
import '../../data/services/usuario_service.dart';

/// Avatar circular que muestra la foto de perfil del usuario si existe,
/// o sus iniciales como fallback. Gestiona descarga y caché automáticamente.
class NexusAvatar extends StatefulWidget {
  final int userId;
  final String nombre;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const NexusAvatar({
    super.key,
    required this.userId,
    required this.nombre,
    this.radius = 16,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<NexusAvatar> createState() => _NexusAvatarState();
}

class _NexusAvatarState extends State<NexusAvatar> {
  final _service = UsuarioService();
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    FotoCache.notifier.addListener(_onCacheUpdate);
    _fetchIfNeeded();
  }

  @override
  void didUpdateWidget(NexusAvatar old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _fetchIfNeeded();
    }
  }

  @override
  void dispose() {
    FotoCache.notifier.removeListener(_onCacheUpdate);
    super.dispose();
  }

  void _onCacheUpdate() {
    // Si se invalidó este userId, volvemos a buscar
    if (!FotoCache.has(widget.userId) && !_fetching) {
      _fetchIfNeeded();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchIfNeeded() async {
    if (FotoCache.has(widget.userId) || _fetching) return;
    _fetching = true;
    try {
      final bytes = await _service.downloadFoto(widget.userId);
      FotoCache.set(widget.userId, bytes);
    } catch (_) {
      // Sin foto — guardamos null para no reintentar
      FotoCache.set(widget.userId, null);
    } finally {
      _fetching = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = FotoCache.get(widget.userId);
    final bg = widget.backgroundColor ?? NexusColors.primaryLight;
    final fg = widget.textColor ?? NexusColors.primaryText;
    final initials = _initials(widget.nombre);
    final fontSize = (widget.radius * 0.7).clamp(10.0, 18.0);

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bg,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            )
          : null,
    );
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
