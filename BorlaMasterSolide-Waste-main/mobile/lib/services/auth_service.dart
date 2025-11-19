import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';

final supabase = Supabase.instance.client;

class AuthService {
  // ================================================================
  // ✅ EMAIL/PASSWORD SIGN-UP (Profiles + Companies + Customers)
  // ================================================================
  static Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'customer' or 'company'
    String? companyType,
    String? avatarPath,
    Map<String, dynamic>? extraData,
  }) async {
    print("🟢 AUTH DEBUG: Starting sign-up for $email");

    // 1️⃣ Create Auth User
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) {
      print("❌ AUTH ERROR: signUp returned null user.");
      return null;
    }
    print("🟢 AUTH DEBUG: User created => ${user.id}");

    // ✅ Check email confirmation status
    if (user.emailConfirmedAt == null) {
      print("🟡 Email not confirmed yet. Confirmation email should have been sent by Supabase.");
      // Optional: Uncomment to force resend email
      // await supabase.auth.api.resendConfirmationEmail(email);
      // print("🟡 Confirmation email resent to $email");
    } else {
      print("🟢 Email already confirmed at ${user.emailConfirmedAt}");
    }

    // 2️⃣ Upload avatar/logo if provided
    String? uploadedLogoUrl;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        uploadedLogoUrl =
            await StorageService.uploadAvatar(user.id, File(avatarPath));
        print("🟢 Avatar uploaded: $uploadedLogoUrl");
      } catch (e) {
        print("❌ Avatar upload failed: $e");
      }
    }

    // 3️⃣ Insert into PROFILES table
    final profileData = {
      'id': user.id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'avatar_url': uploadedLogoUrl,
    };
    try {
      await supabase.from('profiles').insert(profileData);
      print("🟢 Profile inserted successfully");
    } catch (e) {
      print("❌ PROFILE INSERT ERROR: $e");
      rethrow;
    }

    // 4️⃣ Insert into CUSTOMERS table if role == 'customer'
    if (role == 'customer') {
      print("🟡 Preparing customer insert…");

      final customerData = {
        'auth_user_id': user.id,
        'full_name': fullName,
        'email': email,
        'avatar_url': uploadedLogoUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        final insertedCustomer =
            await supabase.from('customers').insert(customerData).select();
        print("🟢 CUSTOMER INSERT SUCCESS: $insertedCustomer");
      } catch (e) {
        print("❌ CUSTOMER INSERT ERROR: $e");
        rethrow;
      }
    }

    // 5️⃣ Insert into COMPANIES table if role == 'company'
    if (role == 'company') {
      print("🟡 Preparing company insert…");

      List<String> regionsServed = extraData?['regions_served'] is List
          ? List<String>.from(extraData!['regions_served'])
          : [];
      List<String> townsServed = extraData?['towns_served'] is List
          ? List<String>.from(extraData!['towns_served'])
          : [];

      final companyData = {
        'auth_user_id': user.id,
        'company_name': fullName,
        'company_type': extraData?['company_type'] ?? companyType,
        'regions_served': regionsServed,
        'towns_served': townsServed,
        'address': extraData?['address'] ?? '',
        'avatar_url': uploadedLogoUrl,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        final insertedCompany =
            await supabase.from('companies').insert(companyData).select();
        print("🟢 COMPANY INSERT SUCCESS: $insertedCompany");
      } catch (e) {
        print("❌ COMPANY INSERT ERROR: $e");
        rethrow;
      }
    }

    print("🎉 SIGN-UP COMPLETE: All data inserted.");
    return res;
  }

  // ================================================================
  // ✅ EMAIL/PASSWORD SIGN-IN
  // ================================================================
  static Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Optional: Check if email is confirmed on sign-in
    if (res.user?.emailConfirmedAt == null) {
      print("🟡 Warning: User email not confirmed yet. Cannot fully login until confirmed.");
    }

    return res;
  }

  // ================================================================
  // ✅ FETCH USER PROFILE
  // ================================================================
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final res =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();

    return res == null || res.isEmpty ? null : Map<String, dynamic>.from(res);
  }

  // ================================================================
  // ✅ GOOGLE SIGN-IN
  // ================================================================
  static Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  // ================================================================
  // ✅ LOGOUT
  // ================================================================
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}  