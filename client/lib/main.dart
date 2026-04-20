import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_stripe/flutter_stripe.dart";

import "checkout_web.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripePublicKey = String.fromEnvironment("STRIPE_PUBLISHABLE_KEY");
  Stripe.publishableKey = stripePublicKey;
  await Stripe.instance.applySettings();

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
      home: CheckoutScreenWeb(),
    );
  }
}
