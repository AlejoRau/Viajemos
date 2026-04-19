import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/request_success_provider.dart';

void showRequestSuccessOverlay(BuildContext context,
    {required RequestSuccess request}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _RequestSuccessOverlay(
      request: request,
      onDismiss: () => entry.remove(),
    ),
  );
  Overlay.of(context).insert(entry);
}

class _RequestSuccessOverlay extends StatefulWidget {
  const _RequestSuccessOverlay(
      {required this.request, required this.onDismiss});
  final RequestSuccess request;
  final VoidCallback onDismiss;

  @override
  State<_RequestSuccessOverlay> createState() => _RequestSuccessOverlayState();
}

class _RequestSuccessOverlayState extends State<_RequestSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _dismissing = false;

  String get _shareText {
    final r = widget.request;
    final d = r.dateFrom;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    final timeStr =
        r.timeFrom.isNotEmpty ? ' entre las ${r.timeFrom}' : '';
    return '¡Busco viaje de ${r.originCity} a ${r.destinationCity} el $date$timeStr! 🧳\n\n'
        'Si viajás esa fecha avisame por Viajemos.';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.90, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  Future<void> _shareNative() async {
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Texto copiado al portapapeles')),
        );
      }
    } else {
      Share.share(_shareText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                      color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isWide ? 0 : 18),
                    child: SingleChildScrollView(
                      child: _MainCard(
                        request: widget.request,
                        onDismiss: _dismiss,
                        onShare: _shareNative,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card principal ──────────────────────────────────────────────────────────

class _MainCard extends StatefulWidget {
  const _MainCard({
    required this.request,
    required this.onDismiss,
    required this.onShare,
  });
  final RequestSuccess request;
  final VoidCallback onDismiss;
  final VoidCallback onShare;

  @override
  State<_MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<_MainCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _checkScale =
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 160), _checkCtrl.forward);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final dateStr = r.dateTo != null
        ? '${_fmtDate(r.dateFrom)} – ${_fmtDate(r.dateTo!)}'
        : _fmtDate(r.dateFrom);
    final horaStr = r.timeFrom.isNotEmpty
        ? (r.timeTo.isNotEmpty ? '${r.timeFrom} – ${r.timeTo}' : r.timeFrom)
        : 'Flexible';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 28,
                  offset: const Offset(0, 10)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Check animado + título ────────────────────────────────────
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '¡Pedido publicado con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 18),

              // ── Ruta origen → destino ─────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    // Origen
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A73E8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                                width: 2,
                                height: 28,
                                color: const Color(0xFFD1D5DB)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Salida',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500)),
                                Text(r.originCity,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Destino
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: Color(0xFF16A34A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Llegada',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w500)),
                              Text(r.destinationCity,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Info: fecha + hora ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      label: 'Fecha',
                      value: dateStr,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFF0891B2),
                      label: 'Hora',
                      value: horaStr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Info: asientos + precio ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.event_seat_rounded,
                      iconColor: const Color(0xFF1A73E8),
                      label: 'Asientos',
                      value: '${r.seats} lugar${r.seats != 1 ? "es" : ""}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.monetization_on_rounded,
                      iconColor: const Color(0xFF16A34A),
                      label: 'Precio máx.',
                      value: '\$${r.maxPrice} / asiento',
                    ),
                  ),
                ],
              ),

              // ── Tag: mascota ──────────────────────────────────────────────
              if (r.hasPet) ...[
                const SizedBox(height: 12),
                _Tag(
                  label: 'Viaja con mascota',
                  icon: Icons.pets_rounded,
                  color: const Color(0xFFD97706),
                ),
              ],

              // ── Botones ───────────────────────────────────────────────────
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Compartir',
                      icon: Icons.share_rounded,
                      color: const Color(0xFF1A73E8),
                      filled: true,
                      onTap: widget.onShare,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Listo',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF16A34A),
                      filled: true,
                      onTap: widget.onDismiss,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info item ───────────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tag ─────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Botón de acción ─────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color, width: 1.5),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled ? Colors.white : color, size: 14),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: filled ? Colors.white : color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
