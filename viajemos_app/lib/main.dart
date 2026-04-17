import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'shared/services/push_notification_service.dart';
import 'app.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Firebase debe inicializarse antes que Supabase.
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

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

  // Inicializar push notifications (pide permisos, registra token FCM).
  if (!kIsWeb) {
    await PushNotificationService.initialize();
  }

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: ViajemosApp()));
}
