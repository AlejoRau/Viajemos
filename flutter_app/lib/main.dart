import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/main_shell.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/trip_detail/presentation/trip_detail_screen.dart';
import 'features/create_trip/presentation/create_trip_screen.dart';
import 'features/trip_requests/presentation/trip_requests_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xowrngxyiuoaamhwxzng.supabase.co',
    anonKey: 'sb_publishable_mSii79Vd_KLONR0i20F7nw_6iLgenE5',
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: ViajemosApp()));
}

class ViajemosApp extends StatelessWidget {
  const ViajemosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viajemos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const MainShell(),
        '/search': (_) => const SearchScreen(),
        '/trip-detail': (_) => const TripDetailScreen(),
        '/create-trip': (_) => const CreateTripScreen(),
        '/trip-requests': (_) => const TripRequestsScreen(),
      },
    );
  }
}
