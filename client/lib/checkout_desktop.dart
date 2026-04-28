import "dart:async";
import "dart:convert";
import "dart:developer";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:time/time.dart";
import "package:url_launcher/url_launcher.dart";

const _baseUrl = String.fromEnvironment(
  "BASE_URL",
  defaultValue: "http://localhost:4000",
);

enum _PaymentState { idle, launching, polling, paid, cancelled, error }

class CheckoutDesktop extends StatefulWidget {
  const CheckoutDesktop({super.key});

  @override
  State<CheckoutDesktop> createState() => _CheckoutDesktopState();
}

class _CheckoutDesktopState extends State<CheckoutDesktop> {
  _PaymentState _state = _PaymentState.idle;
  Timer? pollTimer;
  Timer? timeoutTimer;

  @override
  void dispose() {
    cancelTimers();
    super.dispose();
  }

  void cancelTimers() {
    pollTimer?.cancel();
    timeoutTimer?.cancel();
  }

  Future<void> handlePayment() async {
    setState(() {
      _state = .launching;
    });

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/api/stripe/checkout"),
        headers: {"content-type": "application/json"},
        body: json.encode({"amount": 1000}),
      );

      if (response.statusCode != 200) {
        throw Exception("""
Server error (${response.statusCode})
${response.body}
""");
      }

      final body = json.decode(response.body) as Map<String, Object?>;
      final url = body["url"] as String?;
      final sessionId = body["session_id"] as String?;

      if (url == null || sessionId == null) {
        throw Exception("""
Invalid server response: url is $url and session_id is $sessionId
Response body: ${response.body}
""");
      }

      log("Opening checkout URL for session: $sessionId");
      await launchUrl(Uri.parse(url), mode: .externalApplication);

      setState(() {
        _state = .polling;
      });
      startPolling(sessionId);
    } on Exception catch (e) {
      log("Checkout error: $e");
      if (!mounted) return;
      setState(() {
        _state = .error;
      });
    }
  }

  void startPolling(String sessionId) {
    // Timeout after 10 minutes
    timeoutTimer = .new(10.minutes, () {
      cancelTimers();
      if (!mounted) return;
      setState(() {
        _state = .cancelled;
      });
    });

    pollTimer = .periodic(3.seconds, (timer) async {
      try {
        final response = await http.get(
          Uri.parse("$_baseUrl/api/stripe/payment_status/$sessionId"),
        );

        if (response.statusCode != 200) return;

        final body = json.decode(response.body) as Map<String, Object?>;
        final status = body["status"] as String?;

        log("poll status for $sessionId: $status");

        if (status != "paid") return;
        cancelTimers();
        if (!mounted) return;
        setState(() {
          _state = .paid;
        });
      } on Exception catch (e) {
        log("Poll error: $e");
      }
    });
  }

  void reset() {
    cancelTimers();
    setState(() => _state = .idle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stripe Sandbox")),
      body: Center(
        child: switch (_state) {
          .idle => ElevatedButton(
            onPressed: handlePayment,
            child: const Text("sgancia €10"),
          ),
          .launching => const Column(
            mainAxisSize: .min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("apro il browser..."),
            ],
          ),
          .polling => const Column(
            mainAxisSize: .min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("in attesa della conferma del pagamento..."),
            ],
          ),
          .paid => Column(
            mainAxisSize: .min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text("pagamento riuscito!"),
              const SizedBox(height: 24),
              TextButton(onPressed: reset, child: const Text("evvai!")),
            ],
          ),
          .cancelled => Column(
            mainAxisSize: .min,
            children: [
              const Icon(Icons.cancel, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text("pagamento annullato o scaduto."),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: reset,
                child: const Text("umh... riprova"),
              ),
            ],
          ),
          .error => Column(
            mainAxisSize: .min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text("qualcosa è andato storto."),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: reset,
                child: const Text(
                  "oof",
                  style: .new(fontStyle: .italic),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
