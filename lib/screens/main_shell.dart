import 'package:flutter/material.dart';
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

  Widget _buildScreen() {
    if (_filtersOpen) {
      return FiltersScreen(
        onBack: () => setState(() => _filtersOpen = false),
      );
    }
    if (_detailCourtId != null) {
      return DetailScreen(
        courtId: _detailCourtId!,
        onBack: () => setState(() => _detailCourtId = null),
      );
    }
    return switch (_tab) {
      AppTab.home => HomeScreen(
          onSelectCourt: (id) => setState(() => _detailCourtId = id),
          onOpenFilters: () => setState(() => _filtersOpen = true),
        ),
      AppTab.list => ListScreen(
          onSelectCourt: (id) => setState(() => _detailCourtId = id),
        ),
      AppTab.plus => const CreateScreen(),
      AppTab.chat => const CrewScreen(),
      AppTab.profile => const ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hideTabs = _detailCourtId != null || _filtersOpen;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildScreen()),
          if (!hideTabs)
            Positioned(
              left: 16,
              right: 16,
              bottom: 28,
              child: AppTabBar(
                active: _tab,
                onChange: (t) => setState(() => _tab = t),
              ),
            ),
        ],
      ),
    );
  }
}
