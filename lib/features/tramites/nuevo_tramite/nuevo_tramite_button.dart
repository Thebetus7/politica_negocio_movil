import 'package:flutter/material.dart';

import '../../../core/models/politica_movil.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import 'nuevo_tramite_modal.dart';

class NuevoTramiteButton extends StatelessWidget {
  final ApiClient apiClient;
  final UserSession session;
  final Future<List<PoliticaMovil>> Function() fetchPoliticas;
  final ValueChanged<bool> onCreated;

  const NuevoTramiteButton({
    super.key,
    required this.apiClient,
    required this.session,
    required this.fetchPoliticas,
    required this.onCreated,
  });

  Future<void> _abrirModal(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NuevoTramiteModal(
        apiClient: apiClient,
        session: session,
        fetchPoliticas: fetchPoliticas,
      ),
    );

    if (created == true) {
      onCreated(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () => _abrirModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Trámite (Portafolio)'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
