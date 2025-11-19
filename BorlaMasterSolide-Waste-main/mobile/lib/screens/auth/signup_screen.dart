import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final String role; // 'customer' or 'company'
  const SignupScreen({required this.role, super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  String? _companyType; // optional: 'solid_waste' or 'septic'
  File? _pickedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final x = await p.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200);
    if (x != null) {
      setState(() => _pickedImage = File(x.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await AuthService.signUpWithEmail(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
        fullName: _fullNameCtl.text.trim(),
        role: widget.role,
        companyType: _companyType,
        avatarPath: _pickedImage?.path,
      );

      if (res != null) {
        // show success and redirect to login or dashboard
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup successful. Please verify email.')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup failed.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.role == 'company';
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                child: _pickedImage == null ? const Icon(Icons.camera_alt, size: 36) : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameCtl,
              decoration: const InputDecoration(labelText: 'Full name / Company name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
            ),
            if (isCompany) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _companyType,
                items: const [
                  DropdownMenuItem(value: 'solid_waste', child: Text('Solid waste (Garbage)')),
                  DropdownMenuItem(value: 'septic', child: Text('Septic')),
                ],
                onChanged: (v) => setState(() => _companyType = v),
                decoration: const InputDecoration(labelText: 'Company type'),
                validator: (v) => v == null ? 'Select company type' : null,
              ),
            ],
            const SizedBox(height: 20),
            _loading ? const CircularProgressIndicator() :
            ElevatedButton(onPressed: _submit, child: const Text('Create account')),
          ]),
        ),
      ),
    );
  }
}