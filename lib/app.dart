import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';

enum AppRoute {
  onboarding,
  home,
}

class VYLTApp extends StatelessWidget {
  final AppRoute initialRoute;

  const VYLTApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VYLT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      initialRoute: _routeName(initialRoute),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }

  String _routeName(AppRoute route) {
    switch (route) {
      case AppRoute.onboarding:
        return '/onboarding';
      case AppRoute.home:
        return '/home';
    }
  }
}
