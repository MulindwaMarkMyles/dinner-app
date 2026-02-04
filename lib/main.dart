import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'screens/lunch_screen.dart';
import 'screens/dinner_screen.dart';
import 'screens/drinks_screen.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DR - Dinner Resources',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      home: const MyHomePage(title: 'DR'),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyHomePage(title: 'DR')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'DR',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dinner Resources',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum ModuleType { lunch, dinner, drinks }

class ScannedUser {
  final String firstName;
  final String lastName;
  final String gender;
  String get fullName => '$firstName $lastName';

  const ScannedUser({
    required this.firstName,
    required this.lastName,
    required this.gender,
  });

  // Updated to handle both JSON and semicolon-separated formats
  static ScannedUser fromQrPayload(String payload) {
    // Try to parse as JSON first
    try {
      final data = json.decode(payload) as Map<String, dynamic>;

      // Extract name and split it
      final fullName = data['name'] as String? ?? '';
      final nameParts = fullName.trim().split(' ');

      String firstName = '';
      String lastName = '';

      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          // Join all remaining parts as last name
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      // Convert gender to M/F format
      final genderRaw = (data['gender'] as String? ?? '').toLowerCase();
      String gender = '';
      if (genderRaw.startsWith('m')) {
        gender = 'M';
      } else if (genderRaw.startsWith('f')) {
        gender = 'F';
      }

      return ScannedUser(
        firstName: firstName,
        lastName: lastName,
        gender: gender,
      );
    } catch (e) {
      // Fall back to semicolon-separated format
      final map = <String, String>{};
      for (final part in payload.split(';')) {
        final kv = part.split('=');
        if (kv.length == 2) map[kv[0].trim()] = kv[1].trim();
      }
      return ScannedUser(
        firstName: map['first_name'] ?? '',
        lastName: map['last_name'] ?? '',
        gender: map['gender'] ?? '',
      );
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _scanAndRoute(ModuleType module) async {
    final moduleLabel = switch (module) {
      ModuleType.lunch => 'Scan for Lunch',
      ModuleType.dinner => 'Scan for Dinner',
      ModuleType.drinks => 'Scan for Drinks',
    };

    // Open QR scanner
    final String? qrData = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(title: moduleLabel),
      ),
    );

    if (qrData == null || !mounted) return;

    print('==========================================');
    print('Raw QR Data: $qrData');
    print('==========================================');

    try {
      // Parse QR data
      final user = ScannedUser.fromQrPayload(qrData);

      print('Parsed Data:');
      print('  First Name: "${user.firstName}"');
      print('  Last Name: "${user.lastName}"');
      print('  Gender: "${user.gender}"');
      print('==========================================');

      // Navigate to appropriate module screen - backend will validate
      Widget screen = switch (module) {
        ModuleType.lunch => LunchScreen(scannedUser: user),
        ModuleType.dinner => DinnerScreen(scannedUser: user),
        ModuleType.drinks => DrinksScreen(scannedUser: user),
      };

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );
    } catch (e) {
      print('Error parsing QR: $e');
      print('==========================================');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing QR code: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
          ),
          // Top decorative element
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.03),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with gradient underline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Scan a QR code to serve meals',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'or drinks',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid of module cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _ModuleCard(
                          title: 'Lunch',
                          subtitle: 'Scan to consume',
                          icon: Icons.lunch_dining,
                          onTap: () => _scanAndRoute(ModuleType.lunch),
                        ),
                        _ModuleCard(
                          title: 'Dinner',
                          subtitle: 'Scan to consume',
                          icon: Icons.restaurant,
                          onTap: () => _scanAndRoute(ModuleType.dinner),
                        ),
                        _ModuleCard(
                          title: 'Drinks',
                          subtitle: 'Scan to serve',
                          icon: Icons.local_bar,
                          onTap: () => _scanAndRoute(ModuleType.drinks),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) => setState(() => _isHovered = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
