import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_design_system.dart';
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
  bool _obscurePassword = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _login() async {
    final correo = _emailController.text.trim();
    final password = _passController.text;

    if (correo.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa correo y contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
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
        setState(() => _error = 'Credenciales inválidas');
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
      setState(() => _error = 'Error inesperado al iniciar sesión.');
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
    const primaryPath = 'auth/login';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / Título
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'POLITICA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'GESTIÓN DE POLÍTICAS DE NEGOCIO',
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Campos del formulario
              Text('CORREO ELECTRÓNICO', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.body.copyWith(color: AppColors.primary),
                decoration: AppDecorations.inputDecoration(
                  labelText: '',
                  hintText: 'nombre@organizacion.com',
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CONTRASEÑA', style: AppTextStyles.label),
                  GestureDetector(
                    onTap: () {
                      _emailController.text = 'atencion1@example.com';
                      _passController.text = 'password';
                    },
                    child: Text(
                      'USAR DEMO',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                style: AppTextStyles.body.copyWith(color: AppColors.primary),
                decoration: AppDecorations.inputDecoration(
                  labelText: '',
                  hintText: '••••••••',
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.tertiary,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Error
              if (_error.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.disconnectedBg,
                  child: Text(
                    _error.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.disconnected,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Botón login
              AppPrimaryButton(
                label: 'INICIAR SESIÓN →',
                onPressed: _login,
                isLoading: _isLoading,
              ),

              // URL del servidor
              const SizedBox(height: AppSpacing.xxl),
              const AppDivider(),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'SERVIDOR  ${_apiClient.dio.options.baseUrl}',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
