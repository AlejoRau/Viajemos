import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/driver/presentation/driver_home_screen.dart';
import 'features/driver/presentation/create_trip_screen.dart';
import 'features/driver/presentation/passenger_requests_screen.dart';
import 'features/passenger/presentation/passenger_home_screen.dart';
import 'features/passenger/presentation/search_trips_screen.dart';
import 'features/passenger/presentation/create_request_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/chats/presentation/chats_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/passenger/presentation/search_results_screen.dart';
import 'shared/widgets/main_shell.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
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
        GoRoute(path: '/driver/passenger-requests', builder: (_, __) => const PassengerRequestsScreen()),
        GoRoute(path: '/passenger', builder: (_, __) => const PassengerHomeScreen()),
        GoRoute(path: '/passenger/search-trips', builder: (_, __) => const SearchTripsScreen()),
        GoRoute(path: '/passenger/search-results', builder: (_, __) => const SearchResultsScreen()),
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
