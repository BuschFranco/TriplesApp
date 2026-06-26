import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/handle_setup_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/courts_provider.dart';
import 'services/favorites_provider.dart';
import 'services/session.dart';
import 'theme/app_theme.dart';
import 'widgets/bball_glyph.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    mapsImpl.useAndroidViewSurface = true;
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
  ));
  runApp(const TriplesApp());
}

class TriplesApp extends StatelessWidget {
  const TriplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()..restore()),
        ChangeNotifierProvider(create: (_) => CourtsProvider()..load()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Triples',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _bootstrapping = true;
  bool _onboardingSeen = false;
  bool _goAuth = false;
  AuthMode _authMode = AuthMode.signup;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    if (mounted) setState(() => _bootstrapping = false);
  }

  Future<void> _leaveOnboarding(AuthMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    setState(() {
      _onboardingSeen = true;
      _goAuth = true;
      _authMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();

    if (_bootstrapping || session.restoring) return const _Splash();
    if (session.isLoggedIn) {
      // Recién registrado sin handle → forzar la elección antes de entrar.
      return session.needsHandle ? const HandleSetupScreen() : const MainShell();
    }

    if (!_onboardingSeen && !_goAuth) {
      return OnboardingScreen(
        onStart: () => _leaveOnboarding(AuthMode.signup),
        onLogin: () => _leaveOnboarding(AuthMode.login),
      );
    }
    return AuthScreen(initialMode: _authMode);
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.accentDark],
                ),
              ),
              child: const Center(child: BBallGlyph(size: 34)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
