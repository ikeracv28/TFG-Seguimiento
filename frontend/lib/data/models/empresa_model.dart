class EmpresaModel {
  final int id;
  final String nombre;
  final String? cif;

  EmpresaModel({required this.id, required this.nombre, this.cif});

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      cif: json['cif'] as String?,
    );
  }
}
