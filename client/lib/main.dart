import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_stripe/flutter_stripe.dart";

import "checkout.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (!isDesktop) {
    const stripePublicKey = String.fromEnvironment("STRIPE_PUBLISHABLE_KEY");
    Stripe.publishableKey = stripePublicKey;
    await Stripe.instance.applySettings();
  }

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale("it"),
        Locale("en"),
      ],
      home: CheckoutScreen(),
    );
  }
}
