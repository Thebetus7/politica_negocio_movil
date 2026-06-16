import 'package:flutter/material.dart';

import '../../core/models/politica_movil.dart';
import '../../core/models/portafolio_movil.dart';
import '../../core/models/tramite_progreso.dart';
import '../../core/models/tramite_vista.dart';
import '../../core/models/user_session.dart';
import '../../core/network/api_client.dart';
import '../../core/network/tramite_socket_service.dart';
import 'nuevo_tramite/nuevo_tramite_button.dart';
import 'tramites_lista/tramite_registro/tramite_progreso_modal.dart';
import 'tramites_lista/tramites_lista.dart';

class TramitesScreen extends StatefulWidget {
  final UserSession session;
  final List<PoliticaMovil> politicas;

  const TramitesScreen({
    super.key,
    required this.session,
    required this.politicas,
  });

  @override
  State<TramitesScreen> createState() => _TramitesScreenState();
}

class _TramitesScreenState extends State<TramitesScreen> {
  final ApiClient _apiClient = ApiClient();
  final TramiteSocketService _socketService = TramiteSocketService();
  bool _isLoading = true;
  String _error = '';
  List<TramiteVista> _tramites = [];

  @override
  void initState() {
    super.initState();
    _loadTramites();
    _socketService.connect();
    _socketService.portafoliosStream.listen((_) {
      if (mounted) _loadTramites(showLoading: false);
    });
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  void _abrirProgreso(TramiteVista tramite) {
    showDialog(
      context: context,
      builder: (_) => TramiteProgresoModal(
        tramite: tramite,
        socketService: _socketService,
      ),
    );
  }

  Future<List<PoliticaMovil>> _fetchPoliticas() async {
    final response = await _apiClient.dio.get('/politicas/public');
    final raw = (response.data as List).cast<dynamic>();
    return raw
        .map((e) => PoliticaMovil.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<TramiteProgreso?> _fetchProgreso(String portafolioId) async {
    try {
      final res = await _apiClient.dio.get('/portafolios/$portafolioId/progreso');
      return TramiteProgreso.fromJson((res.data as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadTramites({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final politicas = await _fetchPoliticas();

      final portRes = await _apiClient.dio.get('/portafolios');
      final allPorts = (portRes.data as List)
          .map((e) => PortafolioMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final list = <TramiteVista>[];
      for (final p in allPorts) {
        if (p.politicaId == null) continue;

        final progresoDto = await _fetchProgreso(p.id);
        final polName = progresoDto?.politicaNombre ??
            politicas
                .firstWhere(
                  (pol) => pol.id == p.politicaId,
                  orElse: () => const PoliticaMovil(id: '', nombre: 'Desconocida'),
                )
                .nombre;

        list.add(TramiteVista(
          portafolio: p,
          politicaNombre: polName,
          progreso: progresoDto?.progreso ?? 0,
          pasos: const [],
        ));
      }

      if (mounted) {
        setState(() => _tramites = list.reversed.toList());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar los trámites');
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onTramiteCreado(bool _) async {
    await _loadTramites(showLoading: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trámite creado exitosamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tramites.isEmpty && _error.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty && _tramites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTramites, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            NuevoTramiteButton(
              apiClient: _apiClient,
              session: widget.session,
              fetchPoliticas: _fetchPoliticas,
              onCreated: _onTramiteCreado,
            ),
            Expanded(
              child: TramitesLista(
                tramites: _tramites,
                onTramiteTap: _abrirProgreso,
              ),
            ),
          ],
        ),
        if (_isLoading)
          const Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}
