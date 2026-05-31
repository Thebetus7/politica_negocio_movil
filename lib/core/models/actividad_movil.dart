class ActividadMovil {
  final String id;
  final String nombre;
  final String? politicaId;
  final String? departamentoId;
  final String? formUpdateId;

  const ActividadMovil({
    required this.id,
    required this.nombre,
    this.politicaId,
    this.departamentoId,
    this.formUpdateId,
  });

  factory ActividadMovil.fromJson(Map<String, dynamic> json) {
    return ActividadMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Actividad').toString(),
      politicaId: json['politicaId']?.toString(),
      departamentoId: json['departamentoId']?.toString(),
      formUpdateId: json['formUpdateId']?.toString(),
    );
  }
}
