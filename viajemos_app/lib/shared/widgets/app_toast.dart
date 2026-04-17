import 'package:flutter/material.dart';

// ── Toast type ────────────────────────────────────────────────────────────────

enum ToastType { success, error, warning, info }

extension _ToastStyle on ToastType {
  Color get bg {
    return switch (this) {
      ToastType.success => const Color(0xFFF0FDF4),
      ToastType.error   => const Color(0xFFFEF2F2),
      ToastType.warning => const Color(0xFFFFFBEB),
      ToastType.info    => const Color(0xFFEFF6FF),
    };
  }

  Color get fg {
    return switch (this) {
      ToastType.success => const Color(0xFF16A34A),
      ToastType.error   => const Color(0xFFDC2626),
      ToastType.warning => const Color(0xFFD97706),
      ToastType.info    => const Color(0xFF1D4ED8),
    };
  }

  Color get border {
    return switch (this) {
      ToastType.success => const Color(0xFFBBF7D0),
      ToastType.error   => const Color(0xFFFECACA),
      ToastType.warning => const Color(0xFFFDE68A),
      ToastType.info    => const Color(0xFFBFDBFE),
    };
  }

  IconData get icon {
    return switch (this) {
      ToastType.success => Icons.check_circle_rounded,
      ToastType.error   => Icons.error_rounded,
      ToastType.warning => Icons.warning_rounded,
      ToastType.info    => Icons.info_rounded,
    };
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Dismiss any existing toast immediately
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastEntry(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

// ── Overlay entry widget ──────────────────────────────────────────────────────

class _ToastEntry extends StatefulWidget {
  const _ToastEntry({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastEntry> createState() => _ToastEntryState();
}

class _ToastEntryState extends State<_ToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.type;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: style.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: style.fg.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: style.fg.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(style.icon,
                            color: style.fg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: style.fg,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(Icons.close_rounded,
                            size: 18,
                            color: style.fg.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
