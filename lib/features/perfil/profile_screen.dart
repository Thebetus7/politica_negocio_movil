import 'package:flutter/material.dart';

import '../../core/models/user_session.dart';

class ProfileScreen extends StatelessWidget {
  final UserSession session;

  const ProfileScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Usuario: ${session.nombre}\nID: ${session.id}',
        textAlign: TextAlign.center,
      ),
    );
  }
}
