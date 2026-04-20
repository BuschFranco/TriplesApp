import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/courts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/bball_glyph.dart';
import '../widgets/rating_badge.dart';
import '../widgets/status_dot.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectCourt;
  final VoidCallback? onOpenFilters;

  const HomeScreen({super.key, this.onSelectCourt, this.onOpenFilters});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Court get _court => kCourts[_index];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          _MapCanvas(
            activeIndex: _index,
            onPin: (i) => setState(() => _index = i),
          ),
          Positioned(
            top: 54,
            left: 16,
            right: 16,
            child: _searchBar(),
          ),
          Positioned(
            top: 112,
            left: 0,
            right: 0,
            child: _quickChips(),
          ),
          Positioned(
            right: 16,
            bottom: 260,
            child: _locateBtn(),
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: _bottomSwipe(),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: _glassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            radius: 100,
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.white(0.5)),
                const SizedBox(width: 10),
                Text(
                  'Buscar cancha o barrio',
                  style: AppText.grotesk(
                    size: 14,
                    color: AppColors.white(0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: widget.onOpenFilters,
          child: _glassContainer(
            width: 44,
            height: 44,
            radius: 100,
            child: const Center(
              child: Icon(Icons.tune, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickChips() {
    final chips = [
      ('Cerca', true),
      ('Abierto ahora', false),
      ('Iluminada', false),
      ('Gratis', false),
      ('Interior', false),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AppChip(
          label: chips[i].$1,
          active: chips[i].$2,
        ),
      ),
    );
  }

  Widget _locateBtn() {
    return _glassContainer(
      width: 48,
      height: 48,
      radius: 16,
      child: Icon(Icons.my_location, color: AppColors.accent, size: 22),
    );
  }

  Widget _bottomSwipe() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _CourtSwipeCard(
            court: _court,
            onSelect: () => widget.onSelectCourt?.call(_court.id),
            onPrev: () => setState(() =>
                _index = (_index - 1 + kCourts.length) % kCourts.length),
            onNext: () =>
                setState(() => _index = (_index + 1) % kCourts.length),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kCourts.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _index ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.accent
                      : AppColors.white(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (i < kCourts.length - 1) const SizedBox(width: 5),
            ],
          ],
        ),
      ],
    );
  }

  Widget _glassContainer({
    required Widget child,
    double? width,
    double? height,
    double radius = 14,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xE011181F),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.white(0.1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onPin;

  const _MapCanvas({required this.activeIndex, required this.onPin});

  static const _positions = [
    Offset(0.45, 0.42),
    Offset(0.70, 0.25),
    Offset(0.25, 0.58),
    Offset(0.82, 0.48),
    Offset(0.55, 0.75),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1520), Color(0xFF0A0F14)],
            ),
          ),
        ),
        CustomPaint(painter: _MapBgPainter(), child: const SizedBox.expand()),
        // "You are here" pulse
        const Center(child: _PulsingDot()),
        // Pins
        LayoutBuilder(builder: (_, c) {
          return Stack(
            children: [
              for (var i = 0; i < kCourts.length; i++)
                Positioned(
                  left: c.maxWidth * _positions[i].dx - 40,
                  top: c.maxHeight * _positions[i].dy - 40,
                  child: _Pin(
                    court: kCourts[i],
                    active: i == activeIndex,
                    onTap: () => onPin(i),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _MapBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final streetPaint = Paint()
      ..color = AppColors.white(0.04)
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.31);
    canvas.translate(-size.width / 2, -size.height / 2);
    for (double x = -size.width; x < size.width * 2; x += 60) {
      canvas.drawLine(Offset(x, -size.height), Offset(x, size.height * 2), streetPaint);
    }
    for (double y = -size.height; y < size.height * 2; y += 60) {
      canvas.drawLine(Offset(-size.width, y), Offset(size.width * 2, y), streetPaint);
    }
    canvas.restore();

    // River blob
    final river = Paint()..color = const Color(0x1F285078);
    final path = Path()
      ..moveTo(-20, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.65, size.width * 0.5,
          size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.85, size.width + 20,
          size.height * 0.78)
      ..lineTo(size.width + 20, size.height)
      ..lineTo(-20, size.height)
      ..close();
    canvas.drawPath(path, river);
  }

  @override
  bool shouldRepaint(covariant _MapBgPainter oldDelegate) => false;
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 18 + _ctrl.value * 40,
              height: 18 + _ctrl.value * 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withAlpha(
                      ((1 - _ctrl.value) * 100).toInt()),
                  width: 2,
                ),
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
              boxShadow: [
                BoxShadow(color: AppColors.accent, blurRadius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Court court;
  final bool active;
  final VoidCallback onTap;

  const _Pin({required this.court, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: active ? 1.15 : 1,
        duration: const Duration(milliseconds: 250),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: active ? 10 : 8,
                vertical: active ? 7 : 6,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : const Color(0xF211181F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.white(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? AppColors.accent.withAlpha(136)
                        : AppColors.black(0.4),
                    blurRadius: active ? 20 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BBallGlyph(size: 14),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Text(
                      court.name.split(' ').first,
                      style: AppText.grotesk(
                        size: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CustomPaint(
              size: const Size(10, 7),
              painter: _PinTailPainter(
                  color: active ? AppColors.accent : const Color(0xF211181F)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}

class _CourtSwipeCard extends StatelessWidget {
  final Court court;
  final VoidCallback onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CourtSwipeCard({
    required this.court,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xEB11181F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white(0.1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black(0.5),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      court.img,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 96,
                        height: 96,
                        color: AppColors.bgElev,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.black(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        court.dist.toUpperCase(),
                        style: AppText.grotesk(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusDot(status: court.status),
                        RatingBadge(value: court.rating, size: 11),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      court.name,
                      style: AppText.archivo(size: 18, weight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${court.area} · ${court.type} · ${court.hoops} aros',
                      style: AppText.grotesk(
                        size: 11,
                        color: AppColors.white(0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onSelect,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'VER DETALLE',
                                style: AppText.archivo(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  letterSpacing: 0.04,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _arrowBtn(Icons.chevron_left, onPrev),
                        const SizedBox(width: 6),
                        _arrowBtn(Icons.chevron_right, onNext),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrowBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.white(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.white(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
