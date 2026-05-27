import 'package:flutter/material.dart';
import '../../features/auth/auth_service.dart';
import 'pin_setup_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  final AuthService authService;

  const CreateAccountScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  bool _isCreating = false;

  Future<void> _handleCreateAccount() async {
    final name = _nameController.text.trim();
    final income = double.tryParse(_incomeController.text.trim()) ?? 0.0;

    if (name.isEmpty || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and income.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    await widget.authService.createAccount(
      displayName: name,
      monthlyIncome: income,
    );

    if (mounted) {
      // Navigate to mandatory PIN setup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(authService: widget.authService),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Welcome icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade400.withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Welcome to KwartaKo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Set up your profile to get started',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              // Display Name field
              _buildInputField(
                controller: _nameController,
                label: 'Display Name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 16),

              // Monthly Income field
              _buildInputField(
                controller: _incomeController,
                label: 'Monthly Income (₱)',
                icon: Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // Create button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _handleCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Account & Set PIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.green.shade400, size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
