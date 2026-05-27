import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/auth/auth_service.dart';
import '../main_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final AuthService authService;

  const PinSetupScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();

    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += digit);
        if (_confirmPin.length == 4) {
          _validateAndSave();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() => _pin += digit);
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() => _isConfirming = true);
          });
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _validateAndSave() async {
    if (_pin != _confirmPin) {
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    // Save PIN via AuthService
    await widget.authService.setPin(_pin);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainScreen(authService: widget.authService),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

            // Splash icon / Logo with Lock fallback
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/icon/splash_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Create a 4-digit PIN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _isConfirming
                  ? 'Re-enter your PIN to confirm'
                  : 'This PIN will protect your financial data',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final dx = _hasError
                    ? (1 - _shakeAnimation.value) *
                        10 *
                        (_shakeController.value < 0.5 ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: filled ? 18 : 16,
                    height: filled ? 18 : 16,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? Colors.red.shade400
                          : filled
                              ? Colors.green.shade400
                              : Colors.transparent,
                      border: Border.all(
                        color: _hasError
                            ? Colors.red.shade400
                            : filled
                                ? Colors.green.shade400
                                : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: filled && !_hasError
                          ? [
                              BoxShadow(
                                color: Colors.green.shade400.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(flex: 1),

            // Number pad
            _buildNumberPad(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumberRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumberRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildNumberRow(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        if (digit.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }

        if (digit == '⌫') {
          return GestureDetector(
            onTap: _onBackspace,
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              child: Icon(
                Icons.backspace_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _onDigitPressed(digit),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              digit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
