import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppTab { home, list, plus, chat, profile }

class AppTabBar extends StatelessWidget {
  final AppTab active;
  final ValueChanged<AppTab> onChange;

  const AppTabBar({super.key, required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xE011181F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.white(0.08)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black(0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tabItem(AppTab.home, 'Mapa', Icons.map_outlined),
              _tabItem(AppTab.list, 'Canchas', Icons.sports_basketball_outlined),
              _plusButton(),
              _tabItem(AppTab.chat, 'Crew', Icons.chat_bubble_outline),
              _tabItem(AppTab.profile, 'Perfil', Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(AppTab tab, String label, IconData icon) {
    final isActive = active == tab;
    final color = isActive ? AppColors.accent : AppColors.white(0.55);
    return GestureDetector(
      onTap: () => onChange(tab),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.grotesk(
                size: 10,
                weight: FontWeight.w600,
                color: color,
                letterSpacing: 0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plusButton() {
    return GestureDetector(
      onTap: () => onChange(AppTab.plus),
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.accentDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withAlpha(85),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
