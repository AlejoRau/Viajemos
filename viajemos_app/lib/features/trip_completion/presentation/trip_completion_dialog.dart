import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/trip_completion_repository.dart';

// ── Public entry points ─────────────────────────────────────────────────────

/// Shows the "¿Finalizó tu viaje?" overlay for an in_progress trip.
/// [onConfirmed] is called after the driver rates passengers and confirms.
/// [onDismissed] is called when driver says "no, sigue en curso".
void showTripCompletionDialog(
  BuildContext context,
  TripPendingAction trip, {
  required Future<void> Function(List<PassengerRating> ratings) onConfirmed,
  VoidCallback? onDismissed,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CompletionOverlay(
      trip: trip,
      isIndeterminate: false,
      onDismiss: () {
        entry.remove();
        onDismissed?.call();
      },
      onConfirm: (ratings) async {
        await onConfirmed(ratings);
        entry.remove();
      },
    ),
  );
  Overlay.of(context).insert(entry);
}

/// Shows the "Pasaron +48hs…" overlay for an indeterminate trip.
/// The "Sí, fue realizado" path leads into the same rating UI.
/// [onConfirmed] is called when driver confirms the trip happened + rates passengers.
/// [onCancelled] is called when driver says the trip didn't happen.
void showIndeterminateTripDialog(
  BuildContext context,
  TripPendingAction trip, {
  required Future<void> Function(List<PassengerRating> ratings) onConfirmed,
  required Future<void> Function(String? reason) onCancelled,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CompletionOverlay(
      trip: trip,
      isIndeterminate: true,
      onDismiss: () => entry.remove(),
      onConfirm: (ratings) async {
        await onConfirmed(ratings);
        entry.remove();
      },
      onNotCompleted: (reason) async {
        await onCancelled(reason);
        entry.remove();
      },
    ),
  );
  Overlay.of(context).insert(entry);
}

// ── Internal overlay widget ─────────────────────────────────────────────────

enum _OverlayView { decision, rating, notCompleted }

class _CompletionOverlay extends StatefulWidget {
  const _CompletionOverlay({
    required this.trip,
    required this.isIndeterminate,
    required this.onDismiss,
    required this.onConfirm,
    this.onNotCompleted,
  });

  final TripPendingAction trip;
  final bool isIndeterminate;
  final VoidCallback onDismiss;
  final Future<void> Function(List<PassengerRating>) onConfirm;
  final Future<void> Function(String?)? onNotCompleted;

  @override
  State<_CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<_CompletionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  _OverlayView _view = _OverlayView.decision;

  // Rating state
  bool _sameRating = true;
  int _globalRating = 5;
  late List<int> _ratings;

  // "Not completed" state
  final _reasonController = TextEditingController();

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
    _ratings = List.filled(widget.trip.passengerIds.length, 5);

    // For non-indeterminate trips, skip the decision screen and go straight to rating
    if (!widget.isIndeterminate) {
      _view = _OverlayView.rating;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _animateOut(VoidCallback then) async {
    if (!mounted) return;
    await _ctrl.reverse();
    then();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final ratings = List.generate(widget.trip.passengerIds.length, (i) {
        return PassengerRating(
          passengerId: widget.trip.passengerIds[i],
          rating: _sameRating ? _globalRating : _ratings[i],
        );
      });
      await widget.onConfirm(ratings);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitNotCompleted() async {
    setState(() => _loading = true);
    try {
      final reason = _reasonController.text.trim();
      await widget.onNotCompleted?.call(reason.isEmpty ? null : reason);
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
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Blurred backdrop
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.30)),
              ),
            ),
            // Card
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                                  child: _buildBody(),
                                ),
                              ),
                              _buildFooter(),
                            ],
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

  Widget _buildBody() {
    return switch (_view) {
      _OverlayView.decision => _buildDecision(),
      _OverlayView.rating => _buildRating(),
      _OverlayView.notCompleted => _buildNotCompleted(),
    };
  }

  // ── Decision screen (indeterminate only) ───────────────────────────────────

  Widget _buildDecision() {
    final trip = widget.trip;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 12),
        const Text(
          'Viaje pendiente de confirmación',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 6),
        Text(
          'Han pasado más de 48 hs desde tu viaje:',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${trip.originAddress} → ${trip.destinationAddress}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(trip.departureDate) +
                    (trip.formattedTime.isNotEmpty ? ' · ${trip.formattedTime}' : ''),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '¿Este viaje fue realizado?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Rating screen ──────────────────────────────────────────────────────────

  Widget _buildRating() {
    final trip = widget.trip;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF16A34A).withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            widget.isIndeterminate ? '¡Confirmado!' : '¿Finalizó tu viaje?',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${trip.originAddress} → ${trip.destinationAddress}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Center(
          child: Text(
            _formatDate(trip.departureDate) +
                (trip.formattedTime.isNotEmpty ? ' · ${trip.formattedTime}' : ''),
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
        const SizedBox(height: 20),

        if (trip.passengerIds.isEmpty) ...[
          const Center(
            child: Text('Sin pasajeros confirmados.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          const SizedBox(height: 8),
        ] else ...[
          // Header row
          Row(
            children: [
              const Text(
                'Calificá a los pasajeros',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const Spacer(),
              if (trip.passengerIds.length > 1)
                GestureDetector(
                  onTap: () => setState(() => _sameRating = !_sameRating),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _sameRating
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _sameRating ? 'Igual a todos' : 'Individual',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _sameRating
                            ? const Color(0xFF065F46)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating UI
          if (_sameRating) ...[
            TripCompletionStarPicker(
              rating: _globalRating,
              onChanged: (v) => setState(() => _globalRating = v),
            ),
            const SizedBox(height: 14),
            ...List.generate(trip.passengerIds.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TripCompletionPassengerRow(
                name: i < trip.passengerNames.length ? trip.passengerNames[i] : 'Pasajero',
                avatarUrl: i < trip.passengerAvatars.length && trip.passengerAvatars[i].isNotEmpty
                    ? trip.passengerAvatars[i] : null,
                rating: _globalRating,
                showStars: false,
              ),
            )),
          ] else ...[
            ...List.generate(trip.passengerIds.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TripCompletionPassengerRow(
                name: i < trip.passengerNames.length ? trip.passengerNames[i] : 'Pasajero',
                avatarUrl: i < trip.passengerAvatars.length && trip.passengerAvatars[i].isNotEmpty
                    ? trip.passengerAvatars[i] : null,
                rating: _ratings[i],
                showStars: true,
                onChanged: (v) => setState(() => _ratings[i] = v),
              ),
            )),
          ],
        ],
      ],
    );
  }

  // ── "Not completed" screen ─────────────────────────────────────────────────

  Widget _buildNotCompleted() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Viaje no realizado',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Podés dejar un comentario opcional sobre lo que pasó.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Motivo (opcional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 14),
          _footerButtons(),
        ],
      ),
    );
  }

  Widget _footerButtons() {
    switch (_view) {
      case _OverlayView.decision:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => setState(() => _view = _OverlayView.notCompleted),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('No fue realizado', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : () => setState(() => _view = _OverlayView.rating),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Sí, fue realizado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );

      case _OverlayView.rating:
        return Row(
          children: [
            if (!widget.isIndeterminate)
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _animateOut(widget.onDismiss),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('No, sigue en curso', style: TextStyle(fontSize: 13)),
                ),
              ),
            if (!widget.isIndeterminate) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sí, finalizar ✓',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );

      case _OverlayView.notCompleted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => setState(() => _view = _OverlayView.decision),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Volver', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _submitNotCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
    }
  }
}

// ── Shared star picker ──────────────────────────────────────────────────────

class TripCompletionStarPicker extends StatelessWidget {
  const TripCompletionStarPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: rating >= star ? const Color(0xFFEAB308) : const Color(0xFFD1D5DB),
            ),
          ),
        );
      }),
    );
  }
}

// ── Passenger row widget ────────────────────────────────────────────────────

class TripCompletionPassengerRow extends StatelessWidget {
  const TripCompletionPassengerRow({
    super.key,
    required this.name,
    required this.rating,
    required this.showStars,
    this.avatarUrl,
    this.onChanged,
  });

  final String name;
  final String? avatarUrl;
  final int rating;
  final bool showStars;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE5E7EB),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF6B7280), fontSize: 14),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              if (!showStars)
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      rating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 13,
                      color: rating > i ? const Color(0xFFEAB308) : const Color(0xFFD1D5DB),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showStars) ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => onChanged?.call(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 22,
                    color: rating >= star ? const Color(0xFFEAB308) : const Color(0xFFD1D5DB),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
