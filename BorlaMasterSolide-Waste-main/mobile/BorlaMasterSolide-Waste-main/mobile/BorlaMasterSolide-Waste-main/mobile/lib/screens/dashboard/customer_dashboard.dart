import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'request_pickup_screen.dart';
import 'live_requests_page.dart';

// ✅ Import separated pages
import 'home_page.dart';
import 'wallet_page.dart';
import 'profile_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final prof = await AuthService.getUserProfile(user.id);
        setState(() => _profile = prof);
      }
    } catch (_) {
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(profile: _profile, loading: _loadingProfile),
      const WalletPage(),
      const LiveRequestsPage(),
      ProfilePage(profile: _profile, onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 36,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            const Text('BorlaMaster',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), label: 'Requests'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
