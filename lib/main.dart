import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  runApp(MyApp(initialRoute: token != null ? '/dashboard' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Política Móvil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF000000),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFFF0F0F0),
          onSecondary: Color(0xFF000000),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF000000),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000000),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const AppShellScreen(),
      },
    );
  }
}

