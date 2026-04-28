import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "checkout_desktop.dart";
import "checkout_mobile.dart";

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      .android => const CheckoutMobile(),
      .iOS => const CheckoutMobile(),
      .linux => const CheckoutDesktop(),
      .macOS => const CheckoutDesktop(),
      .windows => const CheckoutDesktop(),
      .fuchsia => throw UnsupportedError("fuchsia is not supported, wtf lmao"),
    };
  }
}
