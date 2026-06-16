import 'package:flutter/material.dart';

import '../../../../core/models/tramite_progreso.dart';
import '../../../../core/models/tramite_vista.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/tramite_socket_service.dart';

class TramiteProgresoModal extends StatefulWidget {
  final TramiteVista tramite;
  final TramiteSocketService socketService;

  const TramiteProgresoModal({
    super.key,
    required this.tramite,
    required this.socketService,
  });

  @override
  State<TramiteProgresoModal> createState() => _TramiteProgresoModalState();
}

class _TramiteProgresoModalState extends State<TramiteProgresoModal> {
  final ApiClient _apiClient = ApiClient();
  TramiteProgreso? _progreso;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProgreso();
    widget.socketService.subscribePortafolio(widget.tramite.portafolio.id);
    widget.socketService.portafolioStream(widget.tramite.portafolio.id).listen((_) {
      _loadProgreso(silent: true);
    });
  }

  Future<void> _loadProgreso({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final res = await _apiClient.dio.get('/portafolios/${widget.tramite.portafolio.id}/progreso');
      if (!mounted) return;
      setState(() {
        _progreso = TramiteProgreso.fromJson((res.data as Map).cast<String, dynamic>());
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el progreso';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.maxFinite,
          child: _loading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando progreso...'),
                  ],
                )
              : _error.isNotEmpty
                  ? Text(_error, textAlign: TextAlign.center)
                  : _buildContent(_progreso!),
        ),
      ),
    );
  }

  ({IconData icon, Color color, double opacity}) _estiloPaso(TramitePasoProgreso paso) {
    if (paso.ramaVisual == 'no_tomada' || paso.estado == 'omitido') {
      return (icon: Icons.block, color: Colors.grey, opacity: 0.45);
    }

    switch (paso.estado) {
      case 'completado':
        if (paso.tipoNodo == 'decision') {
          return (icon: Icons.call_split, color: Colors.deepPurple, opacity: 1);
        }
        if (paso.tipoNodo == 'pregunta') {
          return (icon: Icons.psychology, color: Colors.amber.shade800, opacity: 1);
        }
        return (icon: Icons.check_circle, color: Colors.green, opacity: 1);
      case 'en_progreso':
        return (icon: Icons.play_circle, color: Colors.blue, opacity: 1);
      default:
        return (icon: Icons.radio_button_unchecked, color: Colors.grey, opacity: 1);
    }
  }

  Widget _buildContent(TramiteProgreso p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                p.politicaNombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        Text('Trámite: ...${p.portafolioId.substring(p.portafolioId.length - 6)}'),
        if (p.creadorId != null) Text('Creador: ${p.creadorId}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p.progreso,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(p.progreso >= 1.0 ? Colors.green : Colors.blue),
          ),
        ),
        Text('${(p.progreso * 100).toStringAsFixed(0)}% completado'),
        const SizedBox(height: 16),
        const Text('Historial de actividades', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: p.pasos.length,
            itemBuilder: (ctx, i) {
              final paso = p.pasos[i];
              final estilo = _estiloPaso(paso);
              return Opacity(
                opacity: estilo.opacity,
                child: ListTile(
                  dense: true,
                  leading: Icon(estilo.icon, color: estilo.color, size: 20),
                  title: Text(
                    paso.nombre,
                    style: TextStyle(
                      color: estilo.color,
                      decoration: paso.estado == 'completado' &&
                              paso.tipoNodo == 'actividad' &&
                              paso.ramaVisual != 'no_tomada'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
