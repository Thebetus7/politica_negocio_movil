import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../shell/app_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'atencion1@example.com',
  );
  final TextEditingController _passController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String _error = "";

  bool _checkingConnection = true;
  bool _isConnected = false;
  String _connectionMessage = 'Verificando conexión...';

  @override
  void initState() {
    super.initState();
    _verifyConnection();
  }

  Future<void> _verifyConnection() async {
    setState(() {
      _checkingConnection = true;
      _connectionMessage = 'Verificando conexión...';
    });

    final result = await _apiClient.checkHealth();

    if (!mounted) return;
    setState(() {
      _checkingConnection = false;
      _isConnected = result.connected;
      _connectionMessage = result.message;
    });
  }

  void _login() async {
    final correo = _emailController.text.trim();
    final password = _passController.text;

    if (correo.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Completa correo y contraseña.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = "";
    });

    final reachable = await _apiClient.isServerReachable();
    if (!reachable) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Fuera de conexión al servidor.';
      });
      return;
    }

    try {
      final response = await _loginWithFallback(correo: correo, password: password);

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        setState(() => _error = "Credenciales inválidas");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_id', (data['id'] ?? '').toString());
      await prefs.setString('user_nombre', (data['nombre'] ?? '').toString());
      await prefs.setString('user_rol', (data['rol'] ?? '').toString());

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShellScreen()),
      );
    } on DioException catch (e) {
      final message = await _buildLoginErrorMessage(e, correo);
      if (!mounted) return;
      setState(() => _error = message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Error inesperado al iniciar sesión.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _buildLoginErrorMessage(DioException e, String correo) async {
    if (ApiClient.isConnectionFailure(e)) {
      return 'Fuera de conexión al servidor.';
    }

    final status = e.response?.statusCode;
    if (status != null && status >= 500) {
      return 'Fuera de conexión al servidor.';
    }

    final errorCode = ApiClient.parseApiErrorCode(e.response?.data);

    if (errorCode == 'EMAIL_NOT_FOUND') {
      return 'No existe una cuenta con ese correo electrónico.';
    }

    if (errorCode == 'WRONG_PASSWORD') {
      return 'El correo existe, pero la contraseña es incorrecta.';
    }

    final exists = await _apiClient.checkEmailExists(correo);
    if (exists == null) {
      return 'Fuera de conexión al servidor.';
    }
    if (!exists) {
      return 'No existe una cuenta con ese correo electrónico.';
    }

    return 'El correo existe, pero la contraseña es incorrecta.';
  }

  Future<Response<dynamic>> _loginWithFallback({
    required String correo,
    required String password,
  }) async {
    final base = _apiClient.dio.options.baseUrl.toLowerCase();
    final primaryPath = 'auth/login';
    final fallbackPath = base.contains('/api') ? null : 'api/auth/login';

    try {
      return await _apiClient.dio.post(primaryPath, data: {
        'correo': correo,
        'password': password,
      });
    } on DioException catch (e) {
      final code = ApiClient.parseApiErrorCode(e.response?.data);
      if (code == 'EMAIL_NOT_FOUND' || code == 'WRONG_PASSWORD') {
        rethrow;
      }
      final isNotFound = e.response?.statusCode == 404;
      if (!isNotFound || fallbackPath == null) {
        rethrow;
      }
      return _apiClient.dio.post(fallbackPath, data: {
        'correo': correo,
        'password': password,
      });
    }
  }

  Widget _buildConnectionBanner() {
    final Color bg;
    final Color fg;
    final IconData icon;

    if (_checkingConnection) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      icon = Icons.sync;
    } else if (_isConnected) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      icon = Icons.check_circle;
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      icon = Icons.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          if (_checkingConnection)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _connectionMessage,
              style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (!_checkingConnection)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.refresh, color: fg, size: 20),
              tooltip: 'Reintentar',
              onPressed: _verifyConnection,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - Móvil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildConnectionBanner(),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _emailController.text = 'atencion1@example.com';
                  _passController.text = 'password';
                },
                child: const Text('Llenar Atención al Cliente', style: TextStyle(color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 10),
            if (_error.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: const Text('Entrar')),
            const SizedBox(height: 16),
            Text(
              'API: ${_apiClient.dio.options.baseUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      )
    );
  }
}
