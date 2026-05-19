class EmpresaModel {
  final int id;
  final String nombre;
  final String? cif;
  final String? direccion;
  final String? emailContacto;
  final String? telefonoContacto;

  EmpresaModel({
    required this.id,
    required this.nombre,
    this.cif,
    this.direccion,
    this.emailContacto,
    this.telefonoContacto,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      cif: json['cif'] as String?,
      direccion: json['direccion'] as String?,
      emailContacto: json['emailContacto'] as String?,
      telefonoContacto: json['telefonoContacto'] as String?,
    );
  }
}
