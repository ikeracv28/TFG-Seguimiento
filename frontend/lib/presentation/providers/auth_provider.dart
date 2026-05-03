import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/auth_models.dart';

/**
 * Gestor de estado para la autenticación en toda la app.
 * Notifica a los widgets cuando el usuario inicia o cierra sesión.
 */
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  /**
   * Intenta iniciar sesión y actualiza el estado global.
   */
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /**
   * Cierra la sesión y limpia el estado.
   */
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
