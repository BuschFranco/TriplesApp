import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/courts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_tab_bar.dart';
import 'crew_screen.dart';
import 'create_screen.dart';
import 'detail_screen.dart';
import 'filters_screen.dart';
import 'home_screen.dart';
import 'list_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;
  String? _detailCourtId;
  bool _filtersOpen = false;

  // +1 → new screen enters from the right (going "forward"),
  // -1 → enters from the left (going "back").
  int _slideDir = 1;

  // Cancha a centrar en el mapa al volver al Home (desde el detalle).
  String? _focusCourtId;

  // Unique key for the currently visible screen, so AnimatedSwitcher
  // knows when to run the transition.
  String get _screenKey {
    if (_filtersOpen) return 'filters';
    if (_detailCourtId != null) return 'detail:$_detailCourtId';
    return 'tab:${_tab.name}';
  }

  void _selectTab(AppTab t) {
    if (t == _tab) return;
    setState(() {
      _slideDir = t.index >= _tab.index ? 1 : -1;
      _tab = t;
    });
  }

  void _openDetail(String id) => setState(() {
        _slideDir = 1;
        _detailCourtId = id;
      });

  void _closeDetail() => setState(() {
        _slideDir = -1;
        _detailCourtId = null;
      });

  void _openFilters() => setState(() {
        _slideDir = 1;
        _filtersOpen = true;
      });

  void _closeFilters() => setState(() {
        _slideDir = -1;
        _filtersOpen = false;
      });

  // Desde el detalle: ir al mapa (Home) centrado en la cancha.
  void _showOnMap(String courtId) => setState(() {
        _slideDir = -1;
        _detailCourtId = null;
        _filtersOpen = false;
        _tab = AppTab.home;
        _focusCourtId = courtId;
      });

  Widget _slideTransition(Widget child, Animation<double> animation, Key currentKey) {
    final incoming = child.key == currentKey;
    final beginX = (incoming ? _slideDir : -_slideDir) * 0.22;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(beginX, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courts = context.watch<CourtsProvider>().courts;
    final hideTabs = _detailCourtId != null || _filtersOpen;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Home (mapa) persistente: queda SIEMPRE montado (no se recrea el platform
    // view) y solo se oculta con Offstage cuando no estás en Home o hay overlay,
    // para no renderizarlo de gusto. Lo demás se anima con slide por encima.
    final homeLayer = Offstage(
      offstage: _tab != AppTab.home || hideTabs,
      child: HomeScreen(
        courts: courts,
        focusCourtId: _focusCourtId,
        onFocusConsumed: () => _focusCourtId = null,
        onSelectCourt: _openDetail,
        onOpenFilters: _openFilters,
      ),
    );

    // Contenido de la pestaña activa (transparente sobre el mapa en Home).
    final Widget tabContent = switch (_tab) {
      AppTab.home => const IgnorePointer(
          key: ValueKey('tab:home'),
          child: SizedBox.expand(),
        ),
      AppTab.list => ListScreen(
          key: const ValueKey('tab:list'),
          courts: courts,
          onSelectCourt: _openDetail,
        ),
      AppTab.plus => const CreateScreen(key: ValueKey('tab:plus')),
      AppTab.chat => const CrewScreen(key: ValueKey('tab:chat')),
      AppTab.profile => const ProfileScreen(key: ValueKey('tab:profile')),
    };
    final tabKey = ValueKey('tab:${_tab.name}');

    // Overlay (detalle / filtros) por encima de todo, con slide.
    Widget overlay = const SizedBox.shrink(key: ValueKey('none'));
    if (_filtersOpen) {
      overlay = FiltersScreen(key: const ValueKey('filters'), onBack: _closeFilters);
    } else if (_detailCourtId != null) {
      overlay = DetailScreen(
        key: ValueKey('detail:$_detailCourtId'),
        courtId: _detailCourtId!,
        courts: courts,
        onBack: _closeDetail,
        onShowOnMap: _showOnMap,
      );
    }
    final overlayKey = ValueKey(_screenKey);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: homeLayer),
          // Pestañas (no-Home) con slide horizontal direccional.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => _slideTransition(child, anim, tabKey),
              child: KeyedSubtree(key: tabKey, child: tabContent),
            ),
          ),
          // Overlay detalle/filtros.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !hideTabs,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => _slideTransition(child, anim, overlayKey),
                child: KeyedSubtree(key: overlayKey, child: overlay),
              ),
            ),
          ),
          if (!hideTabs)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + bottomInset,
              child: AppTabBar(active: _tab, onChange: _selectTab),
            ),
        ],
      ),
    );
  }
}
