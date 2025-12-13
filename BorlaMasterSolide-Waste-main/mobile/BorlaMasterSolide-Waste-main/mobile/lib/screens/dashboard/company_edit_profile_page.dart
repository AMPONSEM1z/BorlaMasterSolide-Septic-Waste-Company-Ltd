import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const CompanyEditProfilePage({super.key, required this.profile});

  @override
  State<CompanyEditProfilePage> createState() => _CompanyEditProfilePageState();
}

class _CompanyEditProfilePageState extends State<CompanyEditProfilePage> {
  final supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _aboutController;
  late TextEditingController _contactController;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile['company_name'] ?? '');
    _typeController =
        TextEditingController(text: widget.profile['company_type'] ?? '');
    _aboutController =
        TextEditingController(text: widget.profile['about'] ?? '');
    _contactController =
        TextEditingController(text: widget.profile['contact_number'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _aboutController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No logged-in user');

      final updates = {
        'company_name': _nameController.text.trim(),
        'company_type': _typeController.text.trim(),
        'about': _aboutController.text.trim(),
        'contact_number': _contactController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('companies')
          .update(updates)
          .eq('auth_user_id', user.id);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Edit Company Profile'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Company Name', _nameController),
            const SizedBox(height: 16),
            _buildTextField('Company Type', _typeController),
            const SizedBox(height: 16),
            _buildTextField('Contact Number', _contactController),
            const SizedBox(height: 16),
            _buildMultilineField('About the Company', _aboutController),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildMultilineField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 5,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
