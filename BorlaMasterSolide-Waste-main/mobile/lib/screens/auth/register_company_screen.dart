// lib/screens/auth/register_company_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

final supabase = Supabase.instance.client;

class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  State<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _address = TextEditingController();

  // Logo & loading
  File? _logoFile;
  bool _loading = false;

  // Dropdown selections
  String? _selectedCompanyType; // 'Solid Waste' | 'Septic Tank'
  String? _selectedRegion;
  List<String> _selectedTowns = [];

  // Regions & towns data
  List<String> _regions = [];
  List<String> _towns = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _companyName.dispose();
    _email.dispose();
    _password.dispose();
    _address.dispose();
    super.dispose();
  }

  // -------------------------
  // Data loading from Supabase
  // -------------------------
  Future<void> _loadRegions() async {
    try {
      final data = await supabase.from('regions').select('region_name');
      if (data is List) {
        final regionNames = data
            .map<String>((r) => (r['region_name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        setState(() => _regions = regionNames);
      }
      debugPrint('✅ Regions loaded: $_regions');
    } catch (e) {
      debugPrint('❌ Error loading regions: $e');
    }
  }

  // When region changes, fetch towns for that region
  Future<void> _onRegionChanged(String? region) async {
    if (region == null) return;

    setState(() {
      _selectedRegion = region;
      _towns = [];
      _selectedTowns = [];
    });

    try {
      final townsData = await supabase
          .from('towns')
          .select('town_name')
          .eq('region_name', region);
      if (townsData is List) {
        final townsList = townsData
            .map<String>((t) => (t['town_name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        setState(() => _towns = townsList);
      }
      debugPrint('✅ Towns loaded for $region: $_towns');
    } catch (e) {
      debugPrint('❌ Error fetching towns for $region: $e');
    }
  }

  // -------------------------
  // Image picker for logo
  // -------------------------
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    try {
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _logoFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('❌ Error picking logo: $e');
    }
  }

  // -------------------------
  // Register company
  // -------------------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegion == null || _selectedTowns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a region and at least one town.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Build extraData ensuring non-null arrays for required columns
      final extraData = <String, dynamic>{
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'company_type': _selectedCompanyType,
        'regions_served': [_selectedRegion], // array
        'towns_served': _selectedTowns, // array
      };

      // pass avatarPath (local file path) for AuthService to upload
      final avatarPath = _logoFile?.path;

      // Call your AuthService sign up function (adapt if signature differs)
      final res = await AuthService.signUpWithEmail(
        email: _email.text.trim(),
        password: _password.text.trim(),
        fullName: _companyName.text.trim(),
        role: 'company',
        companyType: _selectedCompanyType,
        avatarPath: avatarPath,
        extraData: extraData,
      );

      if (res != null && res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Company registered successfully — please login.')),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed.')),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Error inserting user/company: $e\n$st');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // -------------------------
  // UI helpers
  // -------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent) : null,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Register as Company',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Logo picker
              GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blueAccent.withOpacity(0.12),
                  backgroundImage:
                      _logoFile != null ? FileImage(_logoFile!) : null,
                  child: _logoFile == null
                      ? const Icon(Icons.camera_alt,
                          color: Colors.blueAccent, size: 36)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _companyName,
                label: 'Company Name',
                icon: Icons.business_outlined,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Company name required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Company type
              DropdownButtonFormField<String>(
                value: _selectedCompanyType,
                decoration: InputDecoration(
                  labelText: 'Company Type',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Solid Waste', child: Text('Solid Waste')),
                  DropdownMenuItem(
                      value: 'Septic Tank', child: Text('Septic Tank')),
                ],
                onChanged: (v) => setState(() => _selectedCompanyType = v),
                validator: (v) => v == null ? 'Select company type' : null,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Region dropdown
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Region',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: _regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => _onRegionChanged(val),
                validator: (v) => v == null ? 'Select region' : null,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Towns MultiSelect (shows a friendly message if empty)
              _towns.isNotEmpty
                  ? MultiSelectDialogField<String>(
                      items: _towns
                          .map((t) => MultiSelectItem<String>(t, t))
                          .toList(),
                      title: const Text('Select Towns Served',
                          style: TextStyle(color: Colors.white)),
                      buttonText: const Text('Select Towns',
                          style: TextStyle(color: Colors.white)),
                      listType: MultiSelectListType.CHIP,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent, width: 1),
                      ),
                      chipDisplay: MultiSelectChipDisplay(
                        chipColor: Colors.blueAccent,
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                      onConfirm: (values) =>
                          setState(() => _selectedTowns = values),
                      initialValue: _selectedTowns,
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                          'No towns available for selected region.',
                          style: TextStyle(color: Colors.white70)),
                    ),

              const SizedBox(height: 12),

              _buildTextField(
                  controller: _address,
                  label: 'Address / Street',
                  icon: Icons.home_outlined,
                  validator: (_) => null),

              const SizedBox(height: 12),

              _buildTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  }),

              const SizedBox(height: 12),

              _buildTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.length < 6)
                      return 'Minimum 6 characters';
                    return null;
                  }),

              const SizedBox(height: 20),

              _loading
                  ? const CircularProgressIndicator(color: Colors.blueAccent)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Register Company',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Already have an account? Log in',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
