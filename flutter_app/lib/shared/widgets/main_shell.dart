import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/my_trips/presentation/my_trips_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// Shell con IndexedStack: las tabs nunca pushean rutas,
/// así no hay flecha de atrás entre pestañas.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const _screens = [
    HomeScreen(),
    MyTripsScreen(),
    _Placeholder(label: 'Chat'),
    _Placeholder(label: 'Notificaciones'),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Pantalla temporal para tabs sin implementar aún.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label,
          style: const TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }
}
