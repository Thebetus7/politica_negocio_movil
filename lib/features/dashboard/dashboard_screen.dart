import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import 'package:dio/dio.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _username = "Cargando...";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final dio = Dio();

    try {
      final res = await dio.get(
        'http://10.0.2.2:8081/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200) {
        setState(() {
          _username = res.data['username'] ?? 'Usuario';
        });
      } else {
        setState(() => _username = "Desconocido");
      }
    } catch (e) {
      setState(() => _username = "Admin (Local)");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // HOME TAB
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2.0),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 64, color: Colors.black),
                    const SizedBox(height: 16),
                    Text(
                      'HOLA, ${_username.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ROLES: Administrador',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // SECOND TAB
          const Center(child: Text('Políticas y Actividades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          // THIRD TAB
          const Center(child: Text('Ajustes del Auxiliar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
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
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.science_outlined), activeIcon: Icon(Icons.science), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
