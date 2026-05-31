class PortafolioMovil {
  final String id;
  final String? politicaId;
  final String? jsonInfo;

  const PortafolioMovil({required this.id, this.politicaId, this.jsonInfo});

  factory PortafolioMovil.fromJson(Map<String, dynamic> json) {
    return PortafolioMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      politicaId: json['politicaId']?.toString(),
      jsonInfo: json['json']?.toString(),
    );
  }
}
