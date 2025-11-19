import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ Import your screens
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/register_customer_screen.dart';
import 'screens/auth/register_company_screen.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // ✅ Run app
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.notoSansTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      title: 'BorlaMaster',
      debugShowCheckedModeBanner: false,

      // ✅ Unified Dark Green Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.greenAccent.shade400,
          secondary: Colors.green.shade600,
          surface: const Color(0xFF121212),
          background: const Color(0xFF0E0E0E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: baseTextTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          titleTextStyle: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),

      // ✅ Define Navigation Routes
      initialRoute: '/role_selection',
      routes: {
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/register_customer': (context) => const RegisterCustomerScreen(),
        '/register_company': (context) => const RegisterCompanyScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
