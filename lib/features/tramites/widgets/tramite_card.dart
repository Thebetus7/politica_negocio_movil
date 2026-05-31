import 'package:flutter/material.dart';

import '../../../core/models/tramite_vista.dart';

class TramiteCard extends StatelessWidget {
  final TramiteVista tramite;

  const TramiteCard({super.key, required this.tramite});

  @override
  Widget build(BuildContext context) {
    final t = tramite;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.politicaNombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.progreso >= 1.0 ? Colors.green.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t.progreso >= 1.0 ? 'Completado' : 'En curso',
                    style: TextStyle(
                      color: t.progreso >= 1.0 ? Colors.green.shade800 : Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID Trámite: ${t.portafolio.id.substring(t.portafolio.id.length - 6)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (t.portafolio.jsonInfo != null && t.portafolio.jsonInfo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Info: ${t.portafolio.jsonInfo}',
                  style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: t.progreso,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  t.progreso >= 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(t.progreso * 100).toStringAsFixed(0)}% Completado',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('Historial de Actividades:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...t.pasos.map((p) {
              IconData icon;
              Color color;
              if (p.estado == 'completado') {
                icon = Icons.check_circle;
                color = Colors.green;
              } else if (p.estado == 'en_progreso') {
                icon = Icons.play_circle_filled;
                color = Colors.blue;
              } else {
                icon = Icons.radio_button_unchecked;
                color = Colors.grey;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.actividad.nombre,
                        style: TextStyle(
                          color: color,
                          decoration: p.estado == 'completado' ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (p.estado == 'completado')
                      const Text('Resuelta', style: TextStyle(fontSize: 10, color: Colors.green)),
                    if (p.estado == 'en_progreso')
                      const Text('Siguiente', style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
