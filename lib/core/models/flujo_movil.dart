class FlujoMovil {
  final String id;
  final String actividadId;
  final Map<String, dynamic> proceso;

  const FlujoMovil({required this.id, required this.actividadId, required this.proceso});

  factory FlujoMovil.fromJson(Map<String, dynamic> json) {
    return FlujoMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      actividadId: (json['actividadId'] ?? '').toString(),
      proceso: ((json['proceso'] as Map?) ?? {}).cast<String, dynamic>(),
    );
  }
}
