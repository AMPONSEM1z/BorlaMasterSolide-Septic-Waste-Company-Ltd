import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyConfirmedPickupsPage extends StatefulWidget {
  const CompanyConfirmedPickupsPage({super.key});

  @override
  State<CompanyConfirmedPickupsPage> createState() =>
      _CompanyConfirmedPickupsPageState();
}

class _CompanyConfirmedPickupsPageState
    extends State<CompanyConfirmedPickupsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<dynamic> pickups = [];

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  Future<void> _loadPickups() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('bookings')
          .select()
          .eq('company_id', user.id)
          .eq('status', 'pending_company_pickup')
          .order('pickup_date', ascending: true);
      setState(() => pickups = response);
    } catch (e) {
      debugPrint('Error loading pickups: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _confirmPickup(String id) async {
    final costController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Confirm Pickup', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: costController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              hintText: 'Enter actual cost',
              hintStyle: TextStyle(color: Colors.white54)),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () async {
                final cost = double.tryParse(costController.text.trim()) ?? 0;
                await supabase.from('bookings').update({
                  'status': 'completed',
                  'actual_cost': cost,
                }).eq('id', id);
                Navigator.pop(context);
                _loadPickups();
              },
              child: const Text('Confirm',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : pickups.isEmpty
              ? const Center(
                  child: Text('No confirmed pickups.',
                      style: TextStyle(color: Colors.white70)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: pickups.length,
                  itemBuilder: (context, i) {
                    final r = pickups[i];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      child: ListTile(
                        title: Text(r['waste_type'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            'Customer: ${r['customer_id']}\nPickup: ${r['pickup_date']}\nLocation: ${r['region']}, ${r['town']}',
                            style: const TextStyle(color: Colors.white70)),
                        trailing: ElevatedButton(
                          onPressed: () => _confirmPickup(r['id']),
                          child: const Text('Confirm Pickup'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
