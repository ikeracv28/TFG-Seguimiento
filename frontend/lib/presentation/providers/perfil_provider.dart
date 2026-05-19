import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/utils/foto_cache.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/usuario_service.dart';

class PerfilProvider extends ChangeNotifier {
  final UsuarioService _service = UsuarioService();

  User? _usuario;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  String? _successMsg;

  User? get usuario => _usuario;
  // Foto viene del cache global para que todos los NexusAvatar se sincronicen
  Uint8List? get fotoBytes =>
      _usuario != null ? FotoCache.get(_usuario!.id) : null;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  String? get successMsg => _successMsg;

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await _service.getMe();
      // Si tiene foto y no está en cache, la descargamos
      if (_usuario!.tieneFoto && !FotoCache.has(_usuario!.id)) {
        try {
          final bytes = await _service.downloadFoto(_usuario!.id);
          FotoCache.set(_usuario!.id, bytes);
        } catch (_) {
          FotoCache.set(_usuario!.id, null);
        }
      } else if (!_usuario!.tieneFoto) {
        FotoCache.set(_usuario!.id, null);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarYSubirFoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final mimeType = _mimeFromExtension(file.extension ?? '');

    _isUploading = true;
    _error = null;
    _successMsg = null;
    notifyListeners();

    try {
      await _service.uploadFoto(
        bytes: file.bytes!,
        filename: file.name,
        mimeType: mimeType,
      );
      // Actualizar cache global — todos los NexusAvatar con este userId se refrescan
      FotoCache.set(_usuario!.id, file.bytes!);
      _usuario = _usuario?.copyWith(tieneFoto: true);
      _successMsg = 'Foto actualizada correctamente';
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void reset() {
    if (_usuario != null) FotoCache.invalidate(_usuario!.id);
    _usuario = null;
    _error = null;
    _successMsg = null;
  }

  void clearMessages() {
    _error = null;
    _successMsg = null;
    notifyListeners();
  }

  String _mimeFromExtension(String ext) {
    return switch (ext.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
