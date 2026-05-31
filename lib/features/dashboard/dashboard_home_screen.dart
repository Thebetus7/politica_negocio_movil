import 'package:flutter/material.dart';

import '../../core/models/role_helpers.dart';
import '../../core/models/user_session.dart';

class DashboardHomeScreen extends StatelessWidget {
  final UserSession session;

  const DashboardHomeScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final label = roleLabel(session.rol);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.0),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: Colors.black),
              const SizedBox(height: 16),
              Text(
                'HOLA, ${session.nombre.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'ROL: $label',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
