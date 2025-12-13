// lib/screens/admin/pages/overview_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

final supabase = Supabase.instance.client;

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  bool loading = true;

  int totalCustomers = 0;
  int totalCompanies = 0;
  int visibleCompanies = 0;
  int activeSubscriptions = 0;

  List<Map<String, dynamic>> recentActivities = [];

  // For charts
  Map<String, int> customersOverTime = {}; // key: month, value: count
  Map<String, int> companiesPerRegion = {}; // key: region, value: count

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    await Future.wait([
      _loadMetrics(),
      _loadRecentActivities(),
      _loadCustomerChart(),
      _loadCompaniesRegionChart(),
    ]);
    setState(() => loading = false);
  }

  Future<void> _loadMetrics() async {
    try {
      // Total Customers
      final customersRes = await supabase.from('customers').select('id');
      totalCustomers = customersRes.length;

      // Total Companies
      final companiesRes = await supabase.from('companies').select('id, available_for_customers, subscription_status');
      totalCompanies = companiesRes.length;
      visibleCompanies = companiesRes.where((c) => c['available_for_customers'] == true).length;
      activeSubscriptions = companiesRes.where((c) => c['subscription_status'] == 'active').length;
        } catch (e) {
      debugPrint('Error loading metrics: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final res = await supabase
          .from('admin_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(5);
      recentActivities = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (e) {
      debugPrint('Error loading recent activities: $e');
    }
  }

  Future<void> _loadCustomerChart() async {
    try {
      final res = await supabase.from('customers').select('created_at');
      Map<String, int> data = {};
      for (var c in res) {
        final created = c['created_at'];
        if (created != null) {
          final date = DateTime.parse(created);
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          data[key] = (data[key] ?? 0) + 1;
        }
      }
      customersOverTime = Map.fromEntries(data.entries.toList()..sort((a,b) => a.key.compareTo(b.key)));
        } catch (e) {
      debugPrint('Error loading customer chart: $e');
    }
  }

  Future<void> _loadCompaniesRegionChart() async {
    try {
      final res = await supabase.from('companies').select('regions_served');
      Map<String, int> data = {};
      for (var c in res) {
        final regions = (c['regions_served'] ?? []) as List<dynamic>;
        for (var r in regions) {
          final region = r.toString();
          data[region] = (data[region] ?? 0) + 1;
        }
      }
      companiesPerRegion = Map.fromEntries(data.entries.toList()..sort((a,b) => b.value.compareTo(a.value)));
        } catch (e) {
      debugPrint('Error loading companies per region chart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: 'Refresh Overview',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Metrics cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metricCard('Total Customers', totalCustomers.toString(), Colors.blueAccent),
                        _metricCard('Total Companies', totalCompanies.toString(), Colors.greenAccent),
                        _metricCard('Visible Companies', visibleCompanies.toString(), Colors.orangeAccent),
                        _metricCard('Active Subscriptions', activeSubscriptions.toString(), Colors.purpleAccent),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Subscription pie chart
                    Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Companies Subscription Status', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(sections: [
                                  PieChartSectionData(
                                    value: activeSubscriptions.toDouble(),
                                    color: Colors.green,
                                    title: 'Active',
                                    titleStyle: const TextStyle(color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    value: (totalCompanies - activeSubscriptions).toDouble(),
                                    color: Colors.redAccent,
                                    title: 'Inactive',
                                    titleStyle: const TextStyle(color: Colors.white),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New Customers over time chart
                    Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('New Customers Over Time', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final index = val.toInt();
                                          if (index < customersOverTime.keys.length) {
                                            final key = customersOverTime.keys.elementAt(index);
                                            return Text(key, style: const TextStyle(color: Colors.white54, fontSize: 10));
                                          }
                                          return const SizedBox();
                                        },
                                        interval: 1,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(customersOverTime.length, (i) {
                                        final value = customersOverTime.values.elementAt(i).toDouble();
                                        return FlSpot(i.toDouble(), value);
                                      }),
                                      isCurved: true,
                                      color: Colors.blueAccent,
                                      barWidth: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Companies per region chart
                    Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Companies per Region', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final index = val.toInt();
                                          if (index < companiesPerRegion.keys.length) {
                                            final key = companiesPerRegion.keys.elementAt(index);
                                            return Text(key, style: const TextStyle(color: Colors.white54, fontSize: 10));
                                          }
                                          return const SizedBox();
                                        },
                                        interval: 1,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                  ),
                                  barGroups: List.generate(companiesPerRegion.length, (i) {
                                    final value = companiesPerRegion.values.elementAt(i).toDouble();
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [BarChartRodData(toY: value, color: Colors.orangeAccent, width: 16)],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent activity
                    Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Admin Activities', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            ...recentActivities.map((act) {
                              final date = act['created_at']?.toString() ?? '';
                              final action = act['action'] ?? '';
                              return ListTile(
                                title: Text(action, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(date, style: const TextStyle(color: Colors.white54)),
                              );
                            }).toList(),
                            if (recentActivities.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('No recent activity', style: TextStyle(color: Colors.white54)),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
