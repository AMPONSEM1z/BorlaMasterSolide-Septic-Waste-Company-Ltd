import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

final supabase = Supabase.instance.client;

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  List<Map<String, dynamic>> payments = [];
  Map<String, Map<String, dynamic>> users = {};
  Map<String, Map<String, dynamic>> bookings = {};
  Map<String, Map<String, dynamic>> companies = {};

  bool loading = true;
  bool actionLoading = false;

  // Filters
  List<String> statusOptions = ['pending', 'completed', 'failed', 'refunded'];
  List<String> settlementOptions = ['pending', 'settled'];
  String? selectedStatus;
  String? selectedSettlement;
  final TextEditingController _searchController = TextEditingController();

  // Summary
  int totalCount = 0;
  double totalRevenue = 0.0;
  int pendingSettlementCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => loading = true);
    try {
      final paymentRes = await supabase.from('payments').select() as List<dynamic>;
      final paymentsData = paymentRes.map((e) => Map<String, dynamic>.from(e)).toList();

      final results = await Future.wait([
        supabase.from('customers').select(),
        supabase.from('bookings').select(),
        supabase.from('companies').select(),
      ]);

      users = {for (var u in results[0]) u['id']: Map<String, dynamic>.from(u)};
      bookings = {for (var b in results[1]) b['id']: Map<String, dynamic>.from(b)};
      companies = {for (var c in results[2]) c['id']: Map<String, dynamic>.from(c)};

      var filtered = List<Map<String, dynamic>>.from(paymentsData);

      if (selectedStatus != null && selectedStatus!.isNotEmpty) {
        filtered = filtered.where((p) =>
            (p['status'] ?? p['payment_status'] ?? '').toString().toLowerCase() ==
            selectedStatus!.toLowerCase()).toList();
      }

      if (selectedSettlement != null && selectedSettlement!.isNotEmpty) {
        filtered = filtered.where((p) =>
            (p['settlement_status'] ?? '').toString().toLowerCase() ==
            selectedSettlement!.toLowerCase()).toList();
      }

      final queryText = _searchController.text.trim().toLowerCase();
      if (queryText.isNotEmpty) {
        filtered = filtered.where((p) {
          final ref = (p['transaction_reference'] ?? '').toString().toLowerCase();
          final companyName = companies[p['company_id']]?['company_name']?.toLowerCase() ?? '';
          final userId = (p['user_id'] ?? '').toString().toLowerCase();
          final bookingId = (p['booking_id'] ?? '').toString().toLowerCase();
          return ref.contains(queryText) ||
              companyName.contains(queryText) ||
              userId.contains(queryText) ||
              bookingId.contains(queryText);
        }).toList();
      }

      _recomputeSummary(paymentsData);

      setState(() {
        payments = filtered;
      });
    } catch (e) {
      debugPrint('Error loading payments: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading payments: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  void _recomputeSummary(List<Map<String, dynamic>> allPayments) {
    totalCount = allPayments.length;
    totalRevenue = 0.0;
    pendingSettlementCount = 0;

    for (final p in allPayments) {
      final amt = p['amount'];
      if (amt != null) {
        totalRevenue += double.tryParse(amt.toString()) ?? 0;
      }
      if ((p['settlement_status'] ?? '').toString().toLowerCase() == 'pending') {
        pendingSettlementCount++;
      }
    }
  }

  Future<void> _updatePaymentFields(String id, Map<String, dynamic> updates) async {
    setState(() => actionLoading = true);
    try {
      await supabase.from('payments').update(updates).eq('id', id);
      final adminId = supabase.auth.currentUser?.id;
      await supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action': 'Updated payment $id fields: ${updates.keys.join(', ')}',
        'target_table': 'payments',
        'target_id': id,
      });
      await _loadPayments();
    } catch (e) {
      debugPrint('Error updating payment $id: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      setState(() => actionLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No payments to export')));
      return;
    }

    final rows = <List<dynamic>>[];
    rows.add([
      'id',
      'created_at',
      'booking_id',
      'user_id',
      'company',
      'amount',
      'currency',
      'payment_method',
      'payment_status',
      'settlement_status',
      'transaction_reference'
    ]);

    final dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final p in payments) {
      final companyName = companies[p['company_id']]?['company_name'] ?? '';
      rows.add([
        p['id'] ?? '',
        p['created_at'] != null ? dateFmt.format(DateTime.parse(p['created_at'].toString())) : '',
        p['booking_id'] ?? '',
        p['user_id'] ?? '',
        companyName,
        p['amount']?.toString() ?? '',
        p['currency'] ?? '',
        p['payment_method'] ?? '',
        p['payment_status'] ?? p['status'] ?? '',
        p['settlement_status'] ?? '',
        p['transaction_reference'] ?? ''
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    try {
      await Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed')));
    }
  }

  Widget _summaryCard(String title, String value, {Color color = Colors.blueAccent}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Payments')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary cards
            Row(
              children: [
                _summaryCard('Total payments', totalCount.toString()),
                const SizedBox(width: 12),
                _summaryCard('Total revenue',
                    '${currencyFormatter.format(totalRevenue)} ${payments.isNotEmpty ? payments.first['currency'] ?? 'GHS' : 'GHS'}',
                    color: Colors.greenAccent),
                const SizedBox(width: 12),
                _summaryCard('Pending settlements', pendingSettlementCount.toString(), color: Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 12),

            // Filters, search & actions (two rows)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        hint: const Text('Status', style: TextStyle(color: Colors.white)),
                        value: selectedStatus,
                        dropdownColor: const Color(0xFF1E1E1E),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [null, ...statusOptions].map((s) {
                          return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s ?? 'All', style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (v) {
                          setState(() => selectedStatus = v);
                          _loadPayments();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        hint: const Text('Settlement', style: TextStyle(color: Colors.white)),
                        value: selectedSettlement,
                        dropdownColor: const Color(0xFF1E1E1E),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [null, ...settlementOptions].map((s) {
                          return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s ?? 'All', style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (v) {
                          setState(() => selectedSettlement = v);
                          _loadPayments();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search ref / user / booking / company',
                          filled: true,
                          fillColor: Colors.white10,
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (v) => _loadPayments(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: actionLoading ? null : _loadPayments,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _exportCsv,
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payments list
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.payment, color: Colors.white24, size: 48),
                              SizedBox(height: 8),
                              Text('No payments found', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, idx) {
                            final p = payments[idx];
                            final user = users[p['user_id']];
                            final booking = bookings[p['booking_id']];
                            final company = companies[p['company_id']];
                            final amount = p['amount'] ?? 0;
                            final currency = p['currency'] ?? 'GHS';
                            final paymentStatus = (p['payment_status'] ?? p['status'] ?? 'pending').toString();
                            final settlementStatus = (p['settlement_status'] ?? 'pending').toString();

                            return GestureDetector(
                              onTap: () => _openPaymentDetails(p),
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
                                      backgroundColor: Colors.blueAccent.withOpacity(0.12),
                                      child: Text(company?['company_name']?.substring(0, 1).toUpperCase() ?? '-', style: const TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(company?['company_name'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text('Ref: ${p['transaction_reference'] ?? ''}  •  Amount: $amount $currency', style: const TextStyle(color: Colors.white70)),
                                          if (booking != null) ...[
                                            const SizedBox(height: 4),
                                            Text('Booking: ${booking['id']} • Pickup: ${booking['pickup_address'] ?? booking['destination'] ?? ''}',
                                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: paymentStatus == 'completed'
                                                  ? Colors.green
                                                  : paymentStatus == 'failed'
                                                      ? Colors.red
                                                      : Colors.grey,
                                              borderRadius: BorderRadius.circular(8)),
                                          child: Text(paymentStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: settlementStatus == 'settled' ? Colors.greenAccent : Colors.orangeAccent,
                                              borderRadius: BorderRadius.circular(8)),
                                          child: Text(settlementStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ],
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

  Future<void> _openPaymentDetails(Map<String, dynamic> payment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          builder: (_, controller) {
            return PaymentDetailsSheet(
              payment: payment,
              controller: controller,
              users: users,
              bookings: bookings,
              companies: companies,
              onUpdated: () async {
                Navigator.of(ctx).pop();
                await _loadPayments();
              },
            );
          },
        );
      },
    );
  }
}

// PaymentDetailsSheet widget remains unchanged
class PaymentDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> payment;
  final ScrollController controller;
  final Map<String, Map<String, dynamic>> users;
  final Map<String, Map<String, dynamic>> bookings;
  final Map<String, Map<String, dynamic>> companies;
  final VoidCallback onUpdated;

  const PaymentDetailsSheet({required this.payment, required this.controller, required this.users, required this.bookings, required this.companies, required this.onUpdated, super.key});

  @override
  State<PaymentDetailsSheet> createState() => _PaymentDetailsSheetState();
}

class _PaymentDetailsSheetState extends State<PaymentDetailsSheet> {
  bool saving = false;

  Future<void> _update(Map<String, dynamic> updates) async {
    setState(() => saving = true);
    try {
      await supabase.from('payments').update(updates).eq('id', widget.payment['id']);
      final adminId = supabase.auth.currentUser?.id;
      await supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action': 'Admin updated payment ${widget.payment['id']}: ${updates.keys.join(', ')}',
        'target_table': 'payments',
        'target_id': widget.payment['id'],
      });
      widget.onUpdated();
    } catch (e) {
      debugPrint('Error updating payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final company = widget.companies[p['company_id']];
    final booking = widget.bookings[p['booking_id']];
    final user = widget.users[p['user_id']];
    final amount = p['amount'] ?? 0;
    final currency = p['currency'] ?? 'GHS';
    final paymentStatus = p['payment_status'] ?? p['status'] ?? 'pending';
    final settlementStatus = p['settlement_status'] ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(18),
      color: const Color(0xFF121212),
      child: ListView(
        controller: widget.controller,
        children: [
          Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)))),
          const SizedBox(height: 12),
          Text(company?['company_name'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 6),
          Text('Ref: ${p['transaction_reference'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('Amount: $amount $currency', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          if (booking != null) ...[
            const Text('Booking Info', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Booking ID: ${booking['id']}', style: const TextStyle(color: Colors.white54)),
            Text('Pickup: ${booking['pickup_address'] ?? booking['destination'] ?? ''}', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
          ],
          Text('User: ${user?['name'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('Payment method: ${p['payment_method'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: (paymentStatus == 'completed' || saving) ? null : () => _update({'status': 'completed', 'payment_status': 'completed'}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Mark Completed'),
              ),
              ElevatedButton(
                onPressed: (paymentStatus == 'failed' || saving) ? null : () => _update({'status': 'failed', 'payment_status': 'failed'}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Mark Failed'),
              ),
              ElevatedButton(
                onPressed: (paymentStatus == 'refunded' || saving) ? null : () => _update({'status': 'refunded', 'payment_status': 'refunded'}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text('Mark Refunded'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: (settlementStatus == 'settled' || saving) ? null : () => _update({'settlement_status': 'settled', 'settlement_date': DateTime.now().toIso8601String()}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                child: const Text('Mark Settled'),
              ),
              ElevatedButton(
                onPressed: (settlementStatus == 'pending' || saving) ? null : () => _update({'settlement_status': 'pending', 'settlement_date': null}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                child: const Text('Mark Pending'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Close')),
        ],
      ),
    );
  }
}
