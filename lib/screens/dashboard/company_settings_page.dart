import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanySettingsPage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onProfileUpdated;

  const CompanySettingsPage({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<CompanySettingsPage> createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController regionController;
  late TextEditingController townController;
  late TextEditingController phoneController;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.profile?['company_name'] ?? '');
    regionController =
        TextEditingController(text: widget.profile?['region'] ?? '');
    townController = TextEditingController(text: widget.profile?['town'] ?? '');
    phoneController =
        TextEditingController(text: widget.profile?['phone'] ?? '');
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('companies').update({
        'company_name': nameController.text.trim(),
        'region': regionController.text.trim(),
        'town': townController.text.trim(),
        'phone': phoneController.text.trim(),
      }).eq('id', user.id);

      widget.onProfileUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating company profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text('Company Settings'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Update Company Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                        controller: nameController,
                        label: 'Company Name',
                        icon: Icons.business),
                    _buildInputField(
                        controller: regionController,
                        label: 'Region',
                        icon: Icons.location_on),
                    _buildInputField(
                        controller: townController,
                        label: 'Town',
                        icon: Icons.map),
                    _buildInputField(
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text('Logout',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
