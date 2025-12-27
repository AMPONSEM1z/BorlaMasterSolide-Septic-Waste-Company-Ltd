// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'company_edit_profile_page.dart';
// import 'company_change_password_page.dart';

<<<<<<< HEAD
// class CompanyProfilePage extends StatefulWidget {
//   final VoidCallback onLogout;

//   const CompanyProfilePage({
//     super.key,
//     required this.onLogout,
//   });
=======
class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});
>>>>>>> 820755595d1e34fff3d64ff0014a6e6178bc4c31

//   @override
//   State<CompanyProfilePage> createState() => _CompanyProfilePageState();
// }

// class _CompanyProfilePageState extends State<CompanyProfilePage> {
//   final supabase = Supabase.instance.client;
//   Map<String, dynamic>? _profile;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCompanyProfile();
//   }

//   Future<void> _fetchCompanyProfile() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) {
//       setState(() => _loading = false);
//       return;
//     }

//     try {
//       final data = await supabase
//           .from('companies')
//           .select()
//           .eq('auth_user_id', user.id)
//           .maybeSingle();

<<<<<<< HEAD
//       if (mounted) {
//         setState(() {
//           _profile = data != null ? Map<String, dynamic>.from(data) : null;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching company profile: $e');
//       setState(() => _loading = false);
//     }
//   }
=======
      if (mounted) {
        setState(() {
          _profile = data != null ? Map<String, dynamic>.from(data) : null;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching company profile: $e');
      setState(() => _loading = false);
    }
  }
>>>>>>> 820755595d1e34fff3d64ff0014a6e6178bc4c31

//   Future<void> _refreshProfile() async {
//     await _fetchCompanyProfile();
//   }

<<<<<<< HEAD
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }
=======
  // ✅ FIXED LOGOUT (same logic as working page)
  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
>>>>>>> 820755595d1e34fff3d64ff0014a6e6178bc4c31

//     if (_profile == null) {
//       return const Center(
//         child: Text(
//           'No company profile found.',
//           style: TextStyle(color: Colors.white),
//         ),
//       );
//     }

//     final companyName = _profile!['company_name'] ?? '';
//     final email = _profile!['email'] ?? '';
//     final phone = _profile!['contact_number'] ?? '';

<<<<<<< HEAD
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           CircleAvatar(
//             radius: 44,
//             backgroundColor: Colors.redAccent.withOpacity(0.2),
//             backgroundImage: _profile!['logo_url'] != null
//                 ? NetworkImage(_profile!['logo_url'])
//                 : null,
//             child: _profile!['logo_url'] == null
//                 ? const Icon(Icons.business, size: 44, color: Colors.white70)
//                 : null,
//           ),
//           const SizedBox(height: 12),
//           Text(companyName,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600)),
//           const SizedBox(height: 6),
//           Text(email, style: const TextStyle(color: Colors.white70)),
//           const SizedBox(height: 2),
//           Text(phone, style: const TextStyle(color: Colors.white70)),
//           const SizedBox(height: 30),
//           _buildTile(
//             icon: Icons.edit,
//             title: 'Edit Profile',
//             onTap: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       CompanyEditProfilePage(profile: _profile ?? {}),
//                 ),
//               );
//               if (result == true && mounted) {
//                 await _refreshProfile();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Profile updated!'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               }
//             },
//           ),
//           _buildTile(
//             icon: Icons.lock,
//             title: 'Change Password',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const CompanyChangePasswordPage(),
//                 ),
//               );
//             },
//           ),
//           _buildTile(
//             icon: Icons.account_balance_wallet_outlined,
//             title: 'Wallet',
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Wallet feature coming soon!'),
//                   backgroundColor: Colors.orangeAccent,
//                 ),
//               );
//             },
//           ),
//           _buildTile(
//             icon: Icons.logout,
//             title: 'Logout',
//             onTap: widget.onLogout,
//           ),
//         ],
//       ),
//     );
//   }
=======
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            backgroundImage: _profile!['logo_url'] != null
                ? NetworkImage(_profile!['logo_url'])
                : null,
            child: _profile!['logo_url'] == null
                ? const Icon(Icons.business, size: 44, color: Colors.white70)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            companyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 2),
          Text(phone, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),

          _buildTile(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CompanyEditProfilePage(profile: _profile ?? {}),
                ),
              );

              if (result == true && mounted) {
                await _refreshProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),

          _buildTile(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompanyChangePasswordPage(),
                ),
              );
            },
          ),

          _buildTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet feature coming soon!'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            },
          ),

          // ✅ WORKING LOGOUT
          _buildTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _logout,
          ),
        ],
      ),
    );
  }
>>>>>>> 820755595d1e34fff3d64ff0014a6e6178bc4c31

//   Widget _buildTile({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white70),
//         title: Text(title, style: const TextStyle(color: Colors.white)),
//         trailing: const Icon(Icons.arrow_forward_ios,
//             size: 16, color: Colors.white38),
//         onTap: onTap,
//       ),
//     );
//   }
// }
