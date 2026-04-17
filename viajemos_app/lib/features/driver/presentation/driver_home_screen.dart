import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/role_option_card.dart';
import '../../../shared/widgets/role_switcher_title.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/providers/trip_success_provider.dart';
import '../../../shared/widgets/trip_success_overlay.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSuccess());
  }

  void _checkSuccess() {
    final success = ref.read(tripSuccessProvider);
    if (success != null && mounted) {
      ref.read(tripSuccessProvider.notifier).state = null;
      showTripSuccessOverlay(context, trip: success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const RoleSwitcherTitle(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: const [NotificationBell()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoleOptionCard(
                label: 'Crear un viaje',
                icon: Icons.location_on,
                onTap: () => context.go('/driver/create-trip'),
              ),
              const SizedBox(height: 20),
              RoleOptionCard(
                label: 'Ver pedidos de pasajeros',
                icon: Icons.format_list_bulleted,
                onTap: () => context.go('/driver/passenger-requests-filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
