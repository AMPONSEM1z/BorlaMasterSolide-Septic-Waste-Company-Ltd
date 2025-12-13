import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyEarningsSummaryPage extends StatefulWidget {
  const CompanyEarningsSummaryPage({super.key});

  @override
  State<CompanyEarningsSummaryPage> createState() =>
      _CompanyEarningsSummaryPageState();
}

class _CompanyEarningsSummaryPageState
    extends State<CompanyEarningsSummaryPage> {
  bool loading = false;
  bool exporting = false;

  List<Map<String, dynamic>> payments = [];

  String searchQuery = '';
  String filterStatus = 'all';
  String filterMethod = 'all';

  String selectedPeriod = 'daily';

  double dailyEarnings = 0;
  double weeklyEarnings = 0;
  double monthlyEarnings = 0;
  double yearlyEarnings = 0;
  double totalEarnings = 0;
  double settledAmount = 0;
  double pendingAmount = 0;

  DateTimeRange? dateRange;

  final statusOptions = ['all', 'pending', 'settled'];
  final methodOptions = ['all', 'card', 'bank', 'mobile_money'];

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await _loadPayments();
    await _loadEarnings();
  }

  Future<void> _loadPayments() async {
    setState(() => loading = true);

    try {
      var query = Supabase.instance.client.from('payments').select();

      if (filterStatus != 'all') {
        query = query.eq('status', filterStatus);
      }

      if (filterMethod != 'all') {
        query = query.eq('payment_method', filterMethod);
      }

      if (dateRange != null) {
        query = query
            .gte('created_at', dateRange!.start.toIso8601String())
            .lte('created_at', dateRange!.end.toIso8601String());
      }

      // Supabase v2 returns the data directly
      final response = await query;

      final data = List<Map<String, dynamic>>.from(response);

      setState(() {
        payments = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payments: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadEarnings() async {
    double daily = 0, weekly = 0, monthly = 0, yearly = 0, total = 0;
    double settled = 0, pending = 0;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    for (var p in payments) {
      final amount = (p['amount_due'] as num).toDouble();
      total += amount;
      final paidAt = DateTime.parse(p['created_at']);

      if (DateFormat('yyyy-MM-dd').format(paidAt) ==
          DateFormat('yyyy-MM-dd').format(now)) {
        daily += amount;
      }
      if (paidAt.isAfter(weekStart)) weekly += amount;
      if (paidAt.month == now.month && paidAt.year == now.year)
        monthly += amount;
      if (paidAt.year == now.year) yearly += amount;

      if (p['status'] == 'settled')
        settled += amount;
      else
        pending += amount;
    }

    setState(() {
      dailyEarnings = daily;
      weeklyEarnings = weekly;
      monthlyEarnings = monthly;
      yearlyEarnings = yearly;
      totalEarnings = total;
      settledAmount = settled;
      pendingAmount = pending;
    });
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      dateRange = range;
      await _refreshAll();
    }
  }

  Future<void> _exportCsv() async {
    if (payments.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No payments to export')));
      return;
    }

    setState(() => exporting = true);

    try {
      final csvBuf = StringBuffer();
      csvBuf.writeln('ID,Amount,Method,Status,Customer,Date');

      for (var p in payments) {
        List<String> row = [
          p['id'].toString(),
          p['amount_due'].toString(),
          p['payment_method'],
          p['status'],
          p['customer_name'],
          p['created_at'],
        ];

        final escaped = row.map((s) {
          if (s.contains(',') || s.contains('\n') || s.contains('"')) {
            return '"${s.replaceAll('"', '""')}"';
          }
          return s;
        }).join(',');

        csvBuf.writeln(escaped);
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/payments_export.csv');
      await file.writeAsString(csvBuf.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Payments Export');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    } finally {
      setState(() => exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (payments.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No payments to export')));
      return;
    }

    setState(() => exporting = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(pw.Page(
        build: (context) => pw.Column(children: [
          pw.Text('Payments Report',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Total earnings: GHS ${totalEarnings.toStringAsFixed(2)}'),
          pw.Text('Settled: GHS ${settledAmount.toStringAsFixed(2)}'),
          pw.Text('Pending: GHS ${pendingAmount.toStringAsFixed(2)}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ID', 'Amount', 'Method', 'Status', 'Customer', 'Date'],
            data: payments
                .map((p) => [
                      p['id'].toString(),
                      p['amount'].toString(),
                      p['payment_method'],
                      p['status'],
                      p['customer_name'],
                      p['created_at'],
                    ])
                .toList(),
          ),
        ]),
      ));

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/payments_export.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Payments PDF');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    } finally {
      setState(() => exporting = false);
    }
  }

  List<Map<String, dynamic>> get _filteredByPeriod {
    final now = DateTime.now();

    if (selectedPeriod == 'daily') {
      return payments.where((p) {
        final dt = DateTime.parse(p['created_at']);
        return DateFormat('yyyy-MM-dd').format(dt) ==
            DateFormat('yyyy-MM-dd').format(now);
      }).toList();
    }

    if (selectedPeriod == 'weekly') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return payments
          .where((p) => DateTime.parse(p['created_at']).isAfter(weekStart))
          .toList();
    }

    if (selectedPeriod == 'monthly') {
      return payments.where((p) {
        final dt = DateTime.parse(p['created_at']);
        return dt.month == now.month && dt.year == now.year;
      }).toList();
    }

    return payments
        .where((p) => DateTime.parse(p['created_at']).year == now.year)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Earnings Summary')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _StatCard(
                                title: 'Settled',
                                value:
                                    'GHS ${settledAmount.toStringAsFixed(2)}'),
                            _StatCard(
                                title: 'Pending',
                                value:
                                    'GHS ${pendingAmount.toStringAsFixed(2)}'),
                            _StatCard(
                                title: 'Today',
                                value:
                                    'GHS ${dailyEarnings.toStringAsFixed(2)}'),
                            _StatCard(
                                title: 'Week',
                                value:
                                    'GHS ${weeklyEarnings.toStringAsFixed(2)}'),
                            _StatCard(
                                title: 'Month',
                                value:
                                    'GHS ${monthlyEarnings.toStringAsFixed(2)}'),
                            _StatCard(
                                title: 'Year',
                                value:
                                    'GHS ${yearlyEarnings.toStringAsFixed(2)}'),
                            _StatCard(
                                title: 'Total',
                                value:
                                    'GHS ${totalEarnings.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Filters
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: isSmallScreen
                                  ? constraints.maxWidth * 0.45
                                  : 200,
                              child: DropdownButtonFormField<String>(
                                value: filterStatus,
                                items: statusOptions
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.toUpperCase()),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => filterStatus = v);
                                    _refreshAll();
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen
                                  ? constraints.maxWidth * 0.45
                                  : 200,
                              child: DropdownButtonFormField<String>(
                                value: filterMethod,
                                items: methodOptions
                                    .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m.toUpperCase()),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => filterMethod = v);
                                    _refreshAll();
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Method',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _pickDateRange,
                              child: const Text('Select Date Range'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text('PERIOD FILTER',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 10,
                          children: [
                            _periodBtn('daily'),
                            _periodBtn('weekly'),
                            _periodBtn('monthly'),
                            _periodBtn('yearly'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Payments Table
                        _buildPaymentsTable(
                            _filteredByPeriod, constraints.maxWidth),

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: exporting ? null : _exportCsv,
                                child: const Text('Export CSV'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: exporting ? null : _exportPdf,
                                child: const Text('Export PDF'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _periodBtn(String key) {
    final isActive = selectedPeriod == key;

    return ChoiceChip(
      label: Text(key.toUpperCase()),
      selected: isActive,
      onSelected: (_) async {
        setState(() => selectedPeriod = key);
        await _refreshAll();
      },
    );
  }

  Widget _StatCard({required String title, required String value}) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTable(List<Map<String, dynamic>> list, double maxWidth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: maxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 40,
                dataRowHeight: 40,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Date')),
                ],
                rows: list.map((p) {
                  return DataRow(cells: [
                    DataCell(Text(p['id'].toString())),
                    DataCell(Text(p['amount_due'].toString())),
                    DataCell(Text(p['payment_method'])),
                    DataCell(Text(p['status'])),
                    DataCell(Text(p['customer_name'])),
                    DataCell(Text(p['created_at'])),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
