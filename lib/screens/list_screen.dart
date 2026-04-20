import 'package:flutter/material.dart';
import '../data/courts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/rating_badge.dart';
import '../widgets/status_dot.dart';

class ListScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectCourt;
  const ListScreen({super.key, this.onSelectCourt});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String _sort = 'near';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.only(top: 56, bottom: 160),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '340 CANCHAS · BUENOS AIRES',
                  style: AppText.grotesk(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Canchas\ncerca tuyo.',
                  style: AppText.archivo(
                    size: 36,
                    weight: FontWeight.w900,
                    letterSpacing: -0.03,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final c in const [
                  ('near', 'Más cerca'),
                  ('rate', 'Mejor rating'),
                  ('busy', 'Más activas'),
                  ('new', 'Nuevas'),
                ]) ...[
                  AppChip(
                    label: c.$2,
                    active: _sort == c.$1,
                    onTap: () => setState(() => _sort = c.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < kCourts.length; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _CourtListItem(
                court: kCourts[i],
                rank: i + 1,
                onTap: () => widget.onSelectCourt?.call(kCourts[i].id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourtListItem extends StatelessWidget {
  final Court court;
  final int rank;
  final VoidCallback onTap;

  const _CourtListItem({
    required this.court,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x991A2430),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white(0.08)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(19),
                    topRight: Radius.circular(19),
                  ),
                  child: Image.network(
                    court.img,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: AppColors.bgElev,
                    ),
                  ),
                ),
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD90A0F14)],
                      stops: [0.4, 1],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Text(
                    rank.toString().padLeft(2, '0'),
                    style: AppText.archivo(
                      size: 24,
                      weight: FontWeight.w900,
                      letterSpacing: -0.05,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusDot(status: court.status),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      for (final b in court.badges.take(3)) ...[
                        _miniBadge(b),
                        const SizedBox(width: 5),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              court.name,
                              style: AppText.archivo(
                                size: 19,
                                weight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${court.area} · ${court.dist}',
                              style: AppText.grotesk(
                                size: 12,
                                color: AppColors.white(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      RatingBadge(value: court.rating, size: 13),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.white(0.06)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _stat('Tipo', court.type),
                        _divider(),
                        _stat('Superficie', court.surface),
                        _divider(),
                        _stat('Jugando', '${court.players}', highlight: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.black(0.7),
        border: Border.all(color: AppColors.white(0.12)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.grotesk(
          size: 9.5,
          weight: FontWeight.w600,
          letterSpacing: 0.04,
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.grotesk(
              size: 9.5,
              weight: FontWeight.w600,
              color: AppColors.white(0.4),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.archivo(
              size: 14,
              weight: FontWeight.w700,
              color: highlight ? AppColors.accent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: AppColors.white(0.06),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}
