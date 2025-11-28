import 'package:flutter/material.dart';
import '../dashboard/edit_profile_page.dart';
import '../dashboard/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.profile, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile != null ? (_profile!['full_name'] ?? '') : '';
    final email = _profile != null ? (_profile!['email'] ?? '') : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            backgroundImage: _profile != null && _profile!['avatar_url'] != null
                ? NetworkImage(_profile!['avatar_url'])
                : null,
            child: _profile == null || _profile!['avatar_url'] == null
                ? const Icon(Icons.person, size: 44, color: Colors.white70)
                : null,
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),

          // ------------------------------
          // PROFILE FEATURE TILES
          // ------------------------------
          _buildTile(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(profile: _profile),
                ),
              );
              if (result == true && mounted) {
                // Refresh profile
                setState(() {
                  _profile =
                      result; // return updated profile from EditProfilePage
                });
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
                  builder: (_) => const ChangePasswordPage(),
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
          _buildTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
