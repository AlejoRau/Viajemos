import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/role_option_card.dart';
import '../../../shared/widgets/role_switcher_title.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const RoleSwitcherTitle(),
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
