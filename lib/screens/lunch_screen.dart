import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../main.dart';

class LunchScreen extends StatefulWidget {
  final ScannedUser scannedUser;

  const LunchScreen({super.key, required this.scannedUser});

  @override
  State<LunchScreen> createState() => _LunchScreenState();
}

class _LunchScreenState extends State<LunchScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  User? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _consumeLunch();
  }

  Future<void> _consumeLunch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _apiService.consumeLunch(
        firstName: widget.scannedUser.firstName,
        lastName: widget.scannedUser.lastName,
        gender: widget.scannedUser.gender,
      );
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'LUNCH',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
          : _error != null
              ? _buildError()
              : _buildSuccess(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, size: 48, color: Colors.black),
            const SizedBox(height: 24),
            Text(
              'ERROR',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              _error!.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 48),
            _buildActionButton('GO BACK', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check, size: 64, color: Colors.black),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'CONSUMPTION CONFIRMED',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.5),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _user!.fullName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w300),
              ),
            ),
            const SizedBox(height: 60),
            _buildAllowanceSection(),
            const SizedBox(height: 60),
            _buildActionButton('DONE', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllowanceSection() {
    return Column(
      children: [
        const Divider(color: Colors.black, thickness: 1),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAllowanceItem('LUNCH', _user!.lunchesRemaining),
            _buildAllowanceItem('DINNER', _user!.dinnersRemaining),
            _buildAllowanceItem('DRINKS', _user!.drinksRemaining),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.black, thickness: 1),
      ],
    );
  }

  Widget _buildAllowanceItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.0),
        ),
      ),
    );
  }
}
