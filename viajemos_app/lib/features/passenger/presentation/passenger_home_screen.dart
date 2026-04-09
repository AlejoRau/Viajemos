import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/role_option_card.dart';
import '../../../shared/widgets/role_switcher_title.dart';

class PassengerHomeScreen extends ConsumerWidget {
  const PassengerHomeScreen({super.key});

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
