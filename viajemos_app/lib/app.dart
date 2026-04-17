import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/badge_providers.dart';
import 'features/notifications/data/notifications_provider.dart';
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
import 'features/history/data/history_repository.dart';
import 'features/chats/presentation/chats_screen.dart';
import 'features/chats/presentation/chat_detail_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/data/profile_provider.dart';
import 'features/passenger/presentation/search_results_screen.dart';
import 'features/passenger/presentation/trip_deep_link_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
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

    // Notifications: sin nav bar
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),

    // Chat detail: sin nav bar
    GoRoute(
      path: '/chats/:id',
      builder: (_, state) {
        final extra = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
        return ChatDetailScreen(
          chatId: state.pathParameters['id']!,
          contactName: extra['contactName'] as String? ?? 'Conversación',
          contactId: extra['contactId'] as String?,
          tripId: extra['tripId'] as String?,
          isGroupChat: extra['isGroupChat'] as bool? ?? false,
          participantsCount: extra['participantsCount'] as int? ?? 2,
        );
      },
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
            final extra = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
            return PassengerRequestsScreen(
              origin: extra['origin'] as String? ?? '',
              destination: extra['destination'] as String? ?? '',
              dateFrom: extra['dateFrom'] as String? ?? '',
              dateTo: extra['dateTo'] as String? ?? '',
            );
          },
        ),
        GoRoute(path: '/passenger', builder: (_, __) => const PassengerHomeScreen()),
        GoRoute(path: '/passenger/search-trips', builder: (_, __) => const SearchTripsScreen()),
        GoRoute(
          path: '/passenger/search-results',
          builder: (_, state) {
            final extra = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
            return SearchResultsScreen(
              origin: extra['origin'] as String? ?? '',
              destination: extra['destination'] as String?,
              dateFromStr: extra['dateFrom'] as String?,
              dateToStr: extra['dateTo'] as String?,
              maxPriceStr: extra['maxPrice'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/passenger/create-request',
          builder: (_, state) {
            final extra = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
            return CreateRequestScreen(
              prefillOrigin: extra['origin'] as String?,
              prefillDestination: extra['destination'] as String?,
              prefillDateFrom: extra['dateFrom'] as DateTime?,
              prefillDateTo: extra['dateTo'] as DateTime?,
            );
          },
        ),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/chats', builder: (_, __) => const ChatsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(
          path: '/viaje/:id',
          builder: (_, state) => TripDeepLinkScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ],
);

class ViajemosApp extends ConsumerStatefulWidget {
  const ViajemosApp({super.key});

  @override
  ConsumerState<ViajemosApp> createState() => _ViajemosAppState();
}

class _ViajemosAppState extends ConsumerState<ViajemosApp> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        // Invalidate all user-specific providers so they re-fetch with the new session
        ref.invalidate(profileProvider);
        ref.invalidate(passengerActiveRequestsProvider);
        ref.invalidate(passengerCompletedTripsProvider);
        ref.invalidate(myTripAlertsProvider);
        ref.invalidate(activeDriverTripsProvider);
        ref.invalidate(driverHistoryProvider);
        ref.read(unreadCountProvider.notifier).refresh();
        ref.read(pendingInvitationsCountProvider.notifier).refresh();
        ref.read(pendingRequestsCountProvider.notifier).refresh();
        ref.read(notificationUnreadCountProvider.notifier).refresh();
        ref.read(notificationsListProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

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
