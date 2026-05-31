import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  int _currentIndex = 0;
  bool _isLoading = true;
  String _error = '';
  _UserSession? _session;
  List<_PoliticaMovil> _politicas = [];
  String? _selectedPoliticaId;
  List<_ActividadFuncionarioPendiente> _actividadesFuncionarioPendientes = [];
  List<_TramiteVista> _tramitesACliente = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final session = _UserSession(
      id: prefs.getString('user_id') ?? '',
      nombre: prefs.getString('user_nombre') ?? 'Usuario',
      rol: _parseRol(prefs.getString('user_rol')),
    );

    setState(() {
      _session = session;
      _isLoading = true;
      _error = '';
    });

    try {
      await _loadPoliticas();
      if (session.rol == _AppRole.atencionCliente) {
        await _loadTramitesACliente();
      }
      if (session.rol == _AppRole.funcionario && session.id.isNotEmpty) {
        await _loadActividadesFuncionario(session.id);
      }
    } catch (e) {
      setState(() => _error = 'No se pudo cargar información móvil');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _loadPoliticas() async {
    final response = await _apiClient.dio.get('/politicas/public');
    final raw = (response.data as List).cast<dynamic>();
    if (mounted) {
      setState(() {
        _politicas = raw
            .map((e) => _PoliticaMovil.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
    }
  }

  Future<void> _loadTramitesACliente() async {
    final portRes = await _apiClient.dio.get('/portafolios');
    final allPorts = (portRes.data as List)
        .map((e) => _PortafolioMovil.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    List<_TramiteVista> list = [];
    for (final p in allPorts) {
      if (p.politicaId == null) continue;
      final polName = _politicas.firstWhere(
        (pol) => pol.id == p.politicaId,
        orElse: () => _PoliticaMovil(id: '', nombre: 'Desconocida')
      ).nombre;

      final fRes = await _apiClient.dio.get('/politicas/${p.politicaId}/flujos?portafolioId=${p.id}');
      final flujos = (fRes.data as List)
          .map((e) => _FlujoMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final actsRes = await _apiClient.dio.get('/politicas/${p.politicaId}/actividades');
      final acts = (actsRes.data as List)
          .map((e) => _ActividadMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final actsById = {for (final a in acts) a.id: a};

      int completedCount = 0;
      List<_TramitePasoItem> pasos = [];

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
          pasos.add(_TramitePasoItem(actividad: act, estado: estado));
        }
      }

      double progreso = flujos.isEmpty ? 0 : completedCount / flujos.length;

      list.add(_TramiteVista(
        portafolio: p,
        politicaNombre: polName,
        progreso: progreso,
        pasos: pasos,
      ));
    }

    if (mounted) {
      setState(() {
        _tramitesACliente = list.reversed.toList();
      });
    }
  }

  Future<void> _crearNuevoTramite() async {
    final txtController = TextEditingController();
    String? selectedPolId = _politicas.isNotEmpty ? _politicas.first.id : null;

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
                      items: _politicas
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
          }
        );
      }
    );

    if (result == true && selectedPolId != null) {
      setState(() => _isLoading = true);
      try {
        await _apiClient.dio.post('/portafolios', data: {
          'politicaId': selectedPolId,
          'creadorId': _session?.id,
          'estado': 'en_progreso',
          'json': txtController.text,
        });
        await _loadTramitesACliente();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trámite creado exitosamente')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creando trámite')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadActividadesFuncionario(String userId) async {
    final depasRes = await _apiClient.dio.get('/funcionarios-depa/usuario/$userId');
    final depaIds = (depasRes.data as List)
        .map((e) => ((e as Map).cast<String, dynamic>())['departamentoId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    // 1. Cargar portafolios en progreso
    final portRes = await _apiClient.dio.get('/portafolios');
    final allPorts = (portRes.data as List)
        .map((e) => _PortafolioMovil.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final List<_ActividadFuncionarioPendiente> pendientes = [];

    // 2. Por cada portafolio en progreso, buscar flujos pendientes para este depa
    for (final p in allPorts) {
      if (p.politicaId == null) continue;
      final fRes = await _apiClient.dio.get('/politicas/${p.politicaId}/flujos?portafolioId=${p.id}');
      final flujosInstancia = (fRes.data as List)
          .map((e) => _FlujoMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final actsRes = await _apiClient.dio.get('/politicas/${p.politicaId}/actividades');
      final actsPlantilla = (actsRes.data as List)
          .map((e) => _ActividadMovil.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final actsById = {for (final a in actsPlantilla) a.id: a};

      for (final f in flujosInstancia) {
        final estado = f.proceso['estadoActual']?.toString() ?? 'pendiente';
        if (estado == 'en_progreso') {
          final act = actsById[f.actividadId];
          if (act != null && depaIds.contains(act.departamentoId)) {
            pendientes.add(_ActividadFuncionarioPendiente(
              actividad: act,
              portafolio: p,
              flujoInstanciaId: f.id,
            ));
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _actividadesFuncionarioPendientes = pendientes;
      });
    }
  }

  Future<void> _loadTramiteData(String politicaId, {String? portafolioId}) async {
    final actRes = await _apiClient.dio.get('/politicas/$politicaId/actividades');
    final urlFlujos = portafolioId != null 
        ? '/politicas/$politicaId/flujos?portafolioId=$portafolioId' 
        : '/politicas/$politicaId/flujos';
    final flujoRes = await _apiClient.dio.get(urlFlujos);
    
    // Este metodo ya no se usa directamente en la nueva vista de A.C., 
    // pero lo mantenemos por compatibilidad si se llama desde otros lados.
  }

  Widget _buildHomeTab() {
    final session = _session;
    final roleLabel = session == null ? '' : _roleLabel(session.rol);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.0),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: Colors.black),
              const SizedBox(height: 16),
              Text(
                'HOLA, ${(session?.nombre ?? 'USUARIO').toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'ROL: $roleLabel',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completarActividadFuncionario(_ActividadFuncionarioPendiente item) async {
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
            ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Guardar')),
          ],
        );
      },
    );
    if (payload == null) return;

    setState(() => _isLoading = true);

    try {
      final updateBody = {
        'contenidoUpdate': payload,
        'actividadId': item.actividad.id,
        'formularioId': '',
        'portafolioId': item.portafolio.id,
      };
      
      // Creamos siempre uno nuevo ligado a este portafolio/tramite
      await _apiClient.dio.post('/form-updates', data: updateBody);
      
      await _avanzarFlujoInstancia(item);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad completada exitosamente')),
      );
      await _loadActividadesFuncionario(_session?.id ?? '');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la actividad')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _avanzarFlujoInstancia(_ActividadFuncionarioPendiente item) async {
    final politicaId = item.portafolio.politicaId;
    final portafolioId = item.portafolio.id;
    if (politicaId == null || politicaId.isEmpty) return;

    final res = await _apiClient.dio.get('/politicas/$politicaId/flujos?portafolioId=$portafolioId');
    final flujosInstancia = (res.data as List)
        .map((e) => _FlujoMovil.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final actual = flujosInstancia.where((f) => f.id == item.flujoInstanciaId).cast<_FlujoMovil?>().firstWhere(
          (f) => f != null,
          orElse: () => null,
        );
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
      final destino = flujosInstancia.where((f) => f.actividadId == destinoId).cast<_FlujoMovil?>().firstWhere(
            (f) => f != null,
            orElse: () => null,
          );
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

  Widget _buildModernTramiteCard(_TramiteVista t) {
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
            Text('ID Trámite: ${t.portafolio.id.substring(t.portafolio.id.length - 6)}', style: const TextStyle(color: Colors.grey)),
            if (t.portafolio.jsonInfo != null && t.portafolio.jsonInfo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Info: ${t.portafolio.jsonInfo}', style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic)),
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTramiteTab() {
    return Column(
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
          child: _tramitesACliente.isEmpty
              ? const Center(child: Text('No hay trámites en progreso'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _tramitesACliente.length,
                  itemBuilder: (ctx, i) {
                    final t = _tramitesACliente[i];
                    return _buildModernTramiteCard(t);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActividadesTab() {
    if (_actividadesFuncionarioPendientes.isEmpty) {
      return const Center(
        child: Text('No hay actividades asignadas a tu departamento'),
      );
    }
    return ListView.builder(
      itemCount: _actividadesFuncionarioPendientes.length,
      itemBuilder: (context, index) {
        final item = _actividadesFuncionarioPendientes[index];
        final act = item.actividad;
        final pId = item.portafolio.id;
        final shortId = pId.length > 4 ? pId.substring(pId.length - 4) : pId;
        
        return ListTile(
          title: Text(act.nombre),
          subtitle: Text('Trámite: $shortId | Depa: ${act.departamentoId ?? "-"}'),
          trailing: ElevatedButton(
            onPressed: () => _completarActividadFuncionario(item),
            child: const Text('Completar'),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Text(
        'Usuario: ${_session?.nombre ?? "-"}\nID: ${_session?.id ?? "-"}',
        textAlign: TextAlign.center,
      ),
    );
  }

  List<BottomNavigationBarItem> _navItemsForRole(_AppRole role) {
    switch (role) {
      case _AppRole.atencionCliente:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), activeIcon: Icon(Icons.timeline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
        ];
      case _AppRole.funcionario:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
        ];
      case _AppRole.administrador:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.policy_outlined), activeIcon: Icon(Icons.policy), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
        ];
    }
  }

  List<Widget> _tabsForRole(_AppRole role) {
    switch (role) {
      case _AppRole.atencionCliente:
        return [_buildHomeTab(), _buildTramiteTab(), _buildProfileTab()];
      case _AppRole.funcionario:
        return [_buildHomeTab(), _buildActividadesTab(), _buildProfileTab()];
      case _AppRole.administrador:
        return [_buildHomeTab(), const Center(child: Text('Vista de administrador')), _buildProfileTab()];
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final role = session?.rol ?? _AppRole.administrador;
    final tabs = _tabsForRole(role);
    final navItems = _navItemsForRole(role);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'DASHBOARD',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : IndexedStack(index: _currentIndex.clamp(0, tabs.length - 1), children: tabs),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 10)
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex.clamp(0, navItems.length - 1),
              onTap: (index) => setState(() => _currentIndex = index),
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}

_AppRole _parseRol(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'FUNCIONARIO':
      return _AppRole.funcionario;
    case 'ATENCION_CLIENTE':
      return _AppRole.atencionCliente;
    case 'ADMINISTRADOR':
    default:
      return _AppRole.administrador;
  }
}

String _roleLabel(_AppRole rol) {
  switch (rol) {
    case _AppRole.funcionario:
      return 'Funcionario';
    case _AppRole.atencionCliente:
      return 'Atención al Cliente';
    case _AppRole.administrador:
      return 'Administrador';
  }
}

enum _AppRole { administrador, funcionario, atencionCliente }

class _UserSession {
  final String id;
  final String nombre;
  final _AppRole rol;

  _UserSession({required this.id, required this.nombre, required this.rol});
}

class _PoliticaMovil {
  final String id;
  final String nombre;

  _PoliticaMovil({required this.id, required this.nombre});

  factory _PoliticaMovil.fromJson(Map<String, dynamic> json) {
    return _PoliticaMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Sin nombre').toString(),
    );
  }
}

class _PortafolioMovil {
  final String id;
  final String? politicaId;
  final String? jsonInfo;

  _PortafolioMovil({required this.id, this.politicaId, this.jsonInfo});

  factory _PortafolioMovil.fromJson(Map<String, dynamic> json) {
    return _PortafolioMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      politicaId: json['politicaId']?.toString(),
      jsonInfo: json['json']?.toString(),
    );
  }
}

class _ActividadFuncionarioPendiente {
  final _ActividadMovil actividad;
  final _PortafolioMovil portafolio;
  final String flujoInstanciaId;

  _ActividadFuncionarioPendiente({
    required this.actividad,
    required this.portafolio,
    required this.flujoInstanciaId,
  });
}

class _TramiteVista {
  final _PortafolioMovil portafolio;
  final String politicaNombre;
  final double progreso;
  final List<_TramitePasoItem> pasos;

  _TramiteVista({
    required this.portafolio,
    required this.politicaNombre,
    required this.progreso,
    required this.pasos,
  });
}
class _ActividadMovil {
  final String id;
  final String nombre;
  final String? politicaId;
  final String? departamentoId;
  final String? formUpdateId;

  _ActividadMovil({
    required this.id,
    required this.nombre,
    this.politicaId,
    this.departamentoId,
    this.formUpdateId,
  });

  factory _ActividadMovil.fromJson(Map<String, dynamic> json) {
    return _ActividadMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Actividad').toString(),
      politicaId: json['politicaId']?.toString(),
      departamentoId: json['departamentoId']?.toString(),
      formUpdateId: json['formUpdateId']?.toString(),
    );
  }
}

class _FlujoMovil {
  final String id;
  final String actividadId;
  final Map<String, dynamic> proceso;

  _FlujoMovil({required this.id, required this.actividadId, required this.proceso});

  factory _FlujoMovil.fromJson(Map<String, dynamic> json) {
    return _FlujoMovil(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      actividadId: (json['actividadId'] ?? '').toString(),
      proceso: ((json['proceso'] as Map?) ?? {}).cast<String, dynamic>(),
    );
  }
}

class _TramitePaso {
  final int orden;
  final List<_TramitePasoItem> items;

  _TramitePaso({required this.orden, required this.items});
}

class _TramitePasoItem {
  final _ActividadMovil actividad;
  final String estado;

  _TramitePasoItem({required this.actividad, required this.estado});
}
