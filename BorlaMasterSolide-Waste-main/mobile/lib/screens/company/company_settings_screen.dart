import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  String? companyName, slogan, about, phone, brandColor, logoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('companies')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          companyName = data['company_name'] ?? '';
          slogan = data['slogan'] ?? '';
          about = data['about'] ?? '';
          phone = data['contact_phone'] ?? '';
          brandColor = data['brand_color'] ?? '#FF0000';
          logoUrl = data['company_logo_url'];
        });
      }
    } catch (e) {
      debugPrint('Error loading company: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('companies').update({
        'company_name': companyName,
        'slogan': slogan,
        'about': about,
        'contact_phone': phone,
        'brand_color': brandColor,
      }).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      debugPrint('Error saving company: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text('Company Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              initialValue: companyName,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Company Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              onSaved: (v) => companyName = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: slogan,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Slogan',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              onSaved: (v) => slogan = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: about,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'About',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              onSaved: (v) => about = v,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              onSaved: (v) => phone = v,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveProfile,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size.fromHeight(48)),
            ),
          ]),
        ),
      ),
    );
  }
}
