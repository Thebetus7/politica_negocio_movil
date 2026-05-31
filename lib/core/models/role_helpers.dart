import 'package:flutter/material.dart';

import 'app_role.dart';

AppRole parseRol(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'FUNCIONARIO':
      return AppRole.funcionario;
    case 'ATENCION_CLIENTE':
      return AppRole.atencionCliente;
    case 'ADMINISTRADOR':
    default:
      return AppRole.administrador;
  }
}

String roleLabel(AppRole rol) {
  switch (rol) {
    case AppRole.funcionario:
      return 'Funcionario';
    case AppRole.atencionCliente:
      return 'Atención al Cliente';
    case AppRole.administrador:
      return 'Administrador';
  }
}

List<BottomNavigationBarItem> navItemsForRole(AppRole role) {
  switch (role) {
    case AppRole.atencionCliente:
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), activeIcon: Icon(Icons.timeline), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
      ];
    case AppRole.funcionario:
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
      ];
    case AppRole.administrador:
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.policy_outlined), activeIcon: Icon(Icons.policy), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
      ];
  }
}
