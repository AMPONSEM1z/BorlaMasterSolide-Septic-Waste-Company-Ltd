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

  String? selectedService; // 'solid' or 'septic'

  // Controllers for Solid Waste
  final List<Map<String, dynamic>> solidRules = [
    {'min': 0, 'max': 10, 'controller': TextEditingController()},
    {'min': 10, 'max': 15, 'controller': TextEditingController()},
    {'min': 15, 'max': 30, 'controller': TextEditingController()},
    {'min': 50, 'max': 9999, 'controller': TextEditingController()},
  ];

  // Controllers for Septic Waste
  final Map<String, TextEditingController> septicControllers = {
    'small': TextEditingController(),
    'large': TextEditingController(),
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

  /// Load company profile and pricing
  Future<void> _loadProfileAndPricing() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final data = await supabase
          .from('companies')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (data != null) {
        profile = Map<String, dynamic>.from(data);

        // Load selected service type
        selectedService = profile?['service_type'];

        // Load pricing JSON
        final pricing = profile?['pricing'] ?? {};

        // Solid Waste
        if (pricing['solid_waste']?['rules'] != null) {
          final rules = pricing['solid_waste']['rules'] as List;
          for (int i = 0; i < solidRules.length && i < rules.length; i++) {
            solidRules[i]['controller'].text =
                rules[i]['price']?.toString() ?? '';
          }
        }

        // Septic Waste
        if (pricing['septic_tank'] != null) {
          final septic = pricing['septic_tank'] as Map;
          septicControllers.forEach((key, controller) {
            controller.text = septic[key]?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile/pricing: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  /// Save pricing to Supabase
  Future<void> _savePricing() async {
    if (selectedService == null) return;

    setState(() => saving = true);

    final Map<String, dynamic> pricing =
        Map<String, dynamic>.from(profile?['pricing'] ?? {});
    // 🔐 VALIDATION — ADD THIS BLOCK
    if (selectedService == 'solid') {
      final hasValidPrice = solidRules.any(
        (rule) => (int.tryParse(rule['controller'].text) ?? 0) > 0,
      );

      if (!hasValidPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter at least one solid waste price'),
          ),
        );
        setState(() => saving = false);
        return;
      }
    }

    if (selectedService == 'septic') {
      final hasValidPrice = septicControllers.values.any(
        (controller) => (int.tryParse(controller.text) ?? 0) > 0,
      );

      if (!hasValidPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter septic pricing'),
          ),
        );
        setState(() => saving = false);
        return;
      }
    }

    if (selectedService == 'solid') {
      pricing['solid_waste'] = {
        'rules': solidRules.map((rule) {
          return {
            'min': rule['min'],
            'max': rule['max'],
            'price': int.tryParse(rule['controller'].text) ?? 0,
          };
        }).toList(),
      };
    } else if (selectedService == 'septic') {
      final septicPricing = <String, int>{};
      septicControllers.forEach((key, controller) {
        septicPricing[key] = int.tryParse(controller.text) ?? 0;
      });
      pricing['septic_tank'] = septicPricing;
    }

    try {
      await supabase.from('companies').update({
        'service_type': selectedService,
        'pricing': pricing,
      }).eq('auth_user_id', supabase.auth.currentUser!.id);

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
    if (selectedService == 'solid') return _buildSolidWasteSection();
    if (selectedService == 'septic') return _buildSepticWasteSection();
    return const SizedBox.shrink();
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
            const Text(
              'Solid Waste Pricing',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...solidRules.map((rule) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: rule['controller'],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '${rule['min']} - ${rule['max']} kg (GHS)',
                    filled: true,
                    fillColor: Colors.grey[850],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSepticWasteSection() => _pricingCard(
        title: 'Septic Waste Pricing',
        controllers: septicControllers,
      );

  Widget _pricingCard({
    required String title,
    required Map<String, TextEditingController> controllers,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...controllers.entries.map((entry) {
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
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
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
                  const Text(
                    'Select Service Type:',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: selectedService,
                      dropdownColor: Colors.grey[850],
                      hint: const Text('Choose Service',
                          style: TextStyle(color: Colors.white70)),
                      isExpanded: true,
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() {
                          selectedService = val;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 'solid', child: Text('Solid Waste')),
                        DropdownMenuItem(
                            value: 'septic', child: Text('Septic Waste')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPricingFields(),
                  if (selectedService != null)
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
