import "dart:async";
import "dart:convert";
import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter_stripe_web/flutter_stripe_web.dart";
import "package:http/http.dart" as http;
import "package:web/web.dart" as web;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _clientSecret;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchClientSecret());
  }

  Future<void> _fetchClientSecret() async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:4000/api/stripe/payment"),
        headers: {"content-type": "application/json"},
        body: json.encode({"amount": 1000}), // amount in cents
      );
      final decoded = json.decode(response.body);
      final body = decoded as Map<String, Object?>;
      setState(() {
        _clientSecret = body["client_secret"] as String?;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _handlePay() async {
    log("payment intent started");
    final intent = await WebStripe.instance.confirmPaymentElement(
      ConfirmPaymentElementOptions(
        confirmParams: ConfirmPaymentParams(
          return_url: web.window.location.href,
        ),
      ),
    );
    log("payment intent result: $intent");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stripe Sandbox")),
      body: Center(
        child: switch ((_clientSecret, _error)) {
          (_, final String e) => Text("Error: $e"),
          (null, _) => const Text("Loading..."),
          (final secret?, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PaymentElement(
                autofocus: true,
                enablePostalCode: true,
                onCardChanged: (details) {},
                clientSecret: secret,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handlePay,
                child: const Text("sgancia €10"),
              ),
            ],
          ),
        },
      ),
    );
  }
}
