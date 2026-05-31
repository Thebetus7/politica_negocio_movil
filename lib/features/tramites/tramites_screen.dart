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

  @override
  void initState() {
    super.initState();
    _loadTramites();
  }

  Future<void> _loadTramites() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final portRes = await _apiClient.dio.get('/portafolios');
      final allPorts = (portRes.data as List)
          .map((e) => PortafolioMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final list = <TramiteVista>[];
      for (final p in allPorts) {
        if (p.politicaId == null) continue;
        final polName = widget.politicas
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _crearNuevoTramite() async {
    final txtController = TextEditingController();
    String? selectedPolId = widget.politicas.isNotEmpty ? widget.politicas.first.id : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Nuevo Trámite'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: txtController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Información (JSON o texto)',
                        hintText: 'Ej: Carnet, Nota, etc.',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Seleccione la Política de Negocio:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedPolId,
                      items: widget.politicas
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setStateModal(() => selectedPolId = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedPolId != null) {
      setState(() => _isLoading = true);
      try {
        await _apiClient.dio.post('/portafolios', data: {
          'politicaId': selectedPolId,
          'creadorId': widget.session.id,
          'estado': 'en_progreso',
          'json': txtController.text,
        });
        await _loadTramites();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trámite creado exitosamente')),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creando trámite')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
                onPressed: _isLoading ? null : _crearNuevoTramite,
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
