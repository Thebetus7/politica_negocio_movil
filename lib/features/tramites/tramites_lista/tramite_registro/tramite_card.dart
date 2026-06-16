import 'package:flutter/material.dart';

import '../../../../core/models/tramite_vista.dart';

class TramiteCard extends StatelessWidget {
  final TramiteVista tramite;
  final VoidCallback? onTap;

  const TramiteCard({super.key, required this.tramite, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tramite;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
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
              if (onTap != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Toca para ver historial de actividades',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
