import 'package:flutter/material.dart';

// =========================================================================
// ARCHIVE DESIGN SYSTEM - Sistema de diseño minimalista
// Colores: Primary #000000, Secondary #F0F0F0, Tertiary #757575, Neutral #FFFFFF
// Tipografía: Inter (reemplazada por el sistema por defecto de Flutter)
// =========================================================================

// --- COLORES ---
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF000000);
  static const Color secondary = Color(0xFFF0F0F0);
  static const Color tertiary = Color(0xFF757575);
  static const Color neutral = Color(0xFFFFFFFF);

  // Estados para el banner de conexión
  static const Color connected = Color(0xFF2D6A4F);
  static const Color connectedBg = Color(0xFFF0FFF4);
  static const Color disconnected = Color(0xFFAF3E3E);
  static const Color disconnectedBg = Color(0xFFFFF5F5);
  static const Color checking = Color(0xFF5C5C00);
  static const Color checkingBg = Color(0xFFFFFDE7);

  // Estados de items
  static const Color active = Color(0xFF000000);
  static const Color standby = Color(0xFF757575);
  static const Color offline = Color(0xFFAF3E3E);
}

// --- ESPACIADO ---
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// --- TIPOGRAFÍA ---
class AppTextStyles {
  AppTextStyles._();

  // Headline - grande y bold
  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  // Title - para secciones
  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.5,
  );

  // Label - mayúsculas pequeñas
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.tertiary,
    letterSpacing: 1.2,
  );

  // Body - texto corriente
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.tertiary,
  );

  // Caption - texto pequeño
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.tertiary,
    letterSpacing: 0.5,
  );

  // Metric - números grandes
  static const TextStyle metric = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -1,
  );
}

// --- DECORACIONES / ESTILOS DE BORDE ---
class AppDecorations {
  AppDecorations._();

  // Card con borde fino
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.neutral,
    border: Border.all(color: AppColors.secondary, width: 1),
  );

  // Campo de texto
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.label,
      hintText: hintText,
      hintStyle: AppTextStyles.caption,
      suffixIcon: suffixIcon,
      filled: false,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }
}

// --- BOTÓN PRIMARIO (NEGRO) ---
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.neutral,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neutral,
              ),
            )
          : Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
      ),
    );
  }
}

// --- BOTÓN SECUNDARIO (OUTLINE) ---
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// --- DIVIDER MINIMALISTA ---
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.secondary,
      thickness: 1,
      height: 1,
    );
  }
}

// --- BADGE DE ESTADO ---
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AppStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// --- TARJETA MÉTRICA ---
class AppMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.metric),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
