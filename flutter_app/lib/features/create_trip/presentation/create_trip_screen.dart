import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  int _seats = 3;

  void _submit() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  _RouteMapPlaceholder(),
                  const SizedBox(height: 16),
                  _FormField(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.primary,
                    child: TextField(
                      style: _inputStyle,
                      decoration: _inputDeco('Escribir ciudad inicio'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FormField(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.accent,
                    child: TextField(
                      style: _inputStyle,
                      decoration: _inputDeco('Escribir ciudad destino'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          icon: Icons.calendar_today_outlined,
                          iconColor: AppColors.primaryLight,
                          child: TextField(
                            style: _inputStyle,
                            decoration: _inputDeco('dd/mm/aaaa'),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FormField(
                          icon: Icons.access_time_rounded,
                          iconColor: AppColors.primaryLight,
                          child: TextField(
                            style: _inputStyle,
                            decoration: _inputDeco('hh:mm'),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SeatsSelector(
                    seats: _seats,
                    onDecrement: () =>
                        setState(() => _seats = (_seats - 1).clamp(1, 8)),
                    onIncrement: () =>
                        setState(() => _seats = (_seats + 1).clamp(1, 8)),
                  ),
                  const SizedBox(height: 10),
                  _FormField(
                    icon: Icons.attach_money_rounded,
                    iconColor: AppColors.accent,
                    child: TextField(
                      style: _inputStyle,
                      decoration: _inputDeco('Precio por asiento'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      maxLines: 4,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Agregar comentario (opcional)',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text('Publicar viaje', style: AppTextStyles.button),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      );

  TextStyle get _inputStyle =>
      AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary);
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
          Text('Publicar viaje',
              style: AppTextStyles.h3.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Route map placeholder ────────────────────────────────────────────────────

class _RouteMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0x334CAF7D), Color(0x331B6B3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 2, color: AppColors.primary),
                  Positioned(
                    left: -4,
                    top: -5,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -5,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(Icons.location_on_outlined,
                size: 48, color: AppColors.primary.withOpacity(0.25)),
          ),
        ],
      ),
    );
  }
}

// ─── Form Field wrapper ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.icon,
    required this.iconColor,
    required this.child,
  });
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Seats selector ───────────────────────────────────────────────────────────

class _SeatsSelector extends StatelessWidget {
  const _SeatsSelector({
    required this.seats,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int seats;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline_rounded,
              color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Asientos disponibles',
                style: AppTextStyles.bodyMedium),
          ),
          _CounterBtn(
            icon: Icons.remove,
            onTap: onDecrement,
            active: false,
          ),
          const SizedBox(width: 16),
          Text('$seats',
              style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(width: 16),
          _CounterBtn(
            icon: Icons.add,
            onTap: onIncrement,
            active: true,
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  const _CounterBtn({
    required this.icon,
    required this.onTap,
    required this.active,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.muted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16,
            color: active ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}
