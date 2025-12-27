// // lib/screens/dashboard/customer_dashboard.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../auth/login_screen.dart';

// class CustomerDashboard extends StatefulWidget {
//   const CustomerDashboard({super.key});

//   @override
//   State<CustomerDashboard> createState() => _CustomerDashboardState();
// }

// class _CustomerDashboardState extends State<CustomerDashboard> {
//   int _selectedIndex = 0;
//   Map<String, dynamic>? _profile;
//   bool _loadingProfile = true;

//   final List<Widget> _pages = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   Future<void> _loadProfile() async {
//     setState(() => _loadingProfile = true);
//     try {
//       final user = await AuthService
//           .signInWithEmail; // noop-check placeholder to keep analyzer quiet
//     } catch (_) {}
//     // fetch current user from Supabase auth
//     final session = (await AuthService.signInWithEmail == null) ? null : null;
//     // Instead of above weird placeholder (to keep lints happy), fetch profile properly:
//     try {
//       final user = Supabase.instance.client.auth.currentUser;
//       if (user != null) {
//         final prof = await AuthService.getUserProfile(user.id);
//         setState(() => _profile = prof);
//       }
//     } catch (e) {
//       // ignore fetch errors for now
//     } finally {
//       setState(() => _loadingProfile = false);
//     }
//   }

//   void _onItemTapped(int index) {
//     setState(() => _selectedIndex = index);
//   }

//   Future<void> _logout() async {
//     await AuthService.signOut();
//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pages = <Widget>[
//       HomePage(profile: _profile, loading: _loadingProfile),
//       WalletPage(),
//       RequestsPage(),
//       ProfilePage(profile: _profile, onLogout: _logout),
//     ];

//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       appBar: AppBar(
//         backgroundColor: Colors.redAccent,
//         elevation: 0,
//         title: Row(
//           children: [
//             // small logo or placeholder
//             Image.asset(
//               'assets/logo.png',
//               height: 36,
//               errorBuilder: (_, __, ___) => const SizedBox.shrink(),
//             ),
//             const SizedBox(width: 12),
//             const Text('BorlaMaster',
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Logout',
//             onPressed: _logout,
//             icon: const Icon(Icons.logout, color: Colors.white),
//           ),
//         ],
//       ),
//       body: pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: const Color(0xFF1E1E1E),
//         selectedItemColor: Colors.redAccent,
//         unselectedItemColor: Colors.white70,
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined), label: 'Home'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.account_balance_wallet_outlined),
//               label: 'Wallet'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.list_alt_outlined), label: 'Requests'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.person_outline), label: 'Profile'),
//         ],
//       ),
//     );
//   }
// }

// /* ---------------------------
//    Home Page (Dashboard Overview)
//    --------------------------- */
// class HomePage extends StatelessWidget {
//   final Map<String, dynamic>? profile;
//   final bool loading;
//   const HomePage({super.key, required this.profile, required this.loading});

//   @override
//   Widget build(BuildContext context) {
//     final userName =
//         profile != null ? (profile!['full_name'] ?? 'User') : 'User';

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: loading
//           ? const Center(
//               child: CircularProgressIndicator(color: Colors.redAccent))
//           : Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Welcome back, $userName 👋',
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 16),
//                 const Text('Here is a quick summary of your activity:',
//                     style: TextStyle(color: Colors.white70)),
//                 const SizedBox(height: 20),

//                 // quick stat cards
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 12,
//                   children: [
//                     _StatCard(title: 'Upcoming Pickups', value: '2'),
//                     _StatCard(title: 'Completed', value: '15'),
//                     _StatCard(title: 'Wallet Balance', value: 'GHS 120.00'),
//                     _StatCard(title: 'Active Companies', value: '4'),
//                   ],
//                 ),

//                 const SizedBox(height: 24),
//                 const Text('Quick actions',
//                     style: TextStyle(color: Colors.white70)),
//                 const SizedBox(height: 12),

//                 // Quick action buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           // TODO: open new pickup request screen
//                         },
//                         icon: const Icon(Icons.add, color: Colors.white),
//                         label: const Text('Request Pickup'),
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.redAccent,
//                             minimumSize: const Size.fromHeight(48)),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.history, color: Colors.white70),
//                         label: const Text('History',
//                             style: TextStyle(color: Colors.white70)),
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(color: Colors.white12),
//                           minimumSize: const Size.fromHeight(48),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   final String title;
//   final String value;
//   const _StatCard({required this.title, required this.value, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 160,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
//       ),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(title, style: const TextStyle(color: Colors.white70)),
//         const SizedBox(height: 8),
//         Text(value,
//             style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold)),
//       ]),
//     );
//   }
// }

// /* ---------------------------
//    Wallet Page
//    --------------------------- */
// class WalletPage extends StatelessWidget {
//   const WalletPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // placeholder wallet view
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         const Text('Wallet',
//             style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold)),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//               color: const Color(0xFF1E1E1E),
//               borderRadius: BorderRadius.circular(12)),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text('Balance', style: TextStyle(color: Colors.white70)),
//                     SizedBox(height: 6),
//                     Text('GHS 120.00',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold)),
//                   ]),
//               ElevatedButton(
//                 onPressed: () {
//                   // TODO: open top-up flow
//                 },
//                 style:
//                     ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
//                 child: const Text('Top Up'),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 18),
//         const Text('Transactions', style: TextStyle(color: Colors.white70)),
//         const SizedBox(height: 8),
//         Expanded(
//           child: ListView.separated(
//             itemBuilder: (c, i) => ListTile(
//               tileColor: const Color(0xFF161616),
//               leading:
//                   const Icon(Icons.arrow_downward, color: Colors.greenAccent),
//               title:
//                   const Text('Top-up', style: TextStyle(color: Colors.white)),
//               subtitle: const Text('GHS 50 — 05 Oct 2025',
//                   style: TextStyle(color: Colors.white70)),
//               trailing: const Text('-GHS 0.00',
//                   style: TextStyle(color: Colors.white70)),
//             ),
//             separatorBuilder: (_, __) => const SizedBox(height: 8),
//             itemCount: 4,
//           ),
//         ),
//       ]),
//     );
//   }
// }

// /* ---------------------------
//    Requests Page (Pickup Requests)
//    --------------------------- */
// class RequestsPage extends StatelessWidget {
//   const RequestsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // placeholder list of requests
//     final requests = List.generate(
//         6,
//         (i) => {
//               'title': 'Pickup #${i + 1}',
//               'date': '2025-10-${10 + i}',
//               'status': i % 3 == 0
//                   ? 'pending'
//                   : (i % 3 == 1 ? 'in_progress' : 'completed')
//             });

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         const Text('Your Pickups',
//             style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold)),
//         const SizedBox(height: 12),
//         Expanded(
//           child: ListView.separated(
//             itemBuilder: (c, i) {
//               final r = requests[i];
//               final status = r['status'] as String;
//               Color badgeColor = Colors.orangeAccent;
//               if (status == 'completed') badgeColor = Colors.green;
//               if (status == 'in_progress') badgeColor = Colors.blueAccent;

//               return ListTile(
//                 tileColor: const Color(0xFF161616),
//                 title: Text(r['title']!,
//                     style: const TextStyle(color: Colors.white)),
//                 subtitle: Text('Date: ${r['date']!}',
//                     style: const TextStyle(color: Colors.white70)),
//                 trailing: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                       color: badgeColor,
//                       borderRadius: BorderRadius.circular(8)),
//                   child: Text(status.toUpperCase(),
//                       style:
//                           const TextStyle(color: Colors.white, fontSize: 12)),
//                 ),
//               );
//             },
//             separatorBuilder: (_, __) => const SizedBox(height: 8),
//             itemCount: requests.length,
//           ),
//         ),
//       ]),
//     );
//   }
// }

// /* ---------------------------
//    Profile Page
//    --------------------------- */
// class ProfilePage extends StatelessWidget {
//   final Map<String, dynamic>? profile;
//   final VoidCallback onLogout;
//   const ProfilePage({super.key, required this.profile, required this.onLogout});

//   @override
//   Widget build(BuildContext context) {
//     final name = profile != null ? (profile!['full_name'] ?? '') : '';
//     final email = profile != null ? (profile!['email'] ?? '') : '';

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
//         Center(
//           child: Column(
//             children: [
//               CircleAvatar(
//                 radius: 44,
//                 backgroundColor: Colors.redAccent.withOpacity(0.2),
//                 backgroundImage:
//                     profile != null && profile!['avatar_url'] != null
//                         ? NetworkImage(profile!['avatar_url'])
//                         : null,
//                 child: profile == null || profile!['avatar_url'] == null
//                     ? const Icon(Icons.person, size: 44, color: Colors.white70)
//                     : null,
//               ),
//               const SizedBox(height: 12),
//               Text(name,
//                   style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600)),
//               const SizedBox(height: 6),
//               Text(email, style: const TextStyle(color: Colors.white70)),
//             ],
//           ),
//         ),
//         const SizedBox(height: 30),
//         ListTile(
//           tileColor: const Color(0xFF1E1E1E),
//           leading: const Icon(Icons.edit, color: Colors.white70),
//           title:
//               const Text('Edit Profile', style: TextStyle(color: Colors.white)),
//           onTap: () {
//             // TODO: open edit profile page
//           },
//         ),
//         const SizedBox(height: 8),
//         ListTile(
//           tileColor: const Color(0xFF1E1E1E),
//           leading: const Icon(Icons.location_on, color: Colors.white70),
//           title: const Text('Manage Addresses',
//               style: TextStyle(color: Colors.white)),
//           onTap: () {
//             // TODO: manage addresses
//           },
//         ),
//         const SizedBox(height: 8),
//         ListTile(
//           tileColor: const Color(0xFF1E1E1E),
//           leading:
//               const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
//           title: const Text('Privacy & Security',
//               style: TextStyle(color: Colors.white)),
//           onTap: () {
//             // TODO: settings
//           },
//         ),
//         const SizedBox(height: 8),
//         ListTile(
//           tileColor: const Color(0xFF1E1E1E),
//           leading: const Icon(Icons.logout, color: Colors.white70),
//           title: const Text('Logout', style: TextStyle(color: Colors.white)),
//           onTap: onLogout,
//         ),
//       ]),
//     );
//   }
// }
