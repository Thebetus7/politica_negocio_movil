import 'package:flutter/material.dart';

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
  List<Map<String, dynamic>> _tareas = [];

  @override
  void initState() {
    super.initState();
    _loadActividades();
  }

  Future<void> _loadActividades() async {
    if (widget.session.id.isEmpty) {
      setState(() {
        _isLoading = false;
        _tareas = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final res = await _apiClient.dio.get('/funcionarios/${widget.session.id}/tareas');
      if (mounted) {
        setState(() {
          _tareas = (res.data as List)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
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

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Text(
            'Vista de solo lectura. Completa las actividades desde la web en /tareas.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: _tareas.isEmpty
              ? const Center(child: Text('No hay actividades asignadas a tu departamento'))
              : ListView.builder(
                  itemCount: _tareas.length,
                  itemBuilder: (context, index) {
                    final t = _tareas[index];
                    final pId = (t['portafolioId'] ?? '').toString();
                    final shortId = pId.length > 4 ? pId.substring(pId.length - 4) : pId;

                    return ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text((t['actividadNombre'] ?? 'Actividad').toString()),
                      subtitle: Text(
                        'Trámite: $shortId | Tipo: ${t['tipoNodo'] ?? '-'}',
                      ),
                      trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
