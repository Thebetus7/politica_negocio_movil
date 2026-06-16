import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/app_role.dart';
import '../../core/models/politica_movil.dart';
import '../../core/models/role_helpers.dart';
import '../../core/models/user_session.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../actividades/actividades_screen.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_home_screen.dart';
import '../perfil/profile_screen.dart';
import '../tramites/tramites_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  final ApiClient _apiClient = ApiClient();
  int _currentIndex = 0;
  bool _isLoading = true;
  String _error = '';
  UserSession? _session;
  List<PoliticaMovil> _politicas = [];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final session = UserSession(
      id: prefs.getString('user_id') ?? '',
      nombre: prefs.getString('user_nombre') ?? 'Usuario',
      rol: parseRol(prefs.getString('user_rol')),
    );

    setState(() {
      _session = session;
      _isLoading = true;
      _error = '';
    });

    try {
      await _loadPoliticas();
    } catch (_) {
      setState(() => _error = 'No se pudo cargar información móvil');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPoliticas() async {
    final response = await _apiClient.dio.get('/politicas/public');
    final raw = (response.data as List).cast<dynamic>();
    if (mounted) {
      setState(() {
        _politicas = raw
            .map((e) => PoliticaMovil.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
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

  List<Widget> _tabsForRole(AppRole role, UserSession session) {
    switch (role) {
      case AppRole.atencionCliente:
        return [
          DashboardHomeScreen(session: session),
          TramitesScreen(session: session, politicas: _politicas),
          ProfileScreen(session: session),
        ];
      case AppRole.funcionario:
        return [
          DashboardHomeScreen(session: session),
          ActividadesScreen(session: session),
          ProfileScreen(session: session),
        ];
      case AppRole.administrador:
        return [
          DashboardHomeScreen(session: session),
          const Center(child: Text('Vista de administrador')),
          ProfileScreen(session: session),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final role = session?.rol ?? AppRole.administrador;
    final navItems = navItemsForRole(role);
    final tabs = session != null ? _tabsForRole(role, session) : <Widget>[];
    final safeIndex = _currentIndex.clamp(0, navItems.length - 1);
    final currentTitle = navItems.isNotEmpty ? (navItems[safeIndex].label ?? 'DASHBOARD') : 'DASHBOARD';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          currentTitle.toUpperCase(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadSession, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : IndexedStack(
                  index: _currentIndex.clamp(0, tabs.length - 1),
                  children: tabs,
                ),
      bottomNavigationBar: session == null || _error.isNotEmpty
          ? null
          : AppBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: navItems,
            ),
    );
  }
}
