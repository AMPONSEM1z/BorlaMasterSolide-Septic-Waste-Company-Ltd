import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;
  bool loading = true;
  bool saving = false;

  String? selectedWasteType; // 'Solid Waste' or 'Septic Waste'

  // Controllers for Solid Waste
  final Map<String, TextEditingController> solidControllers = {
    '<10kg': TextEditingController(),
    '10-15kg': TextEditingController(),
    '15-30kg': TextEditingController(),
    '50kg+': TextEditingController(),
  };

  // Controllers for Septic Waste
  final Map<String, TextEditingController> septicControllers = {
    'Small': TextEditingController(),
    'Large': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadProfileAndPricing();
  }

  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _loadProfileAndPricing() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch company profile
      final data = await supabase
          .from('companies')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (data != null) {
        profile = Map<String, dynamic>.from(data);

        // Load existing pricing
        final pricing = profile?['pricing'] ?? {};
        // Solid Waste
        final solid = pricing['solid_waste'] ?? {};
        solidControllers.forEach((key, controller) {
          controller.text = solid[key]?.toString() ?? '';
        });
        // Septic Waste
        final septic = pricing['septic_waste'] ?? {};
        septicControllers.forEach((key, controller) {
          controller.text = septic[key]?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile/pricing: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _savePricing() async {
    setState(() => saving = true);

    final solidPricing = <String, int>{};
    solidControllers.forEach((key, controller) {
      solidPricing[key] = int.tryParse(controller.text) ?? 0;
    });

    final septicPricing = <String, int>{};
    septicControllers.forEach((key, controller) {
      septicPricing[key] = int.tryParse(controller.text) ?? 0;
    });

    final pricing = {
      'solid_waste': solidPricing,
      'septic_waste': septicPricing,
    };

    try {
      await supabase.from('companies').update({'pricing': pricing}).eq(
          'auth_user_id', supabase.auth.currentUser!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pricing saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving pricing: $e')),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  Widget _buildPricingFields() {
    if (selectedWasteType == 'Solid Waste') {
      return _buildSolidWasteSection();
    } else if (selectedWasteType == 'Septic Waste') {
      return _buildSepticWasteSection();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSolidWasteSection() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Solid Waste Pricing',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...solidControllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '${entry.key} (GHS)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSepticWasteSection() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Septic Waste Pricing',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...septicControllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '${entry.key} (GHS)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getTimeBasedGreeting()}, ${profile?['company_name'] ?? 'Company'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Waste Type:',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: selectedWasteType,
                      dropdownColor: Colors.grey[850],
                      hint: const Text('Choose Waste Type',
                          style: TextStyle(color: Colors.white70)),
                      isExpanded: true,
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() {
                          selectedWasteType = val;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 'Solid Waste', child: Text('Solid Waste')),
                        DropdownMenuItem(
                            value: 'Septic Waste', child: Text('Septic Waste')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPricingFields(),
                  if (selectedWasteType != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _savePricing,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: saving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Save Pricing',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
