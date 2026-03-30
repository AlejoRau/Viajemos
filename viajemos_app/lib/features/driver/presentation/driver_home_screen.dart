import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/role_option_card.dart';
import '../../../shared/widgets/app_background.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: AppBackground(
        child: Center(
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
                  onTap: () => context.go('/driver/passenger-requests'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
