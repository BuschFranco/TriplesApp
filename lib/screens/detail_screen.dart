import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/courts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/section_title.dart';
import '../widgets/status_dot.dart';

class DetailScreen extends StatelessWidget {
  final String courtId;
  final VoidCallback? onBack;

  const DetailScreen({super.key, required this.courtId, this.onBack});

  @override
  Widget build(BuildContext context) {
    final court = kCourts.firstWhere((c) => c.id == courtId,
        orElse: () => kCourts.first);

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 180),
            children: [
              _hero(court),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ratingStrip(court),
                    const SizedBox(height: 22),
                    const SectionTitle(title: 'Amenities'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final b in court.badges)
                          AppChip(label: b, icon: '✓'),
                        AppChip(label: court.surface),
                        AppChip(label: court.type),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Sobre la cancha'),
                    Text(
                      court.desc,
                      style: AppText.grotesk(
                        size: 14,
                        color: AppColors.white(0.75),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(
                        title: 'Actividad semanal', right: 'Hoy'),
                    _activityChart(),
                    const SizedBox(height: 24),
                    const SectionTitle(
                        title: 'Jugando ahora', right: 'Ver todos'),
                    _playersRow(court),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 56,
            left: 16,
            child: _iconBtn(Icons.chevron_left, onTap: onBack),
          ),
          Positioned(
            top: 56,
            right: 16,
            child: Row(
              children: [
                _iconBtn(Icons.favorite_border),
                const SizedBox(width: 8),
                _iconBtn(Icons.ios_share),
              ],
            ),
          ),
          Positioned(
            bottom: 110,
            left: 16,
            right: 16,
            child: _bottomCta(),
          ),
        ],
      ),
    );
  }

  Widget _hero(Court court) {
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              court.img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.bgElev),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x260A0F14),
                    Color(0x990A0F14),
                    AppColors.bg,
                  ],
                  stops: [0, 0.65, 1],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++) ...[
                  Container(
                    width: i == 0 ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == 0 ? Colors.white : AppColors.white(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (i < 3) const SizedBox(width: 5),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusDot(status: court.status),
                    const SizedBox(width: 8),
                    Text(
                      '· ${court.players} JUGANDO AHORA',
                      style: AppText.grotesk(
                        size: 10.5,
                        color: AppColors.white(0.6),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  court.name,
                  style: AppText.archivo(
                    size: 38,
                    weight: FontWeight.w900,
                    letterSpacing: -0.03,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${court.area} · ${court.dist} · ${court.hours}',
                  style: AppText.grotesk(
                    size: 13,
                    color: AppColors.white(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingStrip(Court court) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x991A2430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white(0.08)),
      ),
      child: Row(
        children: [
          _statCell(
            icon: Icons.star_rounded,
            value: court.rating.toString(),
            label: '${court.reviews} reseñas',
          ),
          _strokeDivider(),
          _statCell(value: court.hoops.toString(), label: 'Aros disp.'),
          _strokeDivider(),
          _statCell(value: court.vibe, label: 'Vibe'),
        ],
      ),
    );
  }

  Widget _statCell({IconData? icon, required String value, required String label}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppText.archivo(size: 22, weight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppText.grotesk(
              size: 10,
              color: AppColors.white(0.5),
              letterSpacing: 0.08,
            ),
          ),
        ],
      ),
    );
  }

  Widget _strokeDivider() => Container(
        width: 1,
        height: 40,
        color: AppColors.white(0.08),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

  Widget _activityChart() {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const vals = [30, 55, 70, 85, 90, 100, 75];
    return Container(
      padding: const EdgeInsets.all(18),
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0x991A2430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 14,
                    height: vals[i].toDouble(),
                    decoration: BoxDecoration(
                      color: i == 3 ? AppColors.accent : AppColors.white(0.12),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: i == 3
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withAlpha(136),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[i],
                    style: AppText.grotesk(
                      size: 11,
                      weight: FontWeight.w600,
                      color: i == 3 ? AppColors.accent : AppColors.white(0.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _playersRow(Court court) {
    const avatars = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80',
      'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=100&q=80',
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&q=80',
    ];
    return Row(
      children: [
        SizedBox(
          width: 36 + (avatars.length + 1) * 26,
          height: 36,
          child: Stack(
            children: [
              for (var i = 0; i < avatars.length; i++)
                Positioned(
                  left: i * 26,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(avatars[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: avatars.length * 26,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white(0.08),
                    border: Border.all(color: AppColors.bg, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${court.players - 4}',
                    style: AppText.grotesk(
                      size: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${court.players} jugadores',
              style: AppText.archivo(size: 14, weight: FontWeight.w700),
            ),
            Text(
              'Pickup game · 5v5',
              style: AppText.grotesk(size: 11, color: AppColors.white(0.5)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xB311181F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.white(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _bottomCta() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 12,
              shadowColor: AppColors.accent.withAlpha(85),
            ),
            child: Text(
              'UNIRME AL JUEGO',
              style: AppText.archivo(
                size: 13,
                weight: FontWeight.w800,
                letterSpacing: 0.06,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.white(0.08),
            border: Border.all(color: AppColors.white(0.12)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.location_on_outlined,
              color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
