import 'package:flutter/material.dart';

import '../../core/widgets/app_design_system.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, items.length - 1);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.neutral,
            unselectedItemColor: AppColors.tertiary,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 1,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 9,
              letterSpacing: 1,
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: safeIndex,
            onTap: onTap,
            items: items,
          ),
        ),
      ),
    );
  }
}
