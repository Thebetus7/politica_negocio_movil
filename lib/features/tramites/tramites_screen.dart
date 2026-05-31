import 'package:flutter/material.dart';

import '../../core/models/actividad_movil.dart';
import '../../core/models/flujo_movil.dart';
import '../../core/models/politica_movil.dart';
import '../../core/models/portafolio_movil.dart';
import '../../core/models/tramite_paso_item.dart';
import '../../core/models/tramite_vista.dart';
import '../../core/models/user_session.dart';
import '../../core/network/api_client.dart';
import 'widgets/tramite_card.dart';

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
  bool _isLoading = true;
  String _error = '';
  List<TramiteVista> _tramites = [];
  List<PoliticaMovil> _politicas = [];

  @override
  void initState() {
    super.initState();
    _politicas = List.from(widget.politicas);
    _loadTramites();
  }

  Future<List<PoliticaMovil>> _fetchPoliticas() async {
    final response = await _apiClient.dio.get('/politicas/public');
    final raw = (response.data as List).cast<dynamic>();
    return raw
        .map((e) => PoliticaMovil.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
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
      if (mounted) {
        setState(() => _politicas = politicas);
      }

      final portRes = await _apiClient.dio.get('/portafolios');
      final allPorts = (portRes.data as List)
          .map((e) => PortafolioMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final list = <TramiteVista>[];
      for (final p in allPorts) {
        if (p.politicaId == null) continue;
        final polName = politicas
            .firstWhere(
              (pol) => pol.id == p.politicaId,
              orElse: () => const PoliticaMovil(id: '', nombre: 'Desconocida'),
            )
            .nombre;

        final fRes = await _apiClient.dio.get('/politicas/${p.politicaId}/flujos?portafolioId=${p.id}');
        final flujos = (fRes.data as List)
            .map((e) => FlujoMovil.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

        final actsRes = await _apiClient.dio.get('/politicas/${p.politicaId}/actividades');
        final acts = (actsRes.data as List)
            .map((e) => ActividadMovil.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        final actsById = {for (final a in acts) a.id: a};

        var completedCount = 0;
        final pasos = <TramitePasoItem>[];

        flujos.sort((a, b) {
          final oa = (a.proceso['orden'] as num?)?.toInt() ?? 999;
          final ob = (b.proceso['orden'] as num?)?.toInt() ?? 999;
          return oa.compareTo(ob);
        });

        for (final f in flujos) {
          final estado = f.proceso['estadoActual']?.toString() ?? 'pendiente';
          if (estado == 'completado') completedCount++;
          final act = actsById[f.actividadId];
          if (act != null) {
            pasos.add(TramitePasoItem(actividad: act, estado: estado));
          }
        }

        final progreso = flujos.isEmpty ? 0.0 : completedCount / flujos.length;

        list.add(TramiteVista(
          portafolio: p,
          politicaNombre: polName,
          progreso: progreso,
          pasos: pasos,
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

  Future<void> _crearNuevoTramite() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NuevoTramiteDialog(
        apiClient: _apiClient,
        session: widget.session,
        fetchPoliticas: _fetchPoliticas,
      ),
    );

    if (created == true && mounted) {
      await _loadTramites(showLoading: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trámite creado exitosamente')),
      );
    }
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _crearNuevoTramite,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Trámite (Portafolio)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: _tramites.isEmpty
                  ? const Center(child: Text('No hay trámites en progreso'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _tramites.length,
                      itemBuilder: (ctx, i) => TramiteCard(tramite: _tramites[i]),
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

class _NuevoTramiteDialog extends StatefulWidget {
  final ApiClient apiClient;
  final UserSession session;
  final Future<List<PoliticaMovil>> Function() fetchPoliticas;

  const _NuevoTramiteDialog({
    required this.apiClient,
    required this.session,
    required this.fetchPoliticas,
  });

  @override
  State<_NuevoTramiteDialog> createState() => _NuevoTramiteDialogState();
}

class _NuevoTramiteDialogState extends State<_NuevoTramiteDialog> {
  final _txtController = TextEditingController();
  bool _loadingPoliticas = true;
  bool _submitting = false;
  String? _loadError;
  List<PoliticaMovil> _politicas = [];
  String? _selectedPolId;

  @override
  void initState() {
    super.initState();
    _reloadPoliticas();
  }

  @override
  void dispose() {
    _txtController.dispose();
    super.dispose();
  }

  Future<void> _reloadPoliticas() async {
    setState(() {
      _loadingPoliticas = true;
      _loadError = null;
    });
    try {
      final politicas = await widget.fetchPoliticas();
      if (!mounted) return;
      setState(() {
        _politicas = politicas;
        _selectedPolId = politicas.isNotEmpty ? politicas.first.id : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'No se pudieron cargar las políticas de negocio');
    } finally {
      if (mounted) setState(() => _loadingPoliticas = false);
    }
  }

  Future<void> _crear() async {
    final selectedPolId = _selectedPolId;
    if (selectedPolId == null) return;

    setState(() => _submitting = true);
    try {
      await widget.apiClient.dio.post('/portafolios', data: {
        'politicaId': selectedPolId,
        'creadorId': widget.session.id,
        'estado': 'en_progreso',
        'json': _txtController.text,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creando trámite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingPoliticas || _submitting;

    return AlertDialog(
      title: const Text('Nuevo Trámite'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loadingPoliticas
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando políticas de negocio...'),
                  ],
                ),
              )
            : _loadError != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _reloadPoliticas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _txtController,
                          enabled: !busy,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Información (JSON o texto)',
                            hintText: 'Ej: Carnet, Nota, etc.',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Seleccione la Política de Negocio:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Actualizar políticas',
                              onPressed: busy ? null : _reloadPoliticas,
                              icon: const Icon(Icons.refresh, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedPolId,
                          items: _politicas
                              .map((p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: busy
                              ? null
                              : (val) => setState(() => _selectedPolId = val),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        if (_submitting) ...[
                          const SizedBox(height: 24),
                          const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 8),
                          const Text(
                            'Creando trámite...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: busy || _selectedPolId == null ? null : _crear,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
