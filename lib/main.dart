import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'screens/lunch_screen.dart';
import 'screens/dinner_screen.dart';
import 'screens/drinks_screen.dart';
import 'screens/bbq_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryBlue = Color(0xFF384D9A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DR - Dinner Resources',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryBlue),
          titleTextStyle: TextStyle(
            color: primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          ),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      _navigateFromSplash();
    });
  }

  Future<void> _navigateFromSplash() async {
    await ApiService.initializeAuth();
    if (!mounted) return;

    final Widget destination = ApiService.isLoggedIn
        ? const MyHomePage(title: 'DR')
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.primaryBlue,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      // decoration: BoxDecoration(
                      //   color: Colors.white,
                      //   shape: BoxShape.circle,
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: Colors.black.withOpacity(0.2),
                      //       blurRadius: 30,
                      //       offset: const Offset(0, 10),
                      //     ),
                      //   ],
                      // ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo_big_.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.restaurant_rounded,
                                size: 70,
                                color: MyApp.primaryBlue,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '101 Rotary Discon',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'CONFERENCE',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

enum ModuleType { lunch, dinner, bbq, drinks }

class ScannedUser {
  final String firstName;
  final String lastName;
  final String gender;
  String get fullName => '$firstName $lastName';
  String get safeGender => gender.isEmpty ? 'UNKNOWN' : gender;

  static const Map<String, String> genderMap = {'FEMALE': 'F', 'MALE': 'M'};

  static const Map<String, String> _shortToFullGender = {
    'F': 'FEMALE',
    'M': 'MALE',
  };

  String get shortGender => genderMap[gender] ?? gender;

  const ScannedUser({
    required this.firstName,
    required this.lastName,
    required this.gender,
  });

  static String _normalizeGender(String? rawGender) {
    final normalized = rawGender?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return '';
    if (genderMap.containsKey(normalized)) return normalized;
    return _shortToFullGender[normalized] ?? '';
  }

  static ScannedUser _fromVCard(String payload) {
    final lines = payload.split(RegExp(r'\r?\n'));
    String fn = '';
    String n = '';
    String rawGender = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toUpperCase().startsWith('FN:')) {
        fn = trimmed.substring(3).trim();
      } else if (trimmed.toUpperCase().startsWith('N:')) {
        n = trimmed.substring(2).trim();
      } else if (trimmed.toUpperCase().startsWith('GENDER:')) {
        rawGender = trimmed.substring(7).trim();
      }
    }

    String fullName = fn;
    if (fullName.isEmpty && n.isNotEmpty) {
      final parts = n.split(';');
      final last = parts.isNotEmpty ? parts[0].trim() : '';
      final first = parts.length > 1 ? parts[1].trim() : '';
      fullName = [first, last].where((p) => p.isNotEmpty).join(' ');
    }

    final nameParts = fullName.trim().split(' ');
    String firstName = '';
    String lastName = '';
    if (nameParts.isNotEmpty) {
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    }

    return ScannedUser(
      firstName: firstName,
      lastName: lastName,
      gender: _normalizeGender(rawGender),
    );
  }

  // Updated to handle both JSON and semicolon-separated formats
  static ScannedUser fromQrPayload(String payload) {
    final trimmed = payload.trim();
    if (trimmed.toUpperCase().contains('BEGIN:VCARD')) {
      return _fromVCard(trimmed);
    }

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

      final gender = _normalizeGender(data['gender'] as String?);

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
      final gender = _normalizeGender(map['gender']);

      return ScannedUser(
        firstName: map['first_name'] ?? '',
        lastName: map['last_name'] ?? '',
        gender: gender,
      );
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _scanAndRoute(ModuleType module) async {
    final moduleLabel = switch (module) {
      ModuleType.lunch => 'Scan for Lunch',
      ModuleType.dinner => 'Scan for Dinner',
      ModuleType.bbq => 'Scan for BBQ',
      ModuleType.drinks => 'Scan for Drinks',
    };

    // Open QR scanner
    final String? qrData = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => QrScannerScreen(title: moduleLabel)),
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
        ModuleType.bbq => BbqScreen(scannedUser: user),
        ModuleType.drinks => DrinksScreen(scannedUser: user),
      };

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: MyApp.primaryBlue,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _logout,
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MyApp.primaryBlue, Color(0xFF4A64C2)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // LOGO PLACEHOLDER
                            // Container(
                            //   height: 80,
                            //   width: double.infinity,
                            //   decoration: BoxDecoration(
                            //     color: Colors.white.withOpacity(0.15),
                            //     borderRadius: BorderRadius.circular(16),
                            //     border: Border.all(
                            //       color: Colors.white.withOpacity(0.2),
                            //     ),
                            //   ),
                            //   child: Center(
                            //     child: Column(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         const Icon(
                            //           Icons.image_outlined,
                            //           color: Colors.white54,
                            //         ),
                            //         const SizedBox(height: 4),
                            //         Text(
                            //           'LOGO PLACEHOLDER',
                            //           style: GoogleFonts.poppins(
                            //             color: Colors.white70,
                            //             fontSize: 10,
                            //             fontWeight: FontWeight.bold,
                            //             letterSpacing: 2,
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/logo_big_.png',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '101 Rotary Discon Conference',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'AI Digital Coupon System',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _ModuleCard(
                  title: 'Lunch',
                  subtitle: 'Scan for Lunch',
                  icon: Icons.lunch_dining_rounded,
                  accentColor: const Color(0xFFFFB74D),
                  onTap: () => _scanAndRoute(ModuleType.lunch),
                ),
                _ModuleCard(
                  title: 'Dinner',
                  subtitle: 'Scan for Dinner',
                  icon: Icons.restaurant_rounded,
                  accentColor: const Color(0xFF81C784),
                  onTap: () => _scanAndRoute(ModuleType.dinner),
                ),
                _ModuleCard(
                  title: 'Drinks',
                  subtitle: 'Scan for Drinks',
                  icon: Icons.local_bar_rounded,
                  accentColor: const Color(0xFF64B5F6),
                  onTap: () => _scanAndRoute(ModuleType.drinks),
                ),
                _ModuleCard(
                  title: 'BBQ',
                  subtitle: 'Scan for BBQ',
                  icon: Icons.outdoor_grill_rounded,
                  accentColor: const Color(0xFFE57373),
                  onTap: () => _scanAndRoute(ModuleType.bbq),
                ),
                _ModuleCard(
                  title: 'AI Chatbot',
                  subtitle: 'Ask the assistant',
                  icon: Icons.support_agent_rounded,
                  accentColor: const Color(0xFF9575CD),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
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
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
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
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.05),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 32, color: widget.accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MyApp.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
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
    );
  }
}
