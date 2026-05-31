import 'portafolio_movil.dart';
import 'tramite_paso_item.dart';

class TramiteVista {
  final PortafolioMovil portafolio;
  final String politicaNombre;
  final double progreso;
  final List<TramitePasoItem> pasos;

  const TramiteVista({
    required this.portafolio,
    required this.politicaNombre,
    required this.progreso,
    required this.pasos,
  });
}
