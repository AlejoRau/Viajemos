import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // En web, Supabase redirige de vuelta con ?code=... en la URL.
  // Intercambiamos el código por sesión antes de que corra el router,
  // para que la sesión esté lista cuando Go Router evalúe el redirect.
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('code')) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        // El código puede estar expirado o ya fue usado.
        // ignore: avoid_print
        print('[Auth] getSessionFromUrl falló: $e');
      }
    }
  }

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: ViajemosApp()));
}
