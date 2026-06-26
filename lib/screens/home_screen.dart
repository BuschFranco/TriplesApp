import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  final List<Court> courts;
  final String? focusCourtId;
  final VoidCallback? onFocusConsumed;
  final ValueChanged<String>? onSelectCourt;
  final VoidCallback? onOpenFilters;

  const HomeScreen({
    super.key,
    required this.courts,
    this.focusCourtId,
    this.onFocusConsumed,
    this.onSelectCourt,
    this.onOpenFilters,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  GoogleMapController? _mapCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  List<_Prediction> _predictions = [];
  bool _showSearch = false;
  bool _locating = false;

  // Filtros rápidos activos (chips debajo del buscador). "Cerca" ordena por
  // cercanía a la ubicación del usuario; el resto filtra la lista.
  final Set<String> _activeFilters = {'Cerca'};
  Position? _userPos;

  // Punto de "mi ubicación" con animación de pulso. _userScreen es la posición
  // en pantalla (px lógicos) de _userPos, recalculada al mover la cámara.
  late final AnimationController _pulseCtrl;
  Offset? _userScreen;

  // Canchas visibles tras aplicar los filtros activos. Alimenta tanto los
  // marcadores del mapa como la tarjeta inferior.
  List<Court> _filtered = [];

  Court? get _court => _filtered.isEmpty
      ? null
      : _filtered[_index.clamp(0, _filtered.length - 1)];

  // Markers cacheados: solo se recalculan cuando cambian las canchas o el
  // índice seleccionado, no en cada setState (buscar, spinner, etc.).
  Set<Marker> _markers = {};

  void _applyFilters() {
    final list = widget.courts.where((c) {
      if (_activeFilters.contains('Abierto ahora') &&
          c.status != CourtStatus.open) {
        return false;
      }
      if (_activeFilters.contains('Iluminada') && !c.lit) return false;
      if (_activeFilters.contains('Gratis') && !c.free) return false;
      if (_activeFilters.contains('Interior') && c.type != 'Interior') {
        return false;
      }
      return true;
    }).toList();

    if (_activeFilters.contains('Cerca') && _userPos != null) {
      final p = _userPos!;
      list.sort((a, b) => Geolocator.distanceBetween(
              p.latitude, p.longitude, a.lat, a.lng)
          .compareTo(
              Geolocator.distanceBetween(p.latitude, p.longitude, b.lat, b.lng)));
    }

    _filtered = list;
    if (_index >= _filtered.length) _index = 0;
    _rebuildMarkers();
  }

  Future<void> _toggleFilter(String label) async {
    setState(() {
      if (_activeFilters.contains(label)) {
        _activeFilters.remove(label);
      } else {
        _activeFilters.add(label);
      }
    });
    // Al activar "Cerca" sin ubicación todavía, la pedimos para poder ordenar.
    if (label == 'Cerca' && _activeFilters.contains('Cerca') && _userPos == null) {
      await _ensureUserPosition();
    }
    setState(_applyFilters);
  }

  Future<void> _ensureUserPosition() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      _userPos = pos;
      _updateUserScreenPos();
    } catch (_) {}
  }

  Future<void> _loadInitialPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _userPos = pos;
        _applyFilters();
      });
      _updateUserScreenPos();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    // Si venimos desde el detalle con una cancha en foco, seleccionarla.
    _applyFilters();
    final fid = widget.focusCourtId;
    if (fid != null) {
      final idx = _filtered.indexWhere((c) => c.id == fid);
      if (idx >= 0) _index = idx;
    }
    _rebuildMarkers();
    _loadInitialPosition();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.courts, widget.courts) ||
        old.courts.length != widget.courts.length) {
      _applyFilters();
    }
    final fid = widget.focusCourtId;
    if (fid != null && fid != old.focusCourtId) {
      _focusOnCourt(fid);
    }
  }

  void _rebuildMarkers() {
    _markers = {
      for (var i = 0; i < _filtered.length; i++)
        Marker(
          markerId: MarkerId(_filtered[i].id),
          position: LatLng(_filtered[i].lat, _filtered[i].lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == _index ? 22.0 : BitmapDescriptor.hueAzure,
          ),
          onTap: () => _onSelectIndex(i),
        ),
    };
  }

  void _focusOnCourt(String courtId) {
    final idx = _filtered.indexWhere((c) => c.id == courtId);
    if (idx >= 0) {
      setState(() {
        _index = idx;
        _rebuildMarkers();
      });
      final c = _filtered[idx];
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(c.lat, c.lng), 16),
      );
    }
    widget.onFocusConsumed?.call();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Convierte _userPos (lat/lng) a coordenadas de pantalla para anclar el
  // punto de ubicación. Se llama al crear el mapa y al mover la cámara.
  Future<void> _updateUserScreenPos() async {
    final ctrl = _mapCtrl;
    final pos = _userPos;
    if (ctrl == null || pos == null) {
      if (_userScreen != null && mounted) setState(() => _userScreen = null);
      return;
    }
    try {
      final sc = await ctrl.getScreenCoordinate(
        LatLng(pos.latitude, pos.longitude),
      );
      if (!mounted) return;
      final ratio = MediaQuery.of(context).devicePixelRatio;
      setState(() => _userScreen = Offset(sc.x / ratio, sc.y / ratio));
    } catch (_) {}
  }

  void _onSelectIndex(int i) {
    setState(() {
      _index = i;
      _rebuildMarkers();
    });
    _mapCtrl?.animateCamera(
      CameraUpdate.newLatLng(LatLng(_filtered[i].lat, _filtered[i].lng)),
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
            onMapCreated: (ctrl) {
              _mapCtrl = ctrl;
              ctrl.setMapStyle(_kMapStyle);
              final c = _court;
              if (widget.focusCourtId != null && c != null) {
                ctrl.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(c.lat, c.lng), 16),
                );
                widget.onFocusConsumed?.call();
              }
              _updateUserScreenPos();
            },
            onCameraMove: (_) => _updateUserScreenPos(),
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
          _userLocationDot(),
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
            bottom: 148,
            left: 0,
            right: 0,
            child: _filtered.isEmpty ? _emptyFilterCard() : _bottomSwipe(),
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
    const labels = ['Cerca', 'Abierto ahora', 'Iluminada', 'Gratis', 'Interior'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => AppChip(
          label: labels[i],
          active: _activeFilters.contains(labels[i]),
          onTap: () => _toggleFilter(labels[i]),
        ),
      ),
    );
  }

  Widget _emptyFilterCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _glassContainer(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          children: [
            Icon(Icons.search_off, color: AppColors.white(0.5), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ninguna cancha coincide con los filtros',
                style: AppText.grotesk(size: 13, color: AppColors.white(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _userLocationDot() {
    final p = _userScreen;
    if (p == null) return const SizedBox.shrink();
    const box = 96.0;
    return Positioned(
      left: p.dx - box / 2,
      top: p.dy - box / 2,
      width: box,
      height: box,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final t = _pulseCtrl.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Anillo de pulso que crece y se desvanece.
                  Container(
                    width: 20 + t * 56,
                    height: 20 + t * 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withAlpha(((1 - t) * 90).round()),
                    ),
                  ),
                  child!,
                ],
              );
            },
            // Punto central fijo.
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(140),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locateBtn() {
    return GestureDetector(
      onTap: _goToMyLocation,
      child: _glassContainer(
        width: 48,
        height: 48,
        radius: 16,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _locating
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : Icon(
                  key: const ValueKey('icon'),
                  Icons.my_location,
                  color: AppColors.accent,
                  size: 22,
                ),
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
            court: _court!,
            onSelect: () => widget.onSelectCourt?.call(_court!.id),
            onPrev: () => _onSelectIndex((_index - 1 + _filtered.length) % _filtered.length),
            onNext: () => _onSelectIndex((_index + 1) % _filtered.length),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _filtered.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _index ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.accent : AppColors.white(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (i < _filtered.length - 1) const SizedBox(width: 5),
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
                  // Handle de quien propuso la cancha (incentiva el aporte).
                  if (court.proposedBy.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.black(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_location_alt_outlined,
                                size: 9, color: AppColors.accent),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                court.proposedBy,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.grotesk(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
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
