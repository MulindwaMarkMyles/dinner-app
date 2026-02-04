import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/drink_model.dart';
import '../services/api_service.dart';
import '../main.dart';

class DrinksScreen extends StatefulWidget {
  final ScannedUser scannedUser;

  const DrinksScreen({super.key, required this.scannedUser});

  @override
  State<DrinksScreen> createState() => _DrinksScreenState();
}

class _DrinksScreenState extends State<DrinksScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _servingPointController = TextEditingController();
  
  bool _isLoading = true;
  List<Drink> _drinks = [];
  Drink? _selectedDrink;
  int _quantity = 1;
  User? _user;
  String? _error;
  bool _isDrinkConsumed = false;

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    try {
      final drinks = await _apiService.getAvailableDrinks();
      setState(() {
        _drinks = drinks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load drinks';
        _isLoading = false;
      });
    }
  }

  Future<void> _consumeDrink() async {
    if (_selectedDrink == null || _servingPointController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a drink and enter serving point')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.consumeDrink(
        firstName: widget.scannedUser.firstName,
        lastName: widget.scannedUser.lastName,
        gender: widget.scannedUser.gender,
        servingPoint: _servingPointController.text.trim(),
        drinkName: _selectedDrink!.name,
        quantity: _quantity,
      );
      
      setState(() {
        _user = result['user'];
        _isDrinkConsumed = true;
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
          'DRINKS',
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
              : _isDrinkConsumed
                  ? _buildSuccess()
                  : _buildDrinkSelection(),
    );
  }

  Widget _buildDrinkSelection() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RECIPIENT',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.scannedUser.firstName} ${widget.scannedUser.lastName}'.toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _servingPointController,
            cursorColor: Colors.black,
            decoration: InputDecoration(
              labelText: 'SERVING POINT',
              labelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.black),
              hintText: 'E.G. BAR A',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'SELECT DRINK',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          ..._drinks.map((drink) {
            final isSelected = _selectedDrink == drink;
            return InkWell(
              onTap: () => setState(() => _selectedDrink = drink),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.black : Colors.transparent,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        drink.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      '${drink.availableQuantity} left',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 40),
          Text(
            'QUANTITY',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQtyButton(Icons.remove, () {
                if (_quantity > 1) setState(() => _quantity--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_quantity', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600)),
              ),
              _buildQtyButton(Icons.add, () => setState(() => _quantity++)),
            ],
          ),
          const SizedBox(height: 60),
          _buildActionButton('SERVE DRINK', _consumeDrink),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
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
                'DRINK SERVED',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.5),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.scannedUser.fullName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w300),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$_quantity × ${_selectedDrink!.name}'.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, letterSpacing: 1.0),
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
