import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/driver/presentation/driver_home_screen.dart';
import 'features/driver/presentation/create_trip_screen.dart';
import 'features/driver/presentation/passenger_requests_screen.dart' show PassengerRequestsScreen, PassengerRequestsFilterScreen;
import 'features/passenger/presentation/passenger_home_screen.dart';
import 'features/passenger/presentation/search_trips_screen.dart';
import 'features/passenger/presentation/create_request_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/chats/presentation/chats_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/passenger/presentation/search_results_screen.dart';
import 'shared/widgets/main_shell.dart';

// Notifica al router cuando cambia el estado de auth para disparar redirect.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthNotifier();

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final path = state.matchedLocation;
    final isAuthRoute = path == '/login' || path == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  routes: [
    // Auth: sin nav bar
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // Home: sin nav bar
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),

    // Rutas con nav bar inferior
    ShellRoute(
      builder: (_, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/driver', builder: (_, __) => const DriverHomeScreen()),
        GoRoute(path: '/driver/create-trip', builder: (_, __) => const CreateTripScreen()),
        GoRoute(path: '/driver/passenger-requests-filter', builder: (_, __) => const PassengerRequestsFilterScreen()),
        GoRoute(
          path: '/driver/passenger-requests',
          builder: (_, state) {
            final extra = state.extra as Map<String, String?>? ?? {};
            return PassengerRequestsScreen(
              origin: extra['origin'] ?? '',
              destination: extra['destination'] ?? '',
              dateFrom: extra['dateFrom'] ?? '',
              dateTo: extra['dateTo'] ?? '',
            );
          },
        ),
        GoRoute(path: '/passenger', builder: (_, __) => const PassengerHomeScreen()),
        GoRoute(path: '/passenger/search-trips', builder: (_, __) => const SearchTripsScreen()),
        GoRoute(
          path: '/passenger/search-results',
          builder: (_, state) {
            final extra = state.extra as Map<String, String?>? ?? {};
            return SearchResultsScreen(
              origin: extra['origin'] ?? '',
              destination: extra['destination'],
              dateFromStr: extra['dateFrom'],
              dateToStr: extra['dateTo'],
              maxPriceStr: extra['maxPrice'],
            );
          },
        ),
        GoRoute(path: '/passenger/create-request', builder: (_, __) => const CreateRequestScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/chats', builder: (_, __) => const ChatsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

class ViajemosApp extends StatelessWidget {
  const ViajemosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Viajemos',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
