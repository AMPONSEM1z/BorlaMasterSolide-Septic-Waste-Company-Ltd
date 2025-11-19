import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestPickupScreen extends StatefulWidget {
  const RequestPickupScreen({super.key});

  @override
  State<RequestPickupScreen> createState() => _RequestPickupScreenState();
}

class _RequestPickupScreenState extends State<RequestPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRegion;
  String? _selectedTown;
  String? _selectedWasteType;
  Map<String, dynamic>? _selectedCompany;
  DateTime? _pickupDate;
  bool _loading = false;

  String? _solidWasteWeight;
  String? _septicSize;
  double? _calculatedPrice;

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _towns = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final res = await supabase.from('regions').select();
      setState(() => _regions = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error loading regions: $e');
    }
  }

  Future<void> _loadTowns(String regionName) async {
    try {
      final res =
          await supabase.from('towns').select().eq('region_name', regionName);
      final townsList = List<Map<String, dynamic>>.from(res);

      final uniqueTowns = <String, Map<String, dynamic>>{};
      for (var t in townsList) {
        uniqueTowns[t['town_name']] = t;
      }

      setState(() => _towns = uniqueTowns.values.toList());
    } catch (e) {
      debugPrint('Error loading towns: $e');
    }
  }

  Future<void> _loadCompanyForLocation() async {
    if (_selectedWasteType == null ||
        _selectedRegion == null ||
        _selectedTown == null) {
      setState(() => _selectedCompany = null);
      return;
    }

    try {
      final res = await supabase
          .from('companies')
          .select()
          .eq('company_type', _selectedWasteType!)
          .contains('regions_served', [_selectedRegion!]).contains(
              'towns_served', [_selectedTown!]).limit(1);

      final companies = List<Map<String, dynamic>>.from(res);
      if (companies.isNotEmpty) {
        setState(() => _selectedCompany = companies.first);
      } else {
        setState(() => _selectedCompany = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No company serves this location')),
        );
      }
    } catch (e) {
      debugPrint('Error loading company: $e');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.redAccent,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF121212),
        ),
        child: child!,
      ),
    );

    if (picked != null) setState(() => _pickupDate = picked);
  }

  // Real-time validation & price calculation
  void _calculatePrice() {
    double? price;

    if (_selectedWasteType == 'Solid Waste' && _solidWasteWeight != null) {
      final weight = double.tryParse(_solidWasteWeight!);
      if (weight == null || weight <= 0) {
        price = null;
      } else if (weight < 10) {
        price = 100;
      } else if (weight <= 15) {
        price = 300;
      } else if (weight <= 30) {
        price = 500;
      } else if (weight > 50) {
        price = 1000;
      } else {
        price = 0;
      }
    } else if (_selectedWasteType == 'Septic Tank' && _septicSize != null) {
      if (_septicSize == 'Small') {
        price = 400;
      } else if (_septicSize == 'Large') {
        price = 900;
      }
    } else {
      price = null;
    }

    setState(() => _calculatedPrice = price);
  }

  bool _isFormValid() {
    return _formKey.currentState?.validate() == true &&
        _selectedRegion != null &&
        _selectedTown != null &&
        _selectedWasteType != null &&
        _pickupDate != null &&
        _selectedCompany != null &&
        _calculatedPrice != null &&
        _calculatedPrice! > 0;
  }

  Future<void> _submitRequest() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields correctly')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      String wasteDetail = _selectedWasteType == 'Solid Waste'
          ? '$_solidWasteWeight kg'
          : _septicSize ?? '';

      await supabase.from('bookings').insert({
        'customer_id': user.id,
        'waste_type': _selectedWasteType,
        'waste_detail': wasteDetail,
        'region': _selectedRegion,
        'town': _selectedTown,
        'company_id': _selectedCompany!['id'],
        'pickup_date': _pickupDate!.toIso8601String(),
        'status': 'pending_company_accept',
        'amount_due': _calculatedPrice,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Pickup request sent successfully! Price: GHS ${_calculatedPrice!.toStringAsFixed(2)}')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Request Pickup'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Waste Type
              DropdownButtonFormField<String>(
                value: _selectedWasteType,
                dropdownColor: const Color(0xFF1E1E1E),
                decoration: const InputDecoration(
                  labelText: 'Waste Type',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon:
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Solid Waste', child: Text('Solid Waste')),
                  DropdownMenuItem(
                      value: 'Septic Tank', child: Text('Septic Tank')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedWasteType = val;
                    _solidWasteWeight = null;
                    _septicSize = null;
                    _calculatedPrice = null;
                  });
                  _loadCompanyForLocation();
                },
                validator: (value) =>
                    value == null ? 'Please select waste type' : null,
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 20),

              // Weight or Size Input
              if (_selectedWasteType == 'Solid Waste')
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.scale, color: Colors.redAccent),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    _solidWasteWeight = val;
                    _calculatePrice();
                  },
                  validator: (val) {
                    final w = double.tryParse(val ?? '');
                    if (_selectedWasteType == 'Solid Waste' &&
                        (val == null || val.isEmpty || w == null || w <= 0)) {
                      return 'Enter a valid weight';
                    }
                    return null;
                  },
                ),

              if (_selectedWasteType == 'Septic Tank')
                DropdownButtonFormField<String>(
                  value: _septicSize,
                  dropdownColor: const Color(0xFF1E1E1E),
                  decoration: const InputDecoration(
                    labelText: 'Tank Size',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.water_drop, color: Colors.redAccent),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Small', child: Text('Small')),
                    DropdownMenuItem(value: 'Large', child: Text('Large')),
                  ],
                  onChanged: (val) {
                    setState(() => _septicSize = val);
                    _calculatePrice();
                  },
                  validator: (val) =>
                      (_selectedWasteType == 'Septic Tank' && val == null)
                          ? 'Select tank size'
                          : null,
                  style: const TextStyle(color: Colors.white),
                ),

              const SizedBox(height: 20),

              // Show calculated price
              if (_calculatedPrice != null)
                Text(
                  'Price: GHS ${_calculatedPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),

              const SizedBox(height: 20),

              // Region
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                dropdownColor: const Color(0xFF1E1E1E),
                decoration: const InputDecoration(
                  labelText: 'Region',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.map_outlined, color: Colors.redAccent),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                items: _regions
                    .map((r) => DropdownMenuItem<String>(
                          value: r['region_name'],
                          child: Text(r['region_name']),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRegion = val;
                    _selectedTown = null;
                    _towns = [];
                  });
                  if (val != null) _loadTowns(val);
                  _loadCompanyForLocation();
                },
                validator: (value) =>
                    value == null ? 'Please select region' : null,
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 20),

              // Town
              DropdownButtonFormField<String>(
                value: _selectedTown,
                dropdownColor: const Color(0xFF1E1E1E),
                decoration: const InputDecoration(
                  labelText: 'Town',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.location_city_outlined,
                      color: Colors.redAccent),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                items: _towns
                    .map((t) => DropdownMenuItem<String>(
                          value: t['town_name'],
                          child: Text(t['town_name']),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedTown = val);
                  _loadCompanyForLocation();
                },
                validator: (value) =>
                    value == null ? 'Please select town' : null,
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 10),

              // Show assigned company
              if (_selectedCompany != null)
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.redAccent),
                  title: Text(
                    'Assigned Company: ${_selectedCompany!['company_name']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

              const SizedBox(height: 20),

              // Pickup Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.calendar_today, color: Colors.redAccent),
                title: Text(
                  _pickupDate == null
                      ? 'Select Pickup Date'
                      : 'Pickup Date: ${DateFormat('yyyy-MM-dd').format(_pickupDate!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text(
                    'Choose Date',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              _loading
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton(
                      onPressed: _isFormValid() ? _submitRequest : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid()
                            ? Colors.redAccent
                            : Colors.redAccent.withOpacity(0.5),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Pickup Request',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
