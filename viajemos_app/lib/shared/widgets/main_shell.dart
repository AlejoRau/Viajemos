import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/role_provider.dart';
import '../../core/providers/badge_providers.dart';
import '../../features/history/data/history_repository.dart';
import '../../features/trip_completion/data/trip_completion_repository.dart';
import '../../features/trip_completion/presentation/trip_completion_dialog.dart';
import '../../features/trip_completion/presentation/passenger_review_dialog.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/chats')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialDialogs());
  }

  Future<void> _checkInitialDialogs() async {
    if (!mounted) return;
    final role = ref.read(roleProvider);

    if (role == '/driver') {
      // Update statuses first (open/full → in_progress, in_progress → indeterminate)
      try {
        await ref.read(historyRepositoryProvider).updatePastTripStatuses();
      } catch (_) {}

      // Show completion/indeterminate dialog if there are pending trips
      try {
        final pending = await ref
            .read(tripCompletionRepositoryProvider)
            .fetchDriverTripsPendingAction();

        if (pending.isNotEmpty && mounted) {
          final trip = pending.first;
          if (trip.isIndeterminate) {
            showIndeterminateTripDialog(
              context,
              trip,
              onConfirmed: (ratings) async {
                await ref.read(tripCompletionRepositoryProvider).confirmTripCompleted(
                      tripId: trip.tripId,
                      ratings: ratings,
                    );
                ref.invalidate(activeDriverTripsProvider);
                ref.invalidate(driverHistoryProvider);
              },
              onCancelled: (reason) async {
                await ref.read(tripCompletionRepositoryProvider).resolveIndeterminateTrip(
                      tripId: trip.tripId,
                      wasCompleted: false,
                      reason: reason,
                    );
                ref.invalidate(activeDriverTripsProvider);
                ref.invalidate(driverHistoryProvider);
              },
            );
          } else {
            showTripCompletionDialog(
              context,
              trip,
              onConfirmed: (ratings) async {
                await ref.read(tripCompletionRepositoryProvider).confirmTripCompleted(
                      tripId: trip.tripId,
                      ratings: ratings,
                    );
                ref.invalidate(activeDriverTripsProvider);
                ref.invalidate(driverHistoryProvider);
              },
            );
          }
        }
      } catch (_) {}
    } else {
      // Passenger: show review prompt for the first unrated completed trip
      try {
        final dismissed = ref.read(dismissedReviewsProvider);
        final completedTrips = await ref
            .read(historyRepositoryProvider)
            .fetchPassengerCompletedTrips();

        final pending = completedTrips
            .where((t) => !t.hasRated && !dismissed.contains(t.tripId))
            .toList();

        if (pending.isNotEmpty && mounted) {
          final trip = pending.first;
          showPassengerReviewDialog(
            context,
            trip,
            onSubmitted: (rating, comment) async {
              await ref.read(historyRepositoryProvider).submitDriverReview(
                    tripId: trip.tripId,
                    driverId: trip.driverId,
                    rating: rating,
                    comment: comment,
                  );
              ref.invalidate(passengerCompletedTripsProvider);
              ref.read(pendingPassengerReviewsCountProvider.notifier).refresh();
            },
            onDismissed: () {
              ref.read(dismissedReviewsProvider.notifier).update(
                    (s) => {...s, trip.tripId},
                  );
            },
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    final roleHome = ref.watch(roleProvider);
    final isDriver = roleHome == '/driver';
    final unreadCount = ref.watch(unreadCountProvider);

    // Drivers: pending trip requests; Passengers: pending invitations + pending reviews
    final int pendingCount;
    if (isDriver) {
      pendingCount = ref.watch(pendingRequestsCountProvider);
    } else {
      final invitations = ref.watch(pendingInvitationsCountProvider);
      final reviews = ref.watch(pendingPassengerReviewsCountProvider);
      pendingCount = invitations + reviews;
    }

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (idx != 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: IgnorePointer(
                child: _RoleBadge(isDriver: isDriver),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Inicio',
                  selected: idx == 0,
                  onTap: () => context.go(roleHome),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  label: 'Historial',
                  selected: idx == 1,
                  badge: pendingCount,
                  onTap: () => context.go('/history'),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  selected: idx == 2,
                  badge: unreadCount,
                  onTap: () => context.go('/chats'),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Perfil',
                  selected: idx == 3,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isDriver});
  final bool isDriver;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(isDriver),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDriver
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDriver
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFBBF7D0),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDriver
                  ? Icons.directions_car_rounded
                  : Icons.airline_seat_recline_normal_rounded,
              size: 13,
              color: isDriver
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF16A34A),
            ),
            const SizedBox(width: 5),
            Text(
              isDriver ? 'Conductor' : 'Pasajero',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDriver
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 14,
          vertical: selected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
