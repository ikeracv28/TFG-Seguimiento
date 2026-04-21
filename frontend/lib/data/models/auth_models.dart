/**
 * Modelo de Usuario para el Frontend.
 * Representa los datos básicos del perfil del usuario logueado.
 */
class User {
  final int id;
  final String email;
  final String nombreCompleto;
  final List<String> roles;

  User({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      nombreCompleto: json['nombre'] as String,
      roles: List<String>.from(json['roles'] as List),
    );
  }
}

/**
 * Representa la respuesta exitosa del servidor tras un Login/Registro.
 */
class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json),
    );
  }
}
