import 'package:flutter/material.dart';

import '../../core/models/actividad_funcionario_pendiente.dart';
import '../../core/models/actividad_movil.dart';
import '../../core/models/flujo_movil.dart';
import '../../core/models/portafolio_movil.dart';
import '../../core/models/user_session.dart';
import '../../core/network/api_client.dart';

class ActividadesScreen extends StatefulWidget {
  final UserSession session;

  const ActividadesScreen({super.key, required this.session});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _error = '';
  List<ActividadFuncionarioPendiente> _pendientes = [];

  @override
  void initState() {
    super.initState();
    _loadActividades();
  }

  Future<void> _loadActividades() async {
    if (widget.session.id.isEmpty) {
      setState(() {
        _isLoading = false;
        _pendientes = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final depasRes = await _apiClient.dio.get('/funcionarios-depa/usuario/${widget.session.id}');
      final depaIds = (depasRes.data as List)
          .map((e) => ((e as Map).cast<String, dynamic>())['departamentoId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final portRes = await _apiClient.dio.get('/portafolios');
      final allPorts = (portRes.data as List)
          .map((e) => PortafolioMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final pendientes = <ActividadFuncionarioPendiente>[];

      for (final p in allPorts) {
        if (p.politicaId == null) continue;
        final fRes = await _apiClient.dio.get('/politicas/${p.politicaId}/flujos?portafolioId=${p.id}');
        final flujosInstancia = (fRes.data as List)
            .map((e) => FlujoMovil.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

        final actsRes = await _apiClient.dio.get('/politicas/${p.politicaId}/actividades');
        final actsPlantilla = (actsRes.data as List)
            .map((e) => ActividadMovil.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        final actsById = {for (final a in actsPlantilla) a.id: a};

        for (final f in flujosInstancia) {
          final estado = f.proceso['estadoActual']?.toString() ?? 'pendiente';
          if (estado == 'en_progreso') {
            final act = actsById[f.actividadId];
            if (act != null && depaIds.contains(act.departamentoId)) {
              pendientes.add(ActividadFuncionarioPendiente(
                actividad: act,
                portafolio: p,
                flujoInstanciaId: f.id,
              ));
            }
          }
        }
      }

      if (mounted) {
        setState(() => _pendientes = pendientes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar las actividades');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completarActividad(ActividadFuncionarioPendiente item) async {
    final controller = TextEditingController();
    final payload = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Completar ${item.actividad.nombre}'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ingresa observaciones / resultado',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (payload == null) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.dio.post('/form-updates', data: {
        'contenidoUpdate': payload,
        'actividadId': item.actividad.id,
        'formularioId': '',
        'portafolioId': item.portafolio.id,
      });

      await _avanzarFlujoInstancia(item);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad completada exitosamente')),
      );
      await _loadActividades();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la actividad')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _avanzarFlujoInstancia(ActividadFuncionarioPendiente item) async {
    final politicaId = item.portafolio.politicaId;
    final portafolioId = item.portafolio.id;
    if (politicaId == null || politicaId.isEmpty) return;

    final res = await _apiClient.dio.get('/politicas/$politicaId/flujos?portafolioId=$portafolioId');
    final flujosInstancia = (res.data as List)
        .map((e) => FlujoMovil.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    FlujoMovil? actual;
    for (final f in flujosInstancia) {
      if (f.id == item.flujoInstanciaId) {
        actual = f;
        break;
      }
    }
    if (actual == null) return;

    final procesoActual = Map<String, dynamic>.from(actual.proceso);
    procesoActual['estadoActual'] = 'completado';
    await _apiClient.dio.put(
      '/politicas/$politicaId/flujos/${actual.id}',
      data: {'actividadId': actual.actividadId, 'proceso': procesoActual},
    );

    final siguientes = (procesoActual['siguientes'] as List?) ?? const [];
    for (final s in siguientes) {
      final destinoId = (s as Map)['actividadDestinoId']?.toString();
      if (destinoId == null || destinoId.isEmpty) continue;
      FlujoMovil? destino;
      for (final f in flujosInstancia) {
        if (f.actividadId == destinoId) {
          destino = f;
          break;
        }
      }
      if (destino == null) continue;
      final procesoDestino = Map<String, dynamic>.from(destino.proceso);
      if ((procesoDestino['estadoActual'] ?? 'pendiente') != 'completado') {
        procesoDestino['estadoActual'] = 'en_progreso';
        await _apiClient.dio.put(
          '/politicas/$politicaId/flujos/${destino.id}',
          data: {'actividadId': destino.actividadId, 'proceso': procesoDestino},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _pendientes.isEmpty && _error.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty && _pendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadActividades, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_pendientes.isEmpty) {
      return const Center(
        child: Text('No hay actividades asignadas a tu departamento'),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          itemCount: _pendientes.length,
          itemBuilder: (context, index) {
            final item = _pendientes[index];
            final act = item.actividad;
            final pId = item.portafolio.id;
            final shortId = pId.length > 4 ? pId.substring(pId.length - 4) : pId;

            return ListTile(
              title: Text(act.nombre),
              subtitle: Text('Trámite: $shortId | Depa: ${act.departamentoId ?? "-"}'),
              trailing: ElevatedButton(
                onPressed: _isLoading ? null : () => _completarActividad(item),
                child: const Text('Completar'),
              ),
            );
          },
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
