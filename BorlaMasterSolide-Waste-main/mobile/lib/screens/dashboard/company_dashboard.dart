import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'company_home_page.dart';
import 'company_live_requests_page.dart';
import 'company_confirmed_pickups_page.dart';
import 'company_completed_pickups_page.dart';
import 'company_earnings_summary_page.dart';
import 'company_settings_page.dart';
import 'company_profile_page.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _companyProfile;
  bool _loadingProfile = true;

  late final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyProfile();
  }

  Future<void> _fetchCompanyProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('companies')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _companyProfile =
              data != null ? Map<String, dynamic>.from(data) : null;
          _loadingProfile = false;

          // Initialize pages after fetching profile
          _pages.clear();
          _pages.addAll([
            const CompanyHomePage(),
            const CompanyLiveRequestsPage(),
            const CompanyConfirmedPickupsPage(),
            const CompanyCompletedPickupsPage(),
            const CompanyEarningsSummaryPage(),
            CompanySettingsPage(
              profile: _companyProfile ?? {},
              onProfileUpdated: _refreshProfile,
            ),
            CompanyProfilePage(
              onLogout: _logout,
            ),
          ]);
        });
      }
    } catch (e) {
      print('Error fetching company profile: $e');
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  void _refreshProfile() async {
    await _fetchCompanyProfile();
  }

  void _logout() async {
    await supabase.auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
    // Optionally navigate to login page here
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color(0xFF1E1E1E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions), label: 'Live'),
          BottomNavigationBarItem(
              icon: Icon(Icons.verified), label: 'Confirmed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.done_all), label: 'Completed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Earnings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
