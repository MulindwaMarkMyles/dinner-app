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
  final Map<Drink, int> _selectedItems = {};
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
    if (_selectedItems.isEmpty || _servingPointController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one drink and enter serving point'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.consumeDrink(
        firstName: widget.scannedUser.firstName,
        lastName: widget.scannedUser.lastName,
        gender: widget.scannedUser.safeGender,
        servingPoint: _servingPointController.text.trim(),
        items: _selectedItems.entries
            .map(
              (entry) => {
                'drink_name': entry.key.name,
                'quantity': entry.value,
              },
            )
            .toList(),
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
        title: Text(
          'DRINKS SERVICE',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MyApp.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECIPIENT',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: MyApp.primaryBlue.withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.scannedUser.firstName} ${widget.scannedUser.lastName}'
                      .toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w200,
                    color: MyApp.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _servingPointController,
            cursorColor: MyApp.primaryBlue,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'SERVING POINT',
              labelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.grey.shade500,
              ),
              hintText: 'e.g. BAR A',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: MyApp.primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'SELECT DRINK',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _drinks.map((drink) {
              final isSelected = _selectedDrink == drink;
              return InkWell(
                onTap: () => setState(() => _selectedDrink = drink),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? MyApp.primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? MyApp.primaryBlue
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: MyApp.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        drink.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${drink.availableQuantity} left',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          Text(
            'QUANTITY',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildQtyButton(Icons.remove_rounded, () {
                if (_quantity > 1) setState(() => _quantity--);
              }),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildQtyButton(
                Icons.add_rounded,
                () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionButton('ADD ITEM', _addSelectedItem),
          const SizedBox(height: 20),
          if (_selectedItems.isNotEmpty) _buildSelectedItemsSection(),
          const SizedBox(height: 64),
          _buildActionButton('SUBMIT ORDER', _consumeDrink),
        ],
      ),
    );
  }

  void _addSelectedItem() {
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a drink first')),
      );
      return;
    }

    setState(() {
      final existing = _selectedItems[_selectedDrink!] ?? 0;
      _selectedItems[_selectedDrink!] = existing + _quantity;
      _quantity = 1;
    });
  }

  Widget _buildSelectedItemsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER ITEMS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ..._selectedItems.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.value} × ${entry.key.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedItems.remove(entry.key));
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 24, color: MyApp.primaryBlue),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ACCESS DENIED',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            _buildActionButton(
              'TRY AGAIN',
              () => Navigator.pop(context),
              isError: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'DRINK SERVED',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.0,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.scannedUser.fullName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                  color: MyApp.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _selectedItems.entries
                    .map((entry) => '${entry.value}×${entry.key.name}')
                    .join(' • ')
                    .toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildAllowanceSection(),
            const SizedBox(height: 60),
            _buildActionButton('DONE', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllowanceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            'REMAINING ALLOWANCE',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAllowanceItem(
                'LUNCH',
                _user!.lunchesRemaining,
                Colors.orange,
              ),
              _buildAllowanceItem(
                'DINNER',
                _user!.dinnersRemaining,
                Colors.green,
              ),
              _buildAllowanceItem(
                'DRINKS',
                _user!.drinksRemaining,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceItem(String label, int count, MaterialColor color) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onPressed, {
    bool isError = false,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (isError ? Colors.red : MyApp.primaryBlue).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isError ? Colors.red : MyApp.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
