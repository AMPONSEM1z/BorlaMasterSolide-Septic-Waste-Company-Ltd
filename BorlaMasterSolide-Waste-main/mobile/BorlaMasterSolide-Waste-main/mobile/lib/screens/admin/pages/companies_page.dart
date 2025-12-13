import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  bool loading = true;
  bool actionLoading = false;
  List<Map<String, dynamic>> companies = [];
  List<String> regions = [];
  String? selectedRegion;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    await Future.wait([_loadRegions(), _loadCompanies()]);
    setState(() => loading = false);
  }

  Future<void> _loadRegions() async {
    try {
      final res = await supabase.from('regions').select('region_name');
      if (res is List) {
        final names = res.map<String>((r) => r['region_name'].toString()).toList();
        setState(() => regions = names);
      }
    } catch (e) {
      debugPrint('Error loading regions: $e');
    }
  }

  Future<void> _loadCompanies() async {
    setState(() => loading = true);
    try {
      final res = await supabase.from('companies').select();
      if (res is List) {
        var list = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Filter by region
        if (selectedRegion != null && selectedRegion!.isNotEmpty) {
          list = list.where((c) {
            final regionsServed = (c['regions_served'] ?? []) as List<dynamic>;
            return regionsServed.contains(selectedRegion);
          }).toList();
        }

        // Client-side search
        final queryText = _searchController.text.trim().toLowerCase();
        if (queryText.isNotEmpty) {
          list = list.where((c) {
            final name = (c['company_name'] ?? '').toString().toLowerCase();
            final email = (c['contact_email'] ?? '').toString().toLowerCase();
            return name.contains(queryText) || email.contains(queryText);
          }).toList();
        }

        setState(() => companies = list);
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      setState(() => companies = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleAvailability(Map<String, dynamic> company) async {
    final id = company['id'] as String?;
    if (id == null) return;

    final current = company['available_for_customers'] == true;
    final newVal = !current;

    setState(() => actionLoading = true);
    try {
      await supabase.from('companies').update({'available_for_customers': newVal}).eq('id', id);

      // Update local list
      setState(() {
        final idx = companies.indexWhere((c) => c['id'] == id);
        if (idx >= 0) companies[idx]['available_for_customers'] = newVal;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${company['company_name']} is now ${newVal ? "visible" : "hidden"}'),
      ));
    } catch (e) {
      debugPrint('Error toggling availability: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      setState(() => actionLoading = false);
    }
  }

  Future<void> _openCompanyForm({Map<String, dynamic>? company}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          builder: (_, controller) {
            return CompanyFormSheet(
              company: company,
              onUpdated: () async {
                Navigator.of(ctx).pop();
                await _loadCompanies();
              },
              controller: controller,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Companies')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters & Search
            Row(
              children: [
                // Region filter
                DropdownButton<String>(
                  hint: const Text('Filter by region', style: TextStyle(color: Colors.white)),
                  value: selectedRegion,
                  dropdownColor: const Color(0xFF1E1E1E),
                  underline: const SizedBox(),
                  iconEnabledColor: Colors.redAccent,
                  items: [null, ...regions].map((r) {
                    return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r ?? 'All', style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (val) async {
                    setState(() => selectedRegion = val);
                    await _loadCompanies();
                  },
                ),
                const SizedBox(width: 12),
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search company or email',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    ),
                    onChanged: (v) => _loadCompanies(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: actionLoading ? null : _loadCompanies,
                  icon: const Icon(Icons.search),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                )
              ],
            ),
            const SizedBox(height: 16),
            // Companies list
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : companies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.business_outlined,
                                  color: Colors.white24, size: 42),
                              SizedBox(height: 8),
                              Text('No companies found',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: companies.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, idx) {
                            final c = companies[idx];
                            return CompanyCard(
                              company: c,
                              onToggleAvailability: () => _toggleAvailability(c),
                              onOpenDetails: () => _openCompanyForm(company: c),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () => _openCompanyForm(),
      ),
    );
  }
}

/// Company card
class CompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback onToggleAvailability;
  final VoidCallback onOpenDetails;

  const CompanyCard({
    required this.company,
    required this.onToggleAvailability,
    required this.onOpenDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final name = company['company_name'] ?? '—';
    final type = company['company_type'] ?? '—';
    final available = company['available_for_customers'] == true;

    return GestureDetector(
      onTap: onOpenDetails,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blueAccent.withOpacity(0.12),
              child: Text(name.toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(type, style: const TextStyle(color: Colors.white70)),
                  ]),
            ),
            Switch(
              value: available,
              activeColor: Colors.blueAccent,
              onChanged: (_) => onToggleAvailability(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add/Edit company sheet
class CompanyFormSheet extends StatefulWidget {
  final Map<String, dynamic>? company;
  final VoidCallback onUpdated;
  final ScrollController controller;

  const CompanyFormSheet({
    this.company,
    required this.onUpdated,
    required this.controller,
    super.key,
  });

  @override
  State<CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends State<CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?['company_name'] ?? '');
    _emailController = TextEditingController(text: widget.company?['contact_email'] ?? '');
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    final data = {
      'company_name': _nameController.text.trim(),
      'contact_email': _emailController.text.trim(),
    };

    try {
      if (widget.company == null) {
        // Add new company
        await supabase.from('companies').insert(data);
      } else {
        // Edit existing company
        await supabase.from('companies').update(data).eq('id', widget.company!['id']);
      }
      widget.onUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed')));
    } finally {
      setState(() => saving = false);
    }
  }

  Future<void> _deleteCompany() async {
    final id = widget.company?['id'];
    if (id == null) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this company?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
              ],
            ));
    if (confirmed != true) return;

    setState(() => saving = true);
    try {
      await supabase.from('companies').delete().eq('id', id);
      widget.onUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.company != null;
    return Container(
      padding: const EdgeInsets.all(18),
      color: const Color(0xFF121212),
      child: ListView(
        controller: widget.controller,
        children: [
          Center(
            child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6))),
          ),
          const SizedBox(height: 12),
          Text(isEditing ? 'Edit Company' : 'Add Company', style: const TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Company Name', filled: true, fillColor: Colors.white10),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Email', filled: true, fillColor: Colors.white10),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveCompany,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: saving ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? 'Save' : 'Add'),
                    ),
                  ),
                  if (isEditing) const SizedBox(width: 12),
                  if (isEditing)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving ? null : _deleteCompany,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Delete'),
                      ),
                    )
                ],
              )
            ]),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Close'))
        ],
      ),
    );
  }
}
