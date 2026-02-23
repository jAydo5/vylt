import 'package:flutter/material.dart';

import 'app.dart';
import 'core/privacy/consent_repository.dart';
import 'core/storage/local_database.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local, on-device systems
  await LocalDatabase.init();
  await ConsentRepository.init();

  final hasAcceptedConsent =
      await ConsentRepository.instance.hasAcceptedConsent();

  runApp(
    VYLTApp(
      initialRoute:
          hasAcceptedConsent ? AppRoute.home : AppRoute.onboarding,
    ),
  );
}
