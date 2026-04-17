import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler para mensajes recibidos cuando la app está cerrada (background/terminated).
// Debe ser una función top-level (fuera de cualquier clase).
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // FCM muestra la notificación del sistema automáticamente.
  // No se necesita hacer nada aquí salvo inicializar dependencias si fuera necesario.
}

class PushNotificationService {
  PushNotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'viajemos_high_importance';
  static const _channelName = 'Notificaciones Viajemos';
  static const _channelDesc =
      'Notificaciones de viajes, solicitudes y mensajes';

  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
  );

  /// Inicializar el servicio. Llamar una sola vez en main() luego de Firebase.
  static Future<void> initialize() async {
    // Registrar handler de background antes que cualquier otra cosa.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Pedir permiso (iOS muestra diálogo; Android 13+ también).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Canal de alta importancia para Android 8+.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Inicializar flutter_local_notifications (para foreground).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Mensajes cuando la app está en primer plano → mostrar notificación local.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Escuchar cambios de auth: registrar token al loguear, limpiar al desloguear.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        registerToken();
      }
    });

    // Si ya hay sesión activa al iniciar, registrar de una.
    if (Supabase.instance.client.auth.currentSession != null) {
      await registerToken();
    }

    // Actualizar token si FCM lo rota.
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  /// Mostrar la notificación en pantalla cuando la app está en primer plano.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Obtener el FCM token del dispositivo y guardarlo en Supabase.
  static Future<void> registerToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('[FCM] Error al obtener token: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : 'android';

    try {
      await Supabase.instance.client.from('push_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
        },
        onConflict: 'token',
      );
      debugPrint('[FCM] Token registrado ($platform)');
    } catch (e) {
      debugPrint('[FCM] Error al guardar token: $e');
    }
  }

  /// Eliminar el token del dispositivo actual. Llamar antes de hacer signOut.
  static Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('push_tokens')
            .delete()
            .eq('token', token);
      }
      await _messaging.deleteToken();
      debugPrint('[FCM] Token eliminado');
    } catch (e) {
      debugPrint('[FCM] Error al eliminar token: $e');
    }
  }
}
