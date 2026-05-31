class PoliticaMovil {
  final String id;
  final String nombre;

  const PoliticaMovil({required this.id, required this.nombre});

  factory PoliticaMovil.fromJson(Map<String, dynamic> json) {
    return PoliticaMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Sin nombre').toString(),
    );
  }
}
