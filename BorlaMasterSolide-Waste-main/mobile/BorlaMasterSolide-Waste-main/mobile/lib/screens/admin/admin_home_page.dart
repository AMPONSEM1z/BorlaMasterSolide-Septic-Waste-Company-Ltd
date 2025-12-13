import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'manage_companies_page.dart';
import 'manage_customers_page.dart';
import 'live_requests_page.dart';
import 'subscriptions_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> pages = const [
    AdminDashboard(), // Dashboard
    ManageCompaniesPage(), // Companies
    ManageCustomersPage(), // Customers
    LiveRequestsPage(), // Live requests
    SubscriptionsPage(), // Subscriptions
    ReportsPage(), // Reports
    SettingsPage(), // Settings
  ];

  final List<String> titles = [
    "Dashboard",
    "Manage Companies",
    "Manage Customers",
    "Live Requests",
    "Subscriptions",
    "Reports",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: Colors.blueGrey.shade900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "ADMIN PORTAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    children: [
                      _sidebarItem(Icons.dashboard, "Dashboard", 0),
                      _sidebarItem(Icons.apartment, "Companies", 1),
                      _sidebarItem(Icons.people, "Customers", 2),
                      _sidebarItem(Icons.bolt, "Live Requests", 3),
                      _sidebarItem(Icons.subscriptions, "Subscriptions", 4),
                      _sidebarItem(Icons.bar_chart, "Reports", 5),
                      _sidebarItem(Icons.settings, "Settings", 6),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN AREA
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.notifications_outlined, size: 26),
                          SizedBox(width: 20),
                          CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.person),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        color: isSelected ? Colors.blueGrey.shade700 : Colors.transparent,
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.white70, size: 22),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
