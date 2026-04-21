import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../data/courts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/rating_badge.dart';
import '../widgets/status_dot.dart';

const _kMapsApiKey = String.fromEnvironment(
  'MAPS_API_KEY',
  defaultValue: 'AIzaSyA8CPXNiny4hDxakznny0eoY229nmRR9Ng',
);

class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectCourt;
  final VoidCallback? onOpenFilters;

  const HomeScreen({super.key, this.onSelectCourt, this.onOpenFilters});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  bool _locating = false;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;

  // Buenos Aires center
  static const _initialCamera = CameraPosition(
    target: LatLng(-34.5995, -58.3816),
    zoom: 12.5,
  );

  Court get _court => kCourts[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$_kMapsApiKey'
      '&language=es'
      '&components=country:ar'
      '&types=geocode%7Cestablishment',
    );
    try {
      final res = await http.get(uri);
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List? ?? [];
      setState(() {
        _suggestions = predictions.map((p) => _PlaceSuggestion(
          placeId: p['place_id'] as String,
          mainText: (p['structured_formatting']?['main_text'] as String?) ?? p['description'] as String,
          secondaryText: (p['structured_formatting']?['secondary_text'] as String?) ?? '',
        )).toList();
      });
    } catch (_) {}
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    _searchController.text = s.mainText;
    _searchFocus.unfocus();
    setState(() => _suggestions = []);

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${s.placeId}'
      '&key=$_kMapsApiKey'
      '&fields=geometry',
    );
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final loc = data['result']['geometry']['location'];
      await _animateTo(LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()));
    } catch (_) {}
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _suggestions = []);
    _searchFocus.unfocus();
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};
    for (var i = 0; i < kCourts.length; i++) {
      final idx = i; // captura por valor — i muta entre iteraciones
      final court = kCourts[i];
      final active = i == _index;
      final icon = await _buildPinBitmap(court.name.split(' ').first, active);
      markers.add(Marker(
        markerId: MarkerId(court.id),
        position: LatLng(court.lat, court.lng),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        onTap: () {
          setState(() => _index = idx);
          _buildMarkers();
          _animateTo(LatLng(court.lat, court.lng));
        },
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _buildPinBitmap(String label, bool active) async {
    const double r = 3.0;
    final double pw = active
        ? (label.length * 8.0 + 48.0).clamp(88.0, 140.0)
        : 44.0;
    const double ph = 36.0;
    const double th = 8.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(r);

    final bg = active ? const Color(0xFFFF6B1A) : const Color(0xF211181F);
    final border = active ? const Color(0xFFFF6B1A) : const Color(0x33FFFFFF);

    // Pill background
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, pw - 2, ph - 2),
      const Radius.circular(13),
    );
    canvas.drawRRect(rrect, Paint()..color = bg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Triangle tail
    canvas.drawPath(
      Path()
        ..moveTo(pw / 2 - 5, ph - 1)
        ..lineTo(pw / 2 + 5, ph - 1)
        ..lineTo(pw / 2, ph + th)
        ..close(),
      Paint()..color = bg,
    );

    // Basketball glyph
    final gp = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    const cx = 22.0;
    const cy = ph / 2;
    canvas.drawCircle(const Offset(cx, cy), 8, gp);
    canvas.drawLine(const Offset(cx - 8, cy), const Offset(cx + 8, cy), gp);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(cx - 3, cy), radius: 6.5),
      -0.4, 0.8, false, gp,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(cx + 3, cy), radius: 6.5),
      2.74, 0.8, false, gp,
    );

    // Label text (active only)
    if (active) {
      final tp = TextPainter(
        text: TextSpan(
          text: label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(38, (ph - tp.height) / 2));
    }

    final pic = recorder.endRecording();
    final img = await pic.toImage(
      (pw * r).toInt(),
      ((ph + th) * r).toInt(),
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _animateTo(LatLng pos) async {
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newLatLng(pos));
  }

  void _changeIndex(int newIndex) {
    setState(() => _index = newIndex);
    _buildMarkers();
    _animateTo(LatLng(kCourts[newIndex].lat, kCourts[newIndex].lng));
  }

  Future<void> _locateUser() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _animateTo(LatLng(pos.latitude, pos.longitude));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCamera,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onMapCreated: (ctrl) {
            ctrl.setMapStyle(_kDarkMapStyle);
            _mapController.complete(ctrl);
          },
          onTap: (_) => _clearSearch(),
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
        // Search bar + suggestions van al final para estar encima de todo
        Positioned(
          top: 54,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchBar(),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _suggestionsList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: _glassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            radius: 100,
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.white(0.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    style: AppText.grotesk(size: 14),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      hintText: 'Buscar barrio',
                      hintStyle: AppText.grotesk(
                        size: 14,
                        color: AppColors.white(0.45),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(Icons.close, size: 16, color: AppColors.white(0.4)),
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

  Widget _suggestionsList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF011181F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.white(0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.white(0.06),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (_, i) {
              final s = _suggestions[i];
              return InkWell(
                onTap: () => _selectSuggestion(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.mainText,
                              style: AppText.grotesk(
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (s.secondaryText.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                s.secondaryText,
                                style: AppText.grotesk(
                                  size: 11,
                                  color: AppColors.white(0.45),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
    return GestureDetector(
      onTap: _locating ? null : _locateUser,
      child: _glassContainer(
        width: 48,
        height: 48,
        radius: 16,
        child: Center(
          child: _locating
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : Icon(Icons.my_location, color: AppColors.accent, size: 22),
        ),
      ),
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
            onPrev: () =>
                _changeIndex((_index - 1 + kCourts.length) % kCourts.length),
            onNext: () => _changeIndex((_index + 1) % kCourts.length),
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
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
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
                      style:
                          AppText.archivo(size: 18, weight: FontWeight.w800),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
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

class _PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

const String _kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1520"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4a5a6a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0f14"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a2430"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#7a8a9a"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.sports_complex","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.sports_complex","elementType":"geometry","stylers":[{"color":"#0f2a1a"}]},
  {"featureType":"poi.sports_complex","elementType":"labels.text.fill","stylers":[{"color":"#4ADE80"}]},
  {"featureType":"poi.sports_complex","elementType":"labels.icon","stylers":[{"visibility":"on"},{"color":"#FF6B1A"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2430"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#111821"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#3a4a5a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1e2e3e"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#253545"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1a2430"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#4a5a6a"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#071016"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#253545"}]}
]
''';
