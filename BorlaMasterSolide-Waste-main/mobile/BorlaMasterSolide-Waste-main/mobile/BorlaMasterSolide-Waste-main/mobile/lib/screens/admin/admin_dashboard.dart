import 'package:flutter/material.dart';
import 'pages/overview_page.dart';
import 'pages/companies_page.dart';
import 'pages/customers_page.dart';
import 'pages/subscriptions_page.dart';
import 'pages/requests_page.dart';
import 'pages/payments_page.dart';
import 'pages/admins_page.dart';
import 'pages/settings_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    OverviewPage(),
    CompaniesPage(),
    CustomersPage(),
    SubscriptionsPage(),
    RequestsPage(),
    PaymentsPage(),
    AdminsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Admin Panel", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Admin Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text("System Controls",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _drawerItem(Icons.dashboard, "Overview", 0),
            _drawerItem(Icons.business, "Companies", 1),
            _drawerItem(Icons.people, "Customers", 2),
            _drawerItem(Icons.subscriptions, "Subscriptions", 3),
            _drawerItem(Icons.request_page, "Requests", 4),
            _drawerItem(Icons.payments, "Payments", 5),
            _drawerItem(Icons.admin_panel_settings, "Admins", 6),
            _drawerItem(Icons.settings, "Settings", 7),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    final bool active = _selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: active ? Colors.blueAccent : Colors.white70),
      title: Text(
        label,
        style: TextStyle(
          color: active ? Colors.blueAccent : Colors.white70,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // close drawer
      },
    );
  }
}
