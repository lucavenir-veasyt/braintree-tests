import "dart:convert";
import "dart:developer";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_stripe/flutter_stripe.dart";
import "package:http/http.dart" as http;

class CheckoutMobile extends StatefulWidget {
  const CheckoutMobile({super.key});

  @override
  State<CheckoutMobile> createState() => _CheckoutMobileState();
}

class _CheckoutMobileState extends State<CheckoutMobile> {
  Future<void> handlePayment() async {
    try {
      final url = Uri.parse("http://192.168.1.137:4000/api/stripe/payment");
      final response = await http.post(
        url,
        headers: {"content-type": "application/json"},
        body: json.encode({"amount": 1000}),
      );

      final jsonResponse = json.decode(response.body) as Map<String, Object?>;
      final clientSecret = jsonResponse["client_secret"] as String?;
      log("client secret: $clientSecret");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "VEASYT payment tests",
        ),
      );
      log("payment sheet initialized");

      await Stripe.instance.presentPaymentSheet();
      log("payment sheet presented");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("pagamento completato con successo sul dispositivo!"),
        ),
      );
    } on StripeException catch (e) {
      if (kDebugMode) {
        log("stripe exception: $e");
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        log("client exception: $e");
        log("client exception message: ${e.message}");
        log("client exception uri: ${e.uri}");
      }
    } on StripeConfigException catch (e) {
      if (kDebugMode) {
        log("stripe config exception: $e");
        log("stripe config exception message: ${e.message}");
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        log("other exception: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stripe Sandbox")),
      body: Center(
        child: ElevatedButton(
          onPressed: handlePayment,
          child: const Text("sgancia €10"),
        ),
      ),
    );
  }
}
