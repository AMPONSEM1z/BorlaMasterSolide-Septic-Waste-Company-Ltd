import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CompanyEarningsSummaryPage extends StatefulWidget {
  const CompanyEarningsSummaryPage({super.key});

  @override
  State<CompanyEarningsSummaryPage> createState() =>
      _CompanyEarningsSummaryPageState();
}

class _CompanyEarningsSummaryPageState
    extends State<CompanyEarningsSummaryPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;

  double totalEarnings = 0;
  double dailyEarnings = 0;
  double weeklyEarnings = 0;
  double monthlyEarnings = 0;
  double yearlyEarnings = 0;
  int completedPickups = 0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch completed bookings for this company
      final data = await supabase
          .from('bookings')
          .select(
              'actual_cost, completed_at') // Make sure your table has this column
          .eq('company_id', user.id)
          .eq('status', 'completed');

      double total = 0;
      double daily = 0;
      double weekly = 0;
      double monthly = 0;
      double yearly = 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfYear = DateTime(now.year, 1, 1);

      for (final booking in data) {
        if (booking['actual_cost'] == null || booking['completed_at'] == null)
          continue;
        final cost = (booking['actual_cost'] as num).toDouble();
        final completedAt = DateTime.parse(booking['completed_at']);

        total += cost;

        if (completedAt.isAfter(today)) daily += cost;
        if (completedAt.isAfter(startOfWeek)) weekly += cost;
        if (completedAt.isAfter(startOfMonth)) monthly += cost;
        if (completedAt.isAfter(startOfYear)) yearly += cost;
      }

      setState(() {
        totalEarnings = total;
        dailyEarnings = daily;
        weeklyEarnings = weekly;
        monthlyEarnings = monthly;
        yearlyEarnings = yearly;
        completedPickups = data.length;
      });
    } catch (e) {
      debugPrint('Error loading earnings: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Earnings Summary',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _StatCard(
                      title: 'Completed Pickups',
                      value: '$completedPickups',
                      subtitle: 'Total successful orders'),
                  const SizedBox(height: 12),
                  _StatCard(
                      title: 'Total Earnings',
                      value: 'GHS ${totalEarnings.toStringAsFixed(2)}',
                      subtitle: 'All-time earnings'),
                  const SizedBox(height: 12),
                  _StatCard(
                      title: 'Today\'s Earnings',
                      value: 'GHS ${dailyEarnings.toStringAsFixed(2)}',
                      subtitle:
                          'Earnings for ${DateFormat('EEE, MMM d').format(DateTime.now())}'),
                  const SizedBox(height: 12),
                  _StatCard(
                      title: 'Weekly Earnings',
                      value: 'GHS ${weeklyEarnings.toStringAsFixed(2)}',
                      subtitle: 'Earnings since Monday'),
                  const SizedBox(height: 12),
                  _StatCard(
                      title: 'Monthly Earnings',
                      value: 'GHS ${monthlyEarnings.toStringAsFixed(2)}',
                      subtitle:
                          'Earnings for ${DateFormat('MMMM yyyy').format(DateTime.now())}'),
                  const SizedBox(height: 12),
                  _StatCard(
                      title: 'Annual Earnings',
                      value: 'GHS ${yearlyEarnings.toStringAsFixed(2)}',
                      subtitle:
                          'Earnings for ${DateFormat('yyyy').format(DateTime.now())}'),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  const _StatCard(
      {super.key,
      required this.title,
      required this.value,
      this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
