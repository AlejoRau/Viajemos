import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/role_option_card.dart';
import '../../../shared/widgets/role_switcher_title.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/providers/request_success_provider.dart';
import '../../../shared/widgets/request_success_overlay.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSuccess());
  }

  void _checkSuccess() {
    final success = ref.read(requestSuccessProvider);
    if (success != null && mounted) {
      ref.read(requestSuccessProvider.notifier).state = null;
      showRequestSuccessOverlay(context, request: success);
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
                label: 'Buscar Viajes Disponibles',
                subtitle: 'Encontrá un viaje publicado por un conductor',
                icon: Icons.search_rounded,
                onTap: () => context.go('/passenger/search-trips'),
              ),
              const SizedBox(height: 20),
              RoleOptionCard(
                label: 'Publicar que necesito viaje',
                subtitle: 'Avisá a los conductores que buscás un lugar',
                icon: Icons.campaign_rounded,
                onTap: () => context.go('/passenger/create-request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
