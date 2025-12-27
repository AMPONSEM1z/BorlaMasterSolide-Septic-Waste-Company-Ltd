import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final double amount_due;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.amount_due,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final supabase = Supabase.instance.client;
  bool processing = false;

  // Get Paystack keys from .env
  String get publicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
  String get secretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: processing
            ? const CircularProgressIndicator(color: Colors.orangeAccent)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Amount: GHS ${widget.amount_due.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _startPayment() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Paystack popup is NOT supported on Web. Use Android or iOS."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (publicKey.isEmpty || secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paystack keys missing in .env file."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => processing = true);

    final user = supabase.auth.currentUser;
    final email = user?.email ?? "customer@example.com";
    final amountKobo = (widget.amount_due * 100).toInt().toString();
    final reference =
        "bk_${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}";

    try {
      await FlutterPaystackPlus.openPaystackPopup(
        context: context,
        publicKey: publicKey,
        secretKey: secretKey,
        amount: amountKobo,
        currency: "GHS",
        customerEmail: email,
        reference: reference,
        onClosed: () {
          setState(() => processing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment window closed."),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        },
        onSuccess: () async {
          // Update booking status in Supabase
          try {
            await supabase
                .from('bookings')
                .update({'status': 'paid'}).eq('id', widget.bookingId);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Payment successful!"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            }
          } catch (e) {
            debugPrint("Failed to update booking: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      "Payment succeeded but failed to update booking status."),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      debugPrint("Payment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Payment error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => processing = false);
    }
  }
}
