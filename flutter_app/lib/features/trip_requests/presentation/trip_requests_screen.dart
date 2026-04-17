import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class TripRequestsScreen extends StatefulWidget {
  const TripRequestsScreen({super.key});

  @override
  State<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends State<TripRequestsScreen> {
  _Tab _activeTab = _Tab.pending;

  static const _requests = [
    _RequestData(
      id: '1',
      name: 'Ana García',
      rating: 4.8,
      trips: 15,
      imageUrl: 'https://i.pravatar.cc/150?img=9',
      message: '¡Hola! Me gustaría unirme a tu viaje, voy a visitar a mi familia en Buenos Aires.',
      status: _Tab.pending,
    ),
    _RequestData(
      id: '2',
      name: 'Juan Pérez',
      rating: 4.5,
      trips: 8,
      imageUrl: 'https://i.pravatar.cc/150?img=13',
      message: 'Hola, tengo reunión de trabajo temprano. ¿Hay lugar?',
      status: _Tab.pending,
    ),
    _RequestData(
      id: '3',
      name: 'Sofía Martínez',
      rating: 4.9,
      trips: 22,
      imageUrl: 'https://i.pravatar.cc/150?img=25',
      message: 'Buenas! Necesito llegar a Buenos Aires mañana. Puedo compartir los gastos de peaje también.',
      status: _Tab.accepted,
    ),
  ];

  List<_RequestData> get _filtered =>
      _requests.where((r) => r.status == _activeTab).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AppBar(),
          _TabBar(
            active: _activeTab,
            pendingCount: _requests.where((r) => r.status == _Tab.pending).length,
            acceptedCount: _requests.where((r) => r.status == _Tab.accepted).length,
            onTap: (t) => setState(() => _activeTab = t),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(tab: _activeTab)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _RequestCard(
                      request: _filtered[i],
                      showActions: _activeTab == _Tab.pending,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 8,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solicitudes de viaje',
                    style: AppTextStyles.h3.copyWith(color: Colors.white)),
                Text('Córdoba → Buenos Aires · Mañana 08:00',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.active,
    required this.pendingCount,
    required this.acceptedCount,
    required this.onTap,
  });
  final _Tab active;
  final int pendingCount;
  final int acceptedCount;
  final ValueChanged<_Tab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            _TabBtn(
              label: 'Pendientes ($pendingCount)',
              isActive: active == _Tab.pending,
              onTap: () => onTap(_Tab.pending),
            ),
            _TabBtn(
              label: 'Aceptados ($acceptedCount)',
              isActive: active == _Tab.accepted,
              onTap: () => onTap(_Tab.accepted),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.showActions});
  final _RequestData request;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border(
          left: BorderSide(
            color: showActions ? AppColors.accent : AppColors.primaryLight,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger info
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(request.imageUrl),
                backgroundColor: AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.name, style: AppTextStyles.h4),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(request.rating.toString(),
                            style: AppTextStyles.labelSmall),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text('${request.trips} viajes',
                              style: AppTextStyles.labelXSmall
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!showActions)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Color(0xFF059669), size: 18),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              '"${request.message}"',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),

          // Action buttons (pending only)
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Rechazar — izquierda
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                            color: AppColors.destructive, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.destructive),
                          const SizedBox(width: 6),
                          Text('Rechazar',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.destructive)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Aceptar — derecha
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('Aceptar',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});
  final _Tab tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        tab == _Tab.pending
            ? 'No hay solicitudes pendientes'
            : 'No hay solicitudes aceptadas',
        style: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum _Tab { pending, accepted }

class _RequestData {
  const _RequestData({
    required this.id,
    required this.name,
    required this.rating,
    required this.trips,
    required this.imageUrl,
    required this.message,
    required this.status,
  });
  final String id;
  final String name;
  final double rating;
  final int trips;
  final String imageUrl;
  final String message;
  final _Tab status;
}
