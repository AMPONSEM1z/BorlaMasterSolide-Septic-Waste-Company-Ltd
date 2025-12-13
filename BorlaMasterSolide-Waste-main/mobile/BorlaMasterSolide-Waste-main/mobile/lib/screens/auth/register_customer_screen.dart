import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();

  File? _avatar;
  bool _loading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _avatar = File(picked.path));
  }

  Future<void> _register() async {
    if (_fullName.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty ||
        _address.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _loading = true);

    final res = await AuthService.signUpWithEmail(
      email: _email.text.trim(),
      password: _password.text.trim(),
      fullName: _fullName.text.trim(),
      role: 'customer',
      avatarPath: _avatar?.path,
      extraData: {'address': _address.text.trim()},
    );

    setState(() => _loading = false);

    if (res != null && res.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Register as Customer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👤 Avatar Picker
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                child: _avatar == null
                    ? const Icon(Icons.camera_alt,
                        size: 40, color: Colors.redAccent)
                    : null,
              ),
            ),
            const SizedBox(height: 25),

            // 🧍 Full Name
            _buildTextField(
              controller: _fullName,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // 📍 Address
            _buildTextField(
              controller: _address,
              label: 'Address',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),

            // 📧 Email
            _buildTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // 🔒 Password
            _buildTextField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 30),

            // 🚀 Register button
            _loading
                ? const CircularProgressIndicator(color: Colors.redAccent)
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            const SizedBox(height: 25),

            // 🔁 Login Redirect
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                'Already have an account? Log in',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
