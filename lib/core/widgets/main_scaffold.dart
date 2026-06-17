import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../utils/app_router.dart';
import '../../features/map/presentation/pages/map_page.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _TabItem(route: AppRoutes.home, icon: Icons.home_rounded, label: 'Inicio'),
    _TabItem(route: AppRoutes.map, icon: Icons.map_outlined, label: 'Mapa'),
    _TabItem(route: AppRoutes.rewards, icon: Icons.card_giftcard_rounded, label: 'Premios'),
    _TabItem(route: AppRoutes.profile, icon: Icons.person_outline_rounded, label: 'Perfil'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.map)) return 1;
    if (location.startsWith(AppRoutes.rewards)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_tabs[i].route),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon),
            label: t.label,
          ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final String route;
  final IconData icon;
  final String label;
  const _TabItem({required this.route, required this.icon, required this.label});
}