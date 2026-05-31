import 'app_role.dart';

class UserSession {
  final String id;
  final String nombre;
  final AppRole rol;

  const UserSession({required this.id, required this.nombre, required this.rol});
}
