import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/auth/auth_service.dart';
import '../main_screen.dart';

enum AuthMode { biometric, pin }

class PinEntryScreen extends StatefulWidget {
  final AuthService authService;

  const PinEntryScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _hasError = false;
  String _errorMessage = '';
  int _attempts = 0;
  bool _biometricEnabled = false;
  AuthMode _currentMode = AuthMode.pin;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final profile = await widget.authService.getUserProfile();
    if (profile != null && profile.biometricEnabled == 1) {
      setState(() {
        _biometricEnabled = true;
        _currentMode = AuthMode.biometric;
      });
      // Delay the biometric prompt until the screen is fully visible.
      // Firing it during initState causes the Android Activity to not yet be
      // in the foreground, which makes the biometric dialog silently fail.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _currentMode == AuthMode.biometric) {
            _promptBiometric();
          }
        });
      });
    }
  }

  Future<void> _promptBiometric() async {
    try {
      final success = await widget.authService.authenticateWithBiometrics();
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainScreen(authService: widget.authService),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
    }
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

    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    final isValid = await widget.authService.verifyPin(_pin);

    if (isValid) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainScreen(authService: widget.authService),
          ),
          (route) => false,
        );
      }
    } else {
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      _attempts++;
      setState(() {
        _hasError = true;
        _errorMessage = _attempts >= 3
            ? 'Incorrect PIN. $_attempts failed attempts.'
            : 'Incorrect PIN. Please try again.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: SafeArea(
        child: _currentMode == AuthMode.biometric
            ? _buildBiometricView()
            : _buildPinView(),
      ),
    );
  }

  Widget _buildBiometricView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Premium pulsing fingerprint icon
        GestureDetector(
          onTap: _promptBiometric,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade400.withOpacity(0.08),
              border: Border.all(
                color: Colors.green.shade400.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade400.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: Colors.green.shade400,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Biometrics Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm your identity to unlock KwartaKo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        const Spacer(flex: 2),
        // Text button to enter PIN instead
        TextButton.icon(
          onPressed: () {
            setState(() {
              _currentMode = AuthMode.pin;
            });
          },
          icon: const Icon(Icons.pin_rounded, color: Colors.white60, size: 18),
          label: const Text(
            'Use PIN Code instead',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildPinView() {
    return Column(
      children: [
        const Spacer(flex: 2),

        // Splash icon / Logo with Lock fallback
        Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade400.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(45),
            child: Image.asset(
              'assets/icon/splash_icon_padded.png',
              fit: BoxFit.contain,
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
                    Icons.lock_rounded,
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
        const Text(
          'Welcome back',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Enter your 4-digit PIN to continue',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 40),

        // PIN dots
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final progress = _shakeController.value;
            final dx = _hasError
                ? 12 *
                    (progress < 0.25
                        ? progress * 4
                        : progress < 0.5
                            ? (0.5 - progress) * 4
                            : progress < 0.75
                                ? -(progress - 0.5) * 4
                                : -(1.0 - progress) * 4)
                : 0.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final filled = index < _pin.length;
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
          if (_biometricEnabled) {
            return GestureDetector(
              onTap: _promptBiometric,
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade400.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.green.shade400.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.green.shade400,
                  size: 32,
                ),
              ),
            );
          }
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
