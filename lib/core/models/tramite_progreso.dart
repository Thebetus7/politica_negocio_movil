class TramitePasoProgreso {
  final String actividadId;
  final String nombre;
  final String tipoNodo;
  final String estado;
  final String? formularioId;
  final String? contenidoUpdate;
  final String? updatedAt;
  final String? decisionTomada;
  final String? ramaVisual;

  const TramitePasoProgreso({
    required this.actividadId,
    required this.nombre,
    required this.tipoNodo,
    required this.estado,
    this.formularioId,
    this.contenidoUpdate,
    this.updatedAt,
    this.decisionTomada,
    this.ramaVisual,
  });

  factory TramitePasoProgreso.fromJson(Map<String, dynamic> json) {
    return TramitePasoProgreso(
      actividadId: (json['actividadId'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Actividad').toString(),
      tipoNodo: (json['tipoNodo'] ?? 'actividad').toString(),
      estado: (json['estado'] ?? 'pendiente').toString(),
      formularioId: json['formularioId']?.toString(),
      contenidoUpdate: json['contenidoUpdate']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      decisionTomada: json['decisionTomada']?.toString(),
      ramaVisual: json['ramaVisual']?.toString(),
    );
  }
}

class TramiteProgreso {
  final String portafolioId;
  final String politicaId;
  final String politicaNombre;
  final String? creadorId;
  final String? estado;
  final double progreso;
  final List<TramitePasoProgreso> pasos;

  const TramiteProgreso({
    required this.portafolioId,
    required this.politicaId,
    required this.politicaNombre,
    this.creadorId,
    this.estado,
    required this.progreso,
    required this.pasos,
  });

  factory TramiteProgreso.fromJson(Map<String, dynamic> json) {
    final rawPasos = (json['pasos'] as List?) ?? const [];
    return TramiteProgreso(
      portafolioId: (json['portafolioId'] ?? '').toString(),
      politicaId: (json['politicaId'] ?? '').toString(),
      politicaNombre: (json['politicaNombre'] ?? 'Política').toString(),
      creadorId: json['creadorId']?.toString(),
      estado: json['estado']?.toString(),
      progreso: (json['progreso'] as num?)?.toDouble() ?? 0,
      pasos: rawPasos
          .map((e) => TramitePasoProgreso.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
