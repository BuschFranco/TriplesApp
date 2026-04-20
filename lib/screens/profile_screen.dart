import 'package:flutter/material.dart';
import '../data/courts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/bball_glyph.dart';
import '../widgets/section_title.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withAlpha(48),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.only(top: 56, bottom: 180),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MI PERFIL',
                      style: AppText.grotesk(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.white(0.4),
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.white(0.08)),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.accent, width: 3),
                        image: DecorationImage(
                          image: NetworkImage(kPlayer.avatar),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(85),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kPlayer.name,
                            style: AppText.archivo(
                              size: 24,
                              weight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${kPlayer.handle} · ${kPlayer.city}',
                            style: AppText.grotesk(
                              size: 12,
                              color: AppColors.white(0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppChip(label: kPlayer.pos, icon: '🏀'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _StatBox(
                      label: 'Partidos',
                      value: kPlayer.games.toString(),
                      accent: true,
                    ),
                    _StatBox(
                      label: 'Canchas',
                      value: kPlayer.courts.toString(),
                    ),
                    _StatBox(
                      label: 'Racha',
                      value: '${kPlayer.streak}d',
                      icon: '🔥',
                    ),
                    _StatBox(
                      label: 'Rating',
                      value: kPlayer.rating.toString(),
                      icon: '⭐',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: 'Logros', right: 'Ver todos'),
                    Row(
                      children: [
                        for (var i = 0; i < kPlayer.badges.length; i++) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: i == 0
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.accent.withAlpha(51),
                                          AppColors.accent.withAlpha(13),
                                        ],
                                      )
                                    : null,
                                color: i == 0
                                    ? null
                                    : const Color(0x801A2430),
                                border: Border.all(
                                  color: i == 0
                                      ? AppColors.accent.withAlpha(102)
                                      : AppColors.white(0.08),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    kPlayer.badges[i].icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    kPlayer.badges[i].name,
                                    textAlign: TextAlign.center,
                                    style: AppText.grotesk(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: i == 0
                                          ? AppColors.accent
                                          : AppColors.white(0.7),
                                      letterSpacing: 0.04,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < kPlayer.badges.length - 1)
                            const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                        title: 'Últimos partidos', right: 'Ver historial'),
                    for (final r in kPlayer.recent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x801A2430),
                          border: Border.all(color: AppColors.white(0.06)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accentDark,
                                  ],
                                ),
                              ),
                              child: const Center(child: BBallGlyph(size: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.court,
                                    style: AppText.archivo(
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    r.date,
                                    style: AppText.grotesk(
                                      size: 11,
                                      color: AppColors.white(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                style: AppText.archivo(
                                  size: 20,
                                  weight: FontWeight.w900,
                                  color: AppColors.accent,
                                  letterSpacing: -0.02,
                                ),
                                children: [
                                  TextSpan(text: r.points.toString()),
                                  TextSpan(
                                    text: ' pts',
                                    style: AppText.grotesk(
                                      size: 11,
                                      color: AppColors.white(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final String? icon;

  const _StatBox({
    required this.label,
    required this.value,
    this.accent = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: accent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentDark],
              )
            : null,
        color: accent ? null : const Color(0x991A2430),
        border: accent ? null : Border.all(color: AppColors.white(0.08)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: accent
            ? [
                BoxShadow(
                  color: AppColors.accent.withAlpha(68),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (icon != null)
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(
                opacity: 0.6,
                child: Text(icon!, style: const TextStyle(fontSize: 16)),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppText.archivo(
                  size: 32,
                  weight: FontWeight.w900,
                  letterSpacing: -0.03,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: AppText.grotesk(
                  size: 10,
                  weight: FontWeight.w600,
                  color: accent
                      ? AppColors.white(0.85)
                      : AppColors.white(0.5),
                  letterSpacing: 0.14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
