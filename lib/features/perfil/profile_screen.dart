import 'package:flutter/material.dart';

import '../../core/models/role_helpers.dart';
import '../../core/models/user_session.dart';
import '../../core/widgets/app_design_system.dart';

class ProfileScreen extends StatelessWidget {
  final UserSession session;

  const ProfileScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final label = roleLabel(session.rol);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Título
          const Text(
            'PERFIL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Información de la cuenta activa.',
            style: AppTextStyles.body,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Avatar / Iniciales
          Center(
            child: Container(
              width: 80,
              height: 80,
              color: AppColors.primary,
              child: Center(
                child: Text(
                  session.nombre.isNotEmpty
                    ? session.nombre[0].toUpperCase()
                    : 'U',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Datos del usuario en rows
          _buildDataRow('NOMBRE', session.nombre),
          const AppDivider(),
          _buildDataRow('ROL', label.toUpperCase()),
          const AppDivider(),
          _buildDataRow('ID', session.id.isEmpty ? 'N/A' : '#${session.id.substring(0, 8).toUpperCase()}'),
          const AppDivider(),

          const SizedBox(height: AppSpacing.xl),

          // Sección de controles
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONTROLES DE SISTEMA', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sesión activa',
                      style: AppTextStyles.body.copyWith(color: AppColors.primary),
                    ),
                    const AppStatusBadge(
                      label: 'ACTIVE',
                      color: AppColors.connected,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          const AppDivider(),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              '© 2024 POLITICA.SYS  v.1.0.0',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.label),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
