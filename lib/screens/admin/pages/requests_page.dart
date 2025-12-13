import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  bool loading = true;
  bool actionLoading = false;
  List<Map<String, dynamic>> requests = [];
  List<String> statusFilterOptions = ['Pending', 'In Progress', 'Completed'];
  String? selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('bookings')
          .select('*, customers!bookings_customer_fk(*)')
          .order('created_at', ascending: false);

      var list = res
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Apply status filter
      if (selectedStatus != null && selectedStatus!.isNotEmpty) {
        list = list
            .where((r) => (r['status'] ?? '').toString() == selectedStatus)
            .toList();
      }

      // Client-side search
      final queryText = _searchController.text.trim().toLowerCase();
      if (queryText.isNotEmpty) {
        list = list.where((r) {
          final customerName =
              ((r['customers']?['full_name'] ?? '') as String).toLowerCase();
          final address = ((r['pickup_address'] ?? '') as String).toLowerCase();
          return customerName.contains(queryText) ||
              address.contains(queryText);
        }).toList();
      }

      setState(() => requests = list);
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      setState(() => requests = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateRequestStatus(
      Map<String, dynamic> request, String newStatus) async {
    final id = request['id'] as String?;
    if (id == null) return;

    setState(() => actionLoading = true);
    try {
      await supabase
          .from('bookings')
          .update({'status': newStatus}).eq('id', id);

      // Optional: log admin action
      final adminId = supabase.auth.currentUser?.id;
      await supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action': 'Updated booking ${request['id']} status to $newStatus',
        'target_table': 'bookings',
        'target_id': id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request status updated')));
      await _loadRequests();
    } catch (e) {
      debugPrint('Error updating booking: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      setState(() => actionLoading = false);
    }
  }

  Future<void> _openRequestDetails(Map<String, dynamic> request) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          builder: (_, controller) {
            return RequestDetailsSheet(
              request: request,
              onUpdated: () async {
                Navigator.of(ctx).pop();
                await _loadRequests();
              },
              controller: controller,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Pickup Requests')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter & Search
            Row(
              children: [
                DropdownButton<String>(
                  hint: const Text('Filter by status',
                      style: TextStyle(color: Colors.white)),
                  value: selectedStatus,
                  dropdownColor: const Color(0xFF1E1E1E),
                  underline: const SizedBox(),
                  iconEnabledColor: Colors.redAccent,
                  items: [null, ...statusFilterOptions].map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s ?? 'All',
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    setState(() => selectedStatus = val);
                    await _loadRequests();
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by customer or address',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white54),
                    ),
                    onChanged: (v) => _loadRequests(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: actionLoading ? null : _loadRequests,
                  icon: const Icon(Icons.search),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Requests list
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent))
                  : requests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.request_page,
                                  color: Colors.white24, size: 42),
                              SizedBox(height: 8),
                              Text('No pickup requests found',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: requests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, idx) {
                            final r = requests[idx];
                            final customerName =
                                r['customers']?['full_name'] ?? '—';
                            final address = r['pickup_address'] ?? '—';
                            final status = r['status'] ?? 'Pending';

                            return GestureDetector(
                              onTap: () => _openRequestDetails(r),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                          Colors.blueAccent.withOpacity(0.12),
                                      child: Text(
                                          customerName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(customerName,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            Text(address,
                                                style: const TextStyle(
                                                    color: Colors.white70)),
                                          ]),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: status == 'Completed'
                                              ? Colors.green
                                              : status == 'In Progress'
                                                  ? Colors.orange
                                                  : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(status,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ),
                                  ],
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

class RequestDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onUpdated;
  final ScrollController controller;

  const RequestDetailsSheet({
    required this.request,
    required this.onUpdated,
    required this.controller,
    super.key,
  });

  Future<void> _setStatus(String newStatus) async {
    final id = request['id'] as String?;
    if (id == null) return;

    try {
      await supabase
          .from('bookings')
          .update({'status': newStatus}).eq('id', id);

      final adminId = supabase.auth.currentUser?.id;
      await supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action': 'Updated booking ${request['id']} status to $newStatus',
        'target_table': 'bookings',
        'target_id': id,
      });
    } catch (e) {
      debugPrint('Error updating booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = request['customers']?['full_name'] ?? '—';
    final address = request['pickup_address'] ?? '—';
    final status = request['status'] ?? 'Pending';

    return Container(
      padding: const EdgeInsets.all(18),
      color: const Color(0xFF121212),
      child: ListView(
        controller: controller,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          Text(customerName,
              style: const TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 6),
          Text(address, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: ['Pending', 'In Progress', 'Completed'].map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: status == s
                      ? null
                      : () async {
                          await _setStatus(s);
                          onUpdated();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Status updated')));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s == 'Completed'
                        ? Colors.green
                        : s == 'In Progress'
                            ? Colors.orange
                            : Colors.grey,
                  ),
                  child: Text(s),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
