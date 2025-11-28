import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../dashboard/customer_dashboard.dart';
import '../dashboard/company_dashboard.dart';
import '../admin/admin_dashboard.dart'; // create this page

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Sign in with Supabase
      final res = await AuthService.signInWithEmail(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      if (res != null && res.user != null) {
        final userId = res.user!.id;

        // Fetch profile (customer, company, or admin)
        final profile = await AuthService.getUserProfile(userId);

        if (profile == null) {
          setState(() => _error = 'Failed to fetch profile.');
          return;
        }

        final role = profile['role'];

        // Navigate based on role
        if (role == 'customer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerDashboard()),
          );
        } else if (role == 'company') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompanyDashboard()),
          );
        } else if (role == 'owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          setState(() => _error = 'Unknown role. Contact support.');
        }
      } else {
        setState(() => _error = 'Invalid credentials or login failed.');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    await AuthService.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Column(
                children: [
                  Image.asset('assets/logo.png', height: 90),
                  const SizedBox(height: 10),
                  const Text(
                    'BORLA MASTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your Garbages Only',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Email
              TextField(
                controller: _email,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Colors.redAccent),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _pass,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.redAccent),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),

              const SizedBox(height: 24),

              // Login button
              _loading
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

              const SizedBox(height: 16),

              // Forgot Password
              TextButton(
                onPressed: () {
                  // Add reset password flow if needed
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 10),

              // Google Login
              TextButton.icon(
                onPressed: _googleLogin,
                icon: const Icon(Icons.login, color: Colors.white70),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/role_selection');
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
