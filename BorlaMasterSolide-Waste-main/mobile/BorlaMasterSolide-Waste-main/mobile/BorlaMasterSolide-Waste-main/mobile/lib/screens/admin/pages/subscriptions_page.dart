// lib/screens/admin/pages/subscriptions_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  bool loading = true;
  bool actionLoading = false;
  List<Map<String, dynamic>> companies = [];
  final TextEditingController _searchController = TextEditingController();
  String? subscriptionFilter;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => loading = true);
    try {
      final res = await supabase.from('companies').select();

      if (res is List) {
        var list = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Filter by subscription status
        if (subscriptionFilter != null && subscriptionFilter!.isNotEmpty) {
          list = list.where((c) => (c['subscription_status'] ?? '').toLowerCase() == subscriptionFilter!.toLowerCase()).toList();
        }

        // Search filter
        final queryText = _searchController.text.trim().toLowerCase();
        if (queryText.isNotEmpty) {
          list = list.where((c) {
            final name = (c['company_name'] ?? '').toString().toLowerCase();
            final email = (c['contact_email'] ?? '').toString().toLowerCase();
            return name.contains(queryText) || email.contains(queryText);
          }).toList();
        }

        setState(() => companies = list);
      } else {
        setState(() => companies = []);
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      setState(() => companies = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleSubscription(Map<String, dynamic> company, bool activate) async {
    final id = company['id'] as String?;
    if (id == null) return;

    setState(() => actionLoading = true);

    try {
      final now = DateTime.now().toUtc();
      final nextYear = now.add(const Duration(days: 365));

      await supabase.from('companies').update({
        'subscription_status': activate ? 'active' : 'inactive',
        'subscription_start': activate ? now.toIso8601String() : null,
        'subscription_end': activate ? nextYear.toIso8601String() : null,
        'available_for_customers': activate,
      }).eq('id', id);

      final adminId = supabase.auth.currentUser?.id;
      await supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action': '${activate ? "activated" : "deactivated"} subscription for ${company['company_name']}',
        'target_table': 'companies',
        'target_id': id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${company['company_name']} subscription ${activate ? "activated" : "deactivated"}')),
      );

      await _loadCompanies();
    } catch (e) {
      debugPrint('Error toggling subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      setState(() => actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Company Subscriptions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter & Search
            Row(
              children: [
                DropdownButton<String>(
                  hint: const Text('Filter by subscription', style: TextStyle(color: Colors.white)),
                  value: subscriptionFilter,
                  dropdownColor: const Color(0xFF1E1E1E),
                  underline: const SizedBox(),
                  iconEnabledColor: Colors.redAccent,
                  items: [null, 'active', 'inactive'].map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s == null ? 'All' : s.capitalize(),
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => subscriptionFilter = val);
                    _loadCompanies();
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by company or email',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    ),
                    onChanged: (v) => _loadCompanies(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: actionLoading ? null : _loadCompanies,
                  icon: const Icon(Icons.search),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Companies List
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : companies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.business_outlined, color: Colors.white24, size: 42),
                              SizedBox(height: 8),
                              Text('No companies found', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: companies.length,
                          itemBuilder: (_, idx) {
                            final c = companies[idx];
                            final subscription = c['subscription_status'] ?? 'inactive';
                            return Card(
                              color: const Color(0xFF1E1E1E),
                              child: ListTile(
                                title: Text(c['company_name'] ?? '—', style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Subscription: ${subscription.toString().toUpperCase()}', style: const TextStyle(color: Colors.white70)),
                                trailing: Switch(
                                  value: subscription == 'active',
                                  activeColor: Colors.greenAccent,
                                  onChanged: actionLoading ? null : (v) => _toggleSubscription(c, v),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
