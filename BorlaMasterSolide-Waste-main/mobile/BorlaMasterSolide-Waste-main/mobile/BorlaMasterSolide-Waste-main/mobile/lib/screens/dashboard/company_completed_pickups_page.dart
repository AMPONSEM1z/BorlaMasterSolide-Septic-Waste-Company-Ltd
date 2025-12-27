import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyCompletedPickupsPage extends StatefulWidget {
  const CompanyCompletedPickupsPage({super.key});

  @override
  State<CompanyCompletedPickupsPage> createState() =>
      _CompanyCompletedPickupsPageState();
}

class _CompanyCompletedPickupsPageState
    extends State<CompanyCompletedPickupsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<dynamic> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedPickups();
  }

  Future<void> _loadCompletedPickups() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch completed bookings with **customer profile info**
      // Explicitly specify the customer relationship to avoid errors
      final data = await supabase
          .from('bookings')
          .select(
              '*, profiles!bookings_customer_fk(full_name, email, phone_number), companies(company_name)')
          .eq('company_id', user.id)
          .eq('status', 'completed')
          .order('pickup_date', ascending: false);

      setState(() => bookings = data);
      debugPrint('✅ Fetched ${data.length} completed bookings.');
    } catch (e) {
      debugPrint('❌ Error fetching completed pickups: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(rawDate);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('Completed Pickups'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCompletedPickups,
        color: Colors.redAccent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent))
              : bookings.isEmpty
                  ? const Center(
                      child: Text('No completed pickups.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16)))
                  : ListView.separated(
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        final customer = b['profiles'] ?? {};
                        final company = b['companies'] ?? {};

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      b['waste_type'] ?? 'Unknown',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _formatDate(b['pickup_date']),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Customer: ${customer['full_name'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Email: ${customer['email'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Phone: ${customer['phone_number'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Company: ${company['company_name'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Cost: GHS ${b['actual_cost'] ?? '0.00'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
