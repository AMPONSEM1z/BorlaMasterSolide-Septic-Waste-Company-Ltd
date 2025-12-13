import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  bool loading = true;
  bool actionLoading = false;
  List<Map<String, dynamic>> customers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => loading = true);
    try {
      final res = await supabase.from('customers').select();
      var list = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      final queryText = _searchController.text.trim().toLowerCase();
      if (queryText.isNotEmpty) {
        list = list.where((c) {
          final name = (c['full_name'] ?? '').toString().toLowerCase();
          final email = (c['email'] ?? '').toString().toLowerCase();
          return name.contains(queryText) || email.contains(queryText);
        }).toList();
      }
      setState(() => customers = list);
        } catch (e) {
      debugPrint('Error loading customers: $e');
      setState(() => customers = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> customer) async {
    final id = customer['id'] as String?;
    if (id == null) return;
    final current = customer['role'] == 'customer'; // active by default
    final newVal = current ? 'inactive' : 'customer';

    setState(() => actionLoading = true);
    try {
      await supabase.from('customers').update({'role': newVal}).eq('id', id);
      setState(() {
        final idx = customers.indexWhere((c) => c['id'] == id);
        if (idx >= 0) customers[idx]['role'] = newVal;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${customer['full_name']} is now ${newVal == 'customer' ? 'active' : 'inactive'}'),
      ));
    } catch (e) {
      debugPrint('Error toggling status: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      setState(() => actionLoading = false);
    }
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final id = customer['id'] as String?;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer['full_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await supabase.from('customers').delete().eq('id', id);
      _loadCustomers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed')));
    }
  }

  Future<void> _openCustomerForm({Map<String, dynamic>? customer}) async {
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?['full_name']);
    final emailController = TextEditingController(text: customer?['email']);
    final phoneController = TextEditingController(text: customer?['phone_number']);
    final addressController = TextEditingController(text: customer?['address']);
    final avatarController = TextEditingController(text: customer?['avatar_url']);
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 18, left: 18, right: 18),
          child: StatefulBuilder(
            builder: (context, setState) {
              return ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                          color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(isEditing ? 'Edit Customer' : 'Add Customer',
                      style: const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avatarController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Avatar URL', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            try {
                              if (isEditing) {
                                await supabase.from('customers').update({
                                  'full_name': nameController.text,
                                  'email': emailController.text,
                                  'phone_number': phoneController.text,
                                  'address': addressController.text,
                                  'avatar_url': avatarController.text,
                                }).eq('id', customer['id']);
                              } else {
                                await supabase.from('customers').insert({
                                  'full_name': nameController.text,
                                  'email': emailController.text,
                                  'phone_number': phoneController.text,
                                  'address': addressController.text,
                                  'avatar_url': avatarController.text,
                                });
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(isEditing ? 'Customer updated' : 'Customer added')));
                              Navigator.of(ctx).pop();
                              _loadCustomers();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed')));
                            } finally {
                              setState(() => saving = false);
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEditing ? 'Save Changes' : 'Add Customer'),
                  ),
                  const SizedBox(height: 36),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCustomerDetails(Map<String, dynamic> customer) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return CustomerDetailsSheet(
          customer: customer,
          onUpdated: _loadCustomers,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search customer by name or email',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    ),
                    onChanged: (v) => _loadCustomers(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openCustomerForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : customers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline, color: Colors.white24, size: 42),
                              SizedBox(height: 8),
                              Text('No customers found', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, idx) {
                            final c = customers[idx];
                            final active = c['role'] == 'customer';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: c['avatar_url'] != null ? NetworkImage(c['avatar_url']) : null,
                                child: c['avatar_url'] == null ? Text(c['full_name'][0].toUpperCase()) : null,
                              ),
                              title: Text(c['full_name'] ?? '—', style: const TextStyle(color: Colors.white)),
                              subtitle: Text(c['email'] ?? '—', style: const TextStyle(color: Colors.white70)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: active,
                                    onChanged: (_) => _toggleActive(c),
                                    activeThumbColor: Colors.blueAccent,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white70),
                                    onPressed: () => _openCustomerForm(customer: c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteCustomer(c),
                                  ),
                                ],
                              ),
                              onTap: () => _openCustomerDetails(c),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onUpdated;

  const CustomerDetailsSheet({
    required this.customer,
    required this.onUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final active = customer['role'] == 'customer';
    return Container(
      padding: const EdgeInsets.all(18),
      color: const Color(0xFF121212),
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6))),
          ),
          const SizedBox(height: 12),
          Text(customer['full_name'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 6),
          Text(customer['email'] ?? '—', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(customer['phone_number'] ?? '—', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(customer['address'] ?? '—', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Active', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              Switch(
                  value: active,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (_) async {
                    final newVal = active ? 'inactive' : 'customer';
                    await supabase.from('customers').update({'role': newVal}).eq('id', customer['id']);
                    onUpdated();
                  }),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
