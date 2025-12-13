import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const EditProfilePage({super.key, this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile?['full_name'] ?? '');
    _emailController =
        TextEditingController(text: widget.profile?['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? avatarUrl = widget.profile?['avatar_url'];

      // If user picked a new image, upload it
      if (_pickedImage != null) {
        final fileExt = _pickedImage!.path.split('.').last;
        final filePath = 'avatars/${user.id}.$fileExt';
        await supabase.storage.from('avatars').upload(
              filePath,
              _pickedImage!,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );

        // Updated: getPublicUrl now returns a String directly
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      // Update profile in database
      final updates = {
        'full_name': _nameController.text,
        'email': _emailController.text,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('profiles').update(updates).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh profile
      }
    } catch (e) {
      debugPrint('❌ Failed to update profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (widget.profile?['avatar_url'] != null
                          ? NetworkImage(widget.profile!['avatar_url'])
                          : null) as ImageProvider<Object>?,
                  child: _pickedImage == null &&
                          widget.profile?['avatar_url'] == null
                      ? const Icon(Icons.camera_alt,
                          size: 44, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Name cannot be empty'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
