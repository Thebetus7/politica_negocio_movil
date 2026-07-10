import 'package:flutter/material.dart';

import '../../core/models/role_helpers.dart';
import '../../core/models/user_session.dart';
import '../../core/widgets/app_design_system.dart';

class DashboardHomeScreen extends StatelessWidget {
  final UserSession session;

  const DashboardHomeScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final label = roleLabel(session.rol);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hola.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bienvenido al sistema de gestión de políticas de negocio.',
            style: AppTextStyles.body,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Card de usuario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('USUARIO', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  session.nombre.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label.toUpperCase(), style: AppTextStyles.label),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Card de estado del sistema
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTADO DEL SISTEMA', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.connected,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'SISTEMA OPERATIVO',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Acciones rápidas
          Container(
            width: double.infinity,
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('ACCIONES RÁPIDAS', style: AppTextStyles.label),
                ),
                const AppDivider(),
                _buildQuickAction('Ver mis tareas'),
                const AppDivider(),
                _buildQuickAction('Mis trámites activos'),
                const AppDivider(),
                _buildQuickAction('Ver notificaciones'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Footer
          const AppDivider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© 2024 POLITICA.SYS', style: AppTextStyles.caption),
              Text('v.1.0.0', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.primary),
          ),
          const Icon(Icons.arrow_forward, size: 14, color: AppColors.tertiary),
        ],
      ),
    );
  }
}
