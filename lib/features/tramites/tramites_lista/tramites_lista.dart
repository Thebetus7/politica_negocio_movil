import 'package:flutter/material.dart';

import '../../../core/models/tramite_vista.dart';
import 'tramite_registro/tramite_card.dart';

class TramitesLista extends StatelessWidget {
  final List<TramiteVista> tramites;
  final ValueChanged<TramiteVista> onTramiteTap;

  const TramitesLista({
    super.key,
    required this.tramites,
    required this.onTramiteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tramites.isEmpty) {
      return const Center(child: Text('No hay trámites en progreso'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tramites.length,
      itemBuilder: (ctx, i) => TramiteCard(
        tramite: tramites[i],
        onTap: () => onTramiteTap(tramites[i]),
      ),
    );
  }
}
