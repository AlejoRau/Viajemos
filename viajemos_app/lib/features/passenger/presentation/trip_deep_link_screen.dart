import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_search_repository.dart';
import '../domain/trip_search_result.dart';
import 'search_results_screen.dart' show showTripDetails;

class TripDeepLinkScreen extends StatefulWidget {
  const TripDeepLinkScreen({super.key, required this.tripId});
  final String tripId;

  @override
  State<TripDeepLinkScreen> createState() => _TripDeepLinkScreenState();
}

class _TripDeepLinkScreenState extends State<TripDeepLinkScreen> {
  TripSearchResult? _trip;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trip = await TripSearchRepository().fetchTripById(widget.tripId);
      if (!mounted) return;
      if (trip == null) {
        setState(() { _error = 'El viaje no existe o ya no está disponible.'; _loading = false; });
      } else {
        setState(() { _trip = trip; _loading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _trip != null) {
            showTripDetails(context, _trip!);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'No se pudo cargar el viaje.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viaje compartido')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Volver'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
