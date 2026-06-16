import 'package:flutter/material.dart';

import '../../../core/models/politica_movil.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';

class NuevoTramiteModal extends StatefulWidget {
  final ApiClient apiClient;
  final UserSession session;
  final Future<List<PoliticaMovil>> Function() fetchPoliticas;

  const NuevoTramiteModal({
    super.key,
    required this.apiClient,
    required this.session,
    required this.fetchPoliticas,
  });

  @override
  State<NuevoTramiteModal> createState() => _NuevoTramiteModalState();
}

class _NuevoTramiteModalState extends State<NuevoTramiteModal> {
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

    if (_txtController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese los datos de inicio del portafolio')),
      );
      return;
    }

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
                            labelText: 'Datos de inicio (revisión del portafolio)',
                            hintText: 'Ej: Carnet, Nota, datos del cliente...',
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
