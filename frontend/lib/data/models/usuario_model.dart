class UsuarioModel {
  final int id;
  final String dni;
  final String nombre;
  final String apellidos;
  final String email;
  final List<String> roles;
  final String? centroNombre;
  final bool activo;

  UsuarioModel({
    required this.id,
    required this.dni,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.roles,
    this.centroNombre,
    required this.activo,
  });

  String get nombreCompleto => '$nombre $apellidos';

  String get rolPrincipal {
    if (roles.contains('ROLE_ADMIN')) return 'Admin';
    if (roles.contains('ROLE_TUTOR_CENTRO')) return 'Tutor Centro';
    if (roles.contains('ROLE_TUTOR_EMPRESA')) return 'Tutor Empresa';
    if (roles.contains('ROLE_ALUMNO')) return 'Alumno';
    return 'Sin rol';
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int,
      dni: json['dni'] as String,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] as List),
      centroNombre: json['centroNombre'] as String?,
      activo: json['activo'] as bool,
    );
  }
}
