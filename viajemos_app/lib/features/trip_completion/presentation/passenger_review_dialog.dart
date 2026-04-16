import 'dart:ui';
import 'package:flutter/material.dart';
import '../../history/data/history_repository.dart';

// ── Entry point ─────────────────────────────────────────────────────────────

/// Shows the passenger review prompt overlay for a completed trip.
/// [onSubmitted] is called with (tripId, driverId, rating, comment?) on submit.
/// [onDismissed] is called when the passenger taps "Ahora no".
void showPassengerReviewDialog(
  BuildContext context,
  PassengerCompletedTrip trip, {
  required Future<void> Function(int rating, String? comment) onSubmitted,
  required VoidCallback onDismissed,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PassengerReviewOverlay(
      trip: trip,
      onDismiss: () {
        entry.remove();
        onDismissed();
      },
      onSubmit: (rating, comment) async {
        await onSubmitted(rating, comment);
        entry.remove();
      },
    ),
  );
  Overlay.of(context).insert(entry);
}

// ── Internal overlay ─────────────────────────────────────────────────────────

class _PassengerReviewOverlay extends StatefulWidget {
  const _PassengerReviewOverlay({
    required this.trip,
    required this.onDismiss,
    required this.onSubmit,
  });

  final PassengerCompletedTrip trip;
  final VoidCallback onDismiss;
  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<_PassengerReviewOverlay> createState() => _PassengerReviewOverlayState();
}

class _PassengerReviewOverlayState extends State<_PassengerReviewOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  int _rating = 0;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _loading = true);
    try {
      final comment = _commentController.text.trim();
      await widget.onSubmit(_rating, comment.isEmpty ? null : comment);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.30)),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.6), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Star icon header
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFFF59E0B).withOpacity(0.30),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: const Icon(Icons.star_rounded,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '¿Cómo fue tu viaje?',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827)),
                                ),
                                const SizedBox(height: 6),

                                // Driver info
                                if (trip.driverAvatarUrl != null)
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage:
                                        NetworkImage(trip.driverAvatarUrl!),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    child: Text(
                                      trip.driverName.isNotEmpty
                                          ? trip.driverName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B7280)),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  trip.driverName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827)),
                                ),
                                Text(
                                  '${trip.originAddress} → ${trip.destinationAddress}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDate(trip.departureDate),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF9CA3AF)),
                                ),
                                const SizedBox(height: 20),

                                // Stars
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (i) {
                                    final star = i + 1;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _rating = star),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: Icon(
                                          _rating >= star
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 38,
                                          color: _rating >= star
                                              ? const Color(0xFFEAB308)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),

                                // Comment
                                TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  maxLength: 300,
                                  decoration: InputDecoration(
                                    hintText: 'Dejá un comentario (opcional)',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Divider(
                                    height: 1, color: Color(0xFFF3F4F6)),
                                const SizedBox(height: 14),

                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            _loading ? null : _dismiss,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF6B7280),
                                          side: const BorderSide(
                                              color: Color(0xFFD1D5DB)),
                                          minimumSize: const Size(0, 44),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Ahora no',
                                            style: TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: (_rating == 0 || _loading)
                                            ? null
                                            : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF16A34A),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 44),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white))
                                            : const Text('Calificar conductor',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600)),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
