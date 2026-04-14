// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/trip_success_provider.dart';

void showTripSuccessOverlay(BuildContext context, {required TripSuccess trip}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TripSuccessOverlay(
      trip: trip,
      onDismiss: () => entry.remove(),
    ),
  );
  Overlay.of(context).insert(entry);
}

class _TripSuccessOverlay extends StatefulWidget {
  const _TripSuccessOverlay({required this.trip, required this.onDismiss});
  final TripSuccess trip;
  final VoidCallback onDismiss;

  @override
  State<_TripSuccessOverlay> createState() => _TripSuccessOverlayState();
}

class _TripSuccessOverlayState extends State<_TripSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _dismissing = false;
  bool _shareExpanded = false;
  bool _copied = false;

  String get _shareText {
    final t = widget.trip;
    final d = t.departureDate;
    final date = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    return '🚗 ¡Viaje disponible en Viajemos!\n'
        'De ${t.originCity} a ${t.destinationCity}\n'
        '📅 $date${t.departureTime.isNotEmpty ? " · ${t.departureTime}" : ""}\n'
        '💺 ${t.seats} asiento${t.seats != 1 ? "s" : ""} · \$${t.price} por persona\n'
        '¡Sumate al viaje!';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
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

  void _openUrl(String url) => html.window.open(url, '_blank');

  void _shareWhatsApp() =>
      _openUrl('https://wa.me/?text=${Uri.encodeComponent(_shareText)}');

  void _shareFacebook() => _openUrl(
      'https://www.facebook.com/sharer/sharer.php?quote=${Uri.encodeComponent(_shareText)}');

  void _shareTwitter() => _openUrl(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareText)}');

  void _shareTelegram() => _openUrl(
      'https://t.me/share/url?url=https%3A%2F%2Fviajemos.app&text=${Uri.encodeComponent(_shareText)}');

  void _shareInstagram() {
    Clipboard.setData(ClipboardData(text: _shareText));
    _openUrl('https://www.instagram.com');
    setState(() => _copied = true);
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _shareText));
    setState(() => _copied = true);
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
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 18),
                    child: SingleChildScrollView(
                      child: _MainCard(
                        trip: widget.trip,
                        shareExpanded: _shareExpanded,
                        copied: _copied,
                        onDismiss: _dismiss,
                        onToggleShare: () => setState(() => _shareExpanded = !_shareExpanded),
                        onWhatsApp: _shareWhatsApp,
                        onFacebook: _shareFacebook,
                        onTwitter: _shareTwitter,
                        onTelegram: _shareTelegram,
                        onInstagram: _shareInstagram,
                        onCopy: _copyText,
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

// ─── Card principal ─────────────────────────────────────────────────────────────

class _MainCard extends StatefulWidget {
  const _MainCard({
    required this.trip,
    required this.shareExpanded,
    required this.copied,
    required this.onDismiss,
    required this.onToggleShare,
    required this.onWhatsApp,
    required this.onFacebook,
    required this.onTwitter,
    required this.onTelegram,
    required this.onInstagram,
    required this.onCopy,
  });
  final TripSuccess trip;
  final bool shareExpanded;
  final bool copied;
  final VoidCallback onDismiss;
  final VoidCallback onToggleShare;
  final VoidCallback onWhatsApp, onFacebook, onTwitter, onTelegram, onInstagram, onCopy;

  @override
  State<_MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<_MainCard> with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 160), _checkCtrl.forward);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final d = t.departureDate;
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    const dias = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    final dateStr = '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.13),
                  blurRadius: 28,
                  offset: const Offset(0, 10)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Check animado + título ──────────────────────────────────────
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
                          color: const Color(0xFF16A34A).withOpacity(0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '¡Viaje publicado con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 18),

              // ── Ruta origen → destino ───────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    // Origen
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A73E8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(width: 2, height: 28, color: const Color(0xFFD1D5DB)),
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
                                    style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                                Text(
                                  t.originCity,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                ),
                                if (t.originAddress.isNotEmpty && t.originAddress != t.originCity)
                                  Text(
                                    t.originAddress,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF16A34A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Llegada',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                              Text(
                                t.destinationCity,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              ),
                              if (t.destinationAddress.isNotEmpty && t.destinationAddress != t.destinationCity)
                                Text(
                                  t.destinationAddress,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Info: fecha + hora ──────────────────────────────────────────
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
                      value: t.departureTime.isNotEmpty ? t.departureTime : 'Flexible',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Info: asientos + precio ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.event_seat_rounded,
                      iconColor: const Color(0xFF1A73E8),
                      label: 'Asientos',
                      value: '${t.seats} disponible${t.seats != 1 ? "s" : ""}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.monetization_on_rounded,
                      iconColor: const Color(0xFF16A34A),
                      label: 'Precio',
                      value: '\$${t.price} / persona',
                    ),
                  ),
                ],
              ),

              // ── Vehículo ────────────────────────────────────────────────────
              if (t.vehicle != null) ...[
                const SizedBox(height: 8),
                _InfoItem(
                  icon: Icons.directions_car_rounded,
                  iconColor: Color(t.vehicleColor ?? 0xFF6B7280),
                  label: 'Vehículo',
                  value: t.vehicle!,
                  full: true,
                ),
              ],

              // ── Extras: mascotas, puerta a puerta ──────────────────────────
              if (t.acceptsPets || t.picksUpAtDoor || t.dropsOffAtDoor) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (t.acceptsPets)
                      _Tag(label: 'Acepta mascotas', icon: Icons.pets_rounded,
                          color: const Color(0xFFD97706)),
                    if (t.picksUpAtDoor)
                      _Tag(label: 'Recoge en puerta', icon: Icons.home_rounded,
                          color: const Color(0xFF1A73E8)),
                    if (t.dropsOffAtDoor)
                      _Tag(label: 'Deja en puerta', icon: Icons.home_work_rounded,
                          color: const Color(0xFF7C3AED)),
                  ],
                ),
              ],

              // ── Rutas intermedias ───────────────────────────────────────────
              if (t.routes.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ListSection(
                  icon: Icons.route_rounded,
                  color: const Color(0xFF0891B2),
                  label: 'Ruta',
                  items: t.routes,
                ),
              ],

              // ── Paradas ─────────────────────────────────────────────────────
              if (t.stops.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ListSection(
                  icon: Icons.place_rounded,
                  color: const Color(0xFFD97706),
                  label: 'Paradas',
                  items: t.stops,
                ),
              ],

              // ── Share grid (dentro de la card) ──────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: widget.shareExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _ShareGrid(
                          copied: widget.copied,
                          onWhatsApp: widget.onWhatsApp,
                          onFacebook: widget.onFacebook,
                          onTwitter: widget.onTwitter,
                          onTelegram: widget.onTelegram,
                          onInstagram: widget.onInstagram,
                          onCopy: widget.onCopy,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Divider + botones ────────────────────────────────────────────
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Listo — primario, a la izquierda
                  Expanded(
                    child: _ActionBtn(
                      label: 'Listo',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF16A34A),
                      filled: true,
                      onTap: widget.onDismiss,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Compartir — secundario (outlined), a la derecha
                  Expanded(
                    child: _ActionBtn(
                      label: widget.shareExpanded ? 'Ocultar' : 'Compartir',
                      icon: Icons.share_rounded,
                      color: const Color(0xFF1A73E8),
                      filled: false,
                      onTap: widget.onToggleShare,
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

// ─── Info item ──────────────────────────────────────────────────────────────────
// Neutral background + colored icon + dark text = buen contraste

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.full = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
    return full ? SizedBox(width: double.infinity, child: child) : child;
  }
}

// ─── Tag ────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

// ─── List section ───────────────────────────────────────────────────────────────

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.icon,
    required this.color,
    required this.label,
    required this.items,
  });
  final IconData icon;
  final Color color;
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item,
                  style: TextStyle(
                      fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Grid de compartir ──────────────────────────────────────────────────────────

class _ShareGrid extends StatelessWidget {
  const _ShareGrid({
    required this.copied,
    required this.onWhatsApp,
    required this.onFacebook,
    required this.onTwitter,
    required this.onTelegram,
    required this.onInstagram,
    required this.onCopy,
  });

  final bool copied;
  final VoidCallback onWhatsApp, onFacebook, onTwitter, onTelegram, onInstagram, onCopy;

  @override
  Widget build(BuildContext context) {
    final options = [
      _ShareOpt('WhatsApp', const Color(0xFF25D366), Icons.chat_rounded, onWhatsApp),
      _ShareOpt('Facebook', const Color(0xFF1877F2), Icons.facebook_rounded, onFacebook),
      _ShareOpt('X / Twitter', Colors.black87, Icons.alternate_email_rounded, onTwitter),
      _ShareOpt('Telegram', const Color(0xFF229ED9), Icons.send_rounded, onTelegram),
      _ShareOpt('Instagram', const Color(0xFFE1306C), Icons.camera_alt_rounded, onInstagram),
      _ShareOpt(
        copied ? '¡Copiado!' : 'Copiar',
        copied ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
        copied ? Icons.check_rounded : Icons.copy_rounded,
        onCopy,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 2.4,
        children: options.map((o) => _ShareChip(opt: o)).toList(),
      ),
    );
  }
}

class _ShareOpt {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ShareOpt(this.label, this.color, this.icon, this.onTap);
}

class _ShareChip extends StatelessWidget {
  const _ShareChip({required this.opt});
  final _ShareOpt opt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: opt.color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: opt.onTap,
        borderRadius: BorderRadius.circular(9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(opt.icon, color: opt.color, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(opt.label,
                  style: TextStyle(
                      color: opt.color, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón de acción ────────────────────────────────────────────────────────────

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
