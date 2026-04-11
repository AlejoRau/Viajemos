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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MainCard(trip: widget.trip),
                          const SizedBox(height: 10),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: _shareExpanded
                                ? _ShareGrid(
                                    copied: _copied,
                                    onWhatsApp: _shareWhatsApp,
                                    onFacebook: _shareFacebook,
                                    onTwitter: _shareTwitter,
                                    onTelegram: _shareTelegram,
                                    onInstagram: _shareInstagram,
                                    onCopy: _copyText,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          if (_shareExpanded) const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionBtn(
                                  label: 'Compartir',
                                  icon: Icons.share_rounded,
                                  color: const Color(0xFF1A73E8),
                                  onTap: () => setState(() => _shareExpanded = !_shareExpanded),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionBtn(
                                  label: 'Listo',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF16A34A),
                                  onTap: _dismiss,
                                ),
                              ),
                            ],
                          ),
                        ],
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
  const _MainCard({required this.trip});
  final TripSuccess trip;

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
            color: Colors.white.withOpacity(0.95),
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
              // Check + título
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
                          color: const Color(0xFF16A34A).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Viaje publicado con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 16),

              // Ruta origen → destino
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
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
                                const Text('Salida', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                                Text(
                                  t.originCity,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
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
                              const Text('Llegada', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                              Text(
                                t.destinationCity,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
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

              // Detalles en grid: fecha, hora, asientos, precio
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.0,
                children: [
                  _DetailChip(
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF7C3AED),
                    label: dateStr,
                  ),
                  _DetailChip(
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF0891B2),
                    label: t.departureTime.isNotEmpty ? t.departureTime : 'Hora flexible',
                  ),
                  _DetailChip(
                    icon: Icons.event_seat_rounded,
                    color: const Color(0xFF1A73E8),
                    label: '${t.seats} asiento${t.seats != 1 ? "s" : ""}',
                  ),
                  _DetailChip(
                    icon: Icons.attach_money_rounded,
                    color: const Color(0xFF16A34A),
                    label: '\$${t.price} / persona',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vehículo (si tiene)
              if (t.vehicle != null) ...[
                _DetailChip(
                  icon: Icons.directions_car_rounded,
                  color: Color(t.vehicleColor ?? 0xFF6B7280),
                  label: t.vehicle!,
                  full: true,
                ),
                const SizedBox(height: 8),
              ],

              // Extras: mascotas, puerta a puerta
              if (t.acceptsPets || t.picksUpAtDoor || t.dropsOffAtDoor)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (t.acceptsPets)
                      _Tag(label: 'Acepta mascotas', icon: Icons.pets_rounded, color: const Color(0xFFD97706)),
                    if (t.picksUpAtDoor)
                      _Tag(label: 'Recoge en puerta', icon: Icons.home_rounded, color: const Color(0xFF1A73E8)),
                    if (t.dropsOffAtDoor)
                      _Tag(label: 'Deja en puerta', icon: Icons.home_work_rounded, color: const Color(0xFF7C3AED)),
                  ],
                ),

              // Rutas intermedias
              if (t.routes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ListSection(
                  icon: Icons.route_rounded,
                  color: const Color(0xFF0891B2),
                  label: 'Ruta',
                  items: t.routes,
                ),
              ],

              // Paradas
              if (t.stops.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ListSection(
                  icon: Icons.place_rounded,
                  color: const Color(0xFFD97706),
                  label: 'Paradas',
                  items: t.stops,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares de la card ─────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.color,
    required this.label,
    this.full = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return full ? SizedBox(width: double.infinity, child: child) : child;
  }
}

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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: options.map((o) => _ShareChip(opt: o)).toList(),
          ),
        ),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: opt.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(opt.icon, color: opt.color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(opt.label,
                  style: TextStyle(color: opt.color, fontSize: 11, fontWeight: FontWeight.w600),
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
