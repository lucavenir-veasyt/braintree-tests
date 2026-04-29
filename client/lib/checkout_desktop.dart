import "dart:async";
import "dart:convert";
import "dart:developer";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:webview_flutter/webview_flutter.dart";

const _baseUrl = String.fromEnvironment(
  "BASE_URL",
  defaultValue: "http://localhost:4000",
);

enum _PaymentState { idle, loading, paid, cancelled, error }

class CheckoutDesktop extends StatefulWidget {
  const CheckoutDesktop({super.key});

  @override
  State<CheckoutDesktop> createState() => _CheckoutDesktopState();
}

class _CheckoutDesktopState extends State<CheckoutDesktop> {
  _PaymentState _state = .idle;

  Future<void> handlePayment() async {
    setState(() {
      _state = .loading;
    });

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/api/stripe/checkout"),
        headers: {"content-type": "application/json"},
        body: json.encode({"amount": 1000}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Server error (${response.statusCode})\n${response.body}",
        );
      }

      final body = json.decode(response.body) as Map<String, Object?>;
      final url = body["url"] as String?;

      if (url == null) {
        throw Exception(
          "Invalid server response: missing url\n${response.body}",
        );
      }

      log("Opening checkout URL: $url");
      if (!mounted) return;

      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) {
            return _CheckoutWebView(checkoutUrl: url);
          },
        ),
      );

      if (!mounted) return;
      setState(() {
        _state = paid == true ? .paid : .cancelled;
      });
    } on Exception catch (e) {
      log("Checkout error: $e");
      if (!mounted) return;
      setState(() {
        _state = .error;
      });
    }
  }

  void reset() {
    setState(() {
      _state = .idle;
    });
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
          .loading => const CircularProgressIndicator(),
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

class _CheckoutWebView extends StatefulWidget {
  const _CheckoutWebView({required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<_CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<_CheckoutWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController();
    unawaited(setupWebView());
  }

  Future<void> setupWebView() async {
    await controller.setNavigationDelegate(
      .new(
        onNavigationRequest: (request) {
          if (!mounted) return .prevent;
          if (request.url.startsWith("$_baseUrl/payment/success")) {
            Navigator.of(context).pop(true);
            return .prevent;
          }
          if (request.url.startsWith("$_baseUrl/payment/cancel")) {
            Navigator.of(context).pop(false);
            return .prevent;
          }
          return .navigate;
        },
      ),
    );
    await controller.loadRequest(
      .parse(widget.checkoutUrl),
    );
  }

  @override
  void dispose() {
    unawaited(cleanup());
    super.dispose();
  }

  Future<void> cleanup() async {
    await controller.clearCache();
    await controller.clearLocalStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pagamento")),
      body: WebViewWidget(controller: controller),
    );
  }
}
