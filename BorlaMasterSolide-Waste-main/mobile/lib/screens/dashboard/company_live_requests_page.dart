import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyLiveRequestsPage extends StatefulWidget {
  const CompanyLiveRequestsPage({super.key});

  @override
  State<CompanyLiveRequestsPage> createState() =>
      _CompanyLiveRequestsPageState();
}

class _CompanyLiveRequestsPageState extends State<CompanyLiveRequestsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<dynamic> bookings = [];
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _subscribeToLiveRequests();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch bookings and join with profiles table for customer info
      final data = await supabase
          .from('bookings')
          .select(
              '*, customer:profiles!bookings_customer_fk(id, full_name, phone_number, email)')
          .eq('company_id', user.id)
          .eq('status', 'pending_company_accept')
          .order('pickup_date', ascending: true);

      setState(() => bookings = data ?? []);
    } catch (e) {
      debugPrint('Error fetching live requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching live requests: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _subscribeToLiveRequests() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _subscription = supabase
        .channel('public:bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'company_id',
            value: user.id,
          ),
          callback: (_) => _loadRequests(),
        )
        .subscribe();
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': 'pending_customer_payment'}).eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking accepted. Awaiting customer payment.')),
      );

      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting booking: $e')),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': 'cancelled'}).eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected.')),
      );

      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting booking: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_company_accept':
        return Colors.orangeAccent;
      case 'pending_customer_payment':
        return Colors.blueAccent;
      case 'completed':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : bookings.isEmpty
              ? const Center(
                  child: Text(
                    'No live requests.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    final customer = b['customer'];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  b['waste_type'] ?? 'Unknown Waste',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(b['status']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b['status'] ?? 'N/A',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pickup Date: ${b['pickup_date'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Customer: ${customer?['full_name'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Phone: ${customer?['phone_number'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Email: ${customer?['email'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Region: ${b['region'] ?? 'N/A'} | Town: ${b['town'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (b['waste_detail'] != null)
                              Text(
                                'Details: ${b['waste_detail']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                  ),
                                  onPressed: () => _acceptBooking(b['id']),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Accept'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () => _rejectBooking(b['id']),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
