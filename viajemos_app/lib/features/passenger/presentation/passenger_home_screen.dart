import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/role_option_card.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pasajero', style: AppTextStyles.passengerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoleOptionCard(
                label: 'Buscar viajes',
                icon: Icons.search_rounded,
                onTap: () => context.go('/passenger/search-trips'),
              ),
              const SizedBox(height: 20),
              RoleOptionCard(
                label: 'Publicar que busco viaje',
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
