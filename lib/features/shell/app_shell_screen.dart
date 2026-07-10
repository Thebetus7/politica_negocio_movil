import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/app_role.dart';
import '../../core/models/politica_movil.dart';
import '../../core/models/role_helpers.dart';
import '../../core/models/user_session.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_design_system.dart';
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
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        title: const Text(
          'ARCHIVE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 3,
          ),
        ),
        actions: [
          // Indicador de sección actual
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Text(
                currentTitle.toUpperCase(),
                style: AppTextStyles.label,
              ),
            ),
          ),
          // Botón logout
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.tertiary, size: 18),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.secondary, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 1.5,
              ),
            )
          : _error.isNotEmpty
              ? _buildErrorState()
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ERROR', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSecondaryButton(
              label: 'Reintentar',
              onPressed: _loadSession,
            ),
          ],
        ),
      ),
    );
  }
}
