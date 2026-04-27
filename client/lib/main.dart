import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_stripe/flutter_stripe.dart";

import "checkout.dart";

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
    return MaterialApp(
      home: kIsWeb
          ? const CheckoutScreen()
          : switch (defaultTargetPlatform) {
              .android => const CheckoutScreen(),
              .iOS => const CheckoutScreen(),
              final platform => throw UnsupportedError(
                "we do not support $platform yet",
              ),
            },
    );
  }
}
