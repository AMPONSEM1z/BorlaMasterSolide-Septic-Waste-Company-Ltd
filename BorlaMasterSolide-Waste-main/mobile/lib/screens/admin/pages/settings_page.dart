import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool loading = true;
  bool saving = false;

  // Notification toggle
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Fetch profile from 'profiles' table
        final res =
            await supabase.from('profiles').select().eq('id', user.id).single();
        final profile = res;
        _nameController.text = profile['name'] ?? '';
        _emailController.text = user.email ?? '';
        notificationsEnabled = profile['notifications'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'No authenticated user';

      // Update profile
      await supabase.from('profiles').update({
        'name': _nameController.text.trim(),
        'notifications': notificationsEnabled,
      }).eq('id', user.id);

      // Update password if not empty
      if (_passwordController.text.trim().isNotEmpty) {
        await supabase.auth.updateUser(
            UserAttributes(password: _passwordController.text.trim()));
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')));
    } catch (e) {
      debugPrint('Error saving settings: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: const Color(0xFF121212),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 600 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Profile',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white70),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: const Text('Enable Notifications',
                              style: TextStyle(color: Colors.white)),
                          value: notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => notificationsEnabled = val),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent),
                            child: saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Save Settings'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await supabase.auth.signOut();
                              if (!mounted) return;
                              Navigator.of(context)
                                  .pop(); // Return to login or home
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            child: const Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
