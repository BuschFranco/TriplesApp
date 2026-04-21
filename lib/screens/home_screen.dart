import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../data/courts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/rating_badge.dart';
import '../widgets/status_dot.dart';

const _kApiKey = String.fromEnvironment('MAPS_API_KEY');

const _kMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1520"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8896a7"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0f14"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#152030"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c0c8d8"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#8896a7"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2a3a"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0d1a26"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8896a7"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1e3040"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1a3a52"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#0d2030"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0c4d4"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#586878"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a1929"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d5060"}]}
]
''';

class _Prediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const _Prediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectCourt;
  final VoidCallback? onOpenFilters;

  const HomeScreen({super.key, this.onSelectCourt, this.onOpenFilters});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  GoogleMapController? _mapCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  List<_Prediction> _predictions = [];
  bool _showSearch = false;

  Court get _court => kCourts[_index];

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Set<Marker> get _markers => {
        for (var i = 0; i < kCourts.length; i++)
          Marker(
            markerId: MarkerId(kCourts[i].id),
            position: LatLng(kCourts[i].lat, kCourts[i].lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == _index ? 22.0 : BitmapDescriptor.hueAzure,
            ),
            onTap: () => _onSelectIndex(i),
          ),
      };

  void _onSelectIndex(int i) {
    setState(() => _index = i);
    _mapCtrl?.animateCamera(
      CameraUpdate.newLatLng(LatLng(kCourts[i].lat, kCourts[i].lng)),
    );
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': query,
        'types': '(regions)',
        'components': 'country:ar',
        'language': 'es',
        'key': _kApiKey,
      });
      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['predictions'] as List<dynamic>;
      final predictions = raw.map((p) {
        final fmt = p['structured_formatting'] as Map<String, dynamic>;
        return _Prediction(
          placeId: p['place_id'] as String,
          mainText: fmt['main_text'] as String,
          secondaryText: (fmt['secondary_text'] ?? '') as String,
        );
      }).toList();
      setState(() => _predictions = predictions);
    } catch (_) {}
  }

  Future<void> _onSelectPrediction(_Prediction pred) async {
    setState(() {
      _showSearch = false;
      _predictions = [];
      _searchCtrl.text = pred.mainText;
    });
    FocusScope.of(context).unfocus();
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
        'place_id': pred.placeId,
        'fields': 'geometry',
        'key': _kApiKey,
      });
      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final loc = (data['result'] as Map)['geometry']['location'] as Map<String, dynamic>;
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
          14,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: (ctrl) => _mapCtrl = ctrl,
            style: _kMapStyle,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-34.6037, -58.3816),
              zoom: 12,
            ),
            markers: _markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            tiltGesturesEnabled: false,
          ),
          Positioned(
            top: 54,
            left: 16,
            right: 16,
            child: _searchBar(),
          ),
          if (_showSearch && _predictions.isNotEmpty)
            Positioned(
              top: 112,
              left: 16,
              right: 16,
              child: _predictionsOverlay(),
            ),
          if (!_showSearch)
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
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            radius: 100,
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.white(0.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onTap: () => setState(() => _showSearch = true),
                    onChanged: _onSearch,
                    style: AppText.grotesk(size: 14),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      hintText: 'Buscar barrio',
                      hintStyle: AppText.grotesk(
                        size: 14,
                        color: AppColors.white(0.55),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_showSearch)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = false;
                        _predictions = [];
                        _searchCtrl.clear();
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Icon(Icons.close, size: 16, color: AppColors.white(0.5)),
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

  Widget _predictionsOverlay() {
    return _glassContainer(
      radius: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final pred in _predictions.take(5))
            InkWell(
              onTap: () => _onSelectPrediction(pred),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: AppColors.white(0.5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pred.mainText, style: AppText.grotesk(size: 14)),
                          if (pred.secondaryText.isNotEmpty)
                            Text(
                              pred.secondaryText,
                              style: AppText.grotesk(
                                size: 11,
                                color: AppColors.white(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => AppChip(
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
            onPrev: () => _onSelectIndex((_index - 1 + kCourts.length) % kCourts.length),
            onNext: () => _onSelectIndex((_index + 1) % kCourts.length),
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
                  color: i == _index ? AppColors.accent : AppColors.white(0.25),
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
                      errorBuilder: (context, error, stack) => Container(
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
