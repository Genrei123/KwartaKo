import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:local_auth/local_auth.dart';
import '../../infrastructure/repositories/app_repository.dart';
import '../../infrastructure/models/db_models.dart';

class AuthService {
  final AppRepository _repository;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService({required AppRepository repository}) : _repository = repository;

  AppRepository get appRepository => _repository;

  // ---------------------------------------------------------------------------
  // Account existence check
  // ---------------------------------------------------------------------------
  Future<bool> hasAccount() async {
    final profile = await _repository.getUserProfile();
    return profile != null;
  }

  // ---------------------------------------------------------------------------
  // Account creation
  // ---------------------------------------------------------------------------
  Future<void> createAccount({
    required String displayName,
    required double monthlyIncome,
  }) async {
    final uuid = const Uuid().v4();
    
    final newProfile = DbUserProfile(
      id: uuid,
      displayName: displayName,
      monthlyIncome: monthlyIncome,
    );

    await _repository.saveUserProfile(newProfile);
    
    // Seed categories here to make absolutely sure they exist for new accounts
    await _repository.seedDefaultCategories();
  }

  // ---------------------------------------------------------------------------
  // Profile CRUD
  // ---------------------------------------------------------------------------
  Future<DbUserProfile?> getUserProfile() async {
    return await _repository.getUserProfile();
  }

  Future<void> updateUserProfile(DbUserProfile profile) async {
    await _repository.updateUserProfile(profile);
  }

  // ---------------------------------------------------------------------------
  // PIN management (SHA-256 hashed, 4-digit)
  // ---------------------------------------------------------------------------
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> setPin(String pin) async {
    final profile = await _repository.getUserProfile();
    if (profile == null) {
      throw StateError('No user profile found. Create an account first.');
    }

    final hashedPin = _hashPin(pin);
    final updated = DbUserProfile(
      id: profile.id,
      displayName: profile.displayName,
      monthlyIncome: profile.monthlyIncome,
      needsRatio: profile.needsRatio,
      wantsRatio: profile.wantsRatio,
      flexRatio: profile.flexRatio,
      emergencyRatio: profile.emergencyRatio,
      efundTarget: profile.efundTarget,
      cascadeMode: profile.cascadeMode,
      pinEnabled: 1,
      pinHash: hashedPin,
      biometricEnabled: profile.biometricEnabled,
    );

    await _repository.updateUserProfile(updated);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final profile = await _repository.getUserProfile();
    if (profile == null || profile.pinHash == null) return false;
    return _hashPin(enteredPin) == profile.pinHash;
  }

  Future<bool> isPinEnabled() async {
    final profile = await _repository.getUserProfile();
    return profile != null && profile.pinEnabled == 1;
  }

  Future<void> disablePin() async {
    final profile = await _repository.getUserProfile();
    if (profile == null) return;

    final updated = DbUserProfile(
      id: profile.id,
      displayName: profile.displayName,
      monthlyIncome: profile.monthlyIncome,
      needsRatio: profile.needsRatio,
      wantsRatio: profile.wantsRatio,
      flexRatio: profile.flexRatio,
      emergencyRatio: profile.emergencyRatio,
      efundTarget: profile.efundTarget,
      cascadeMode: profile.cascadeMode,
      pinEnabled: 0,
      pinHash: null,
      biometricEnabled: 0, // Automatically disable biometrics if backup PIN is disabled
    );

    await _repository.updateUserProfile(updated);
  }

  // ---------------------------------------------------------------------------
  // Biometric Authentication
  // ---------------------------------------------------------------------------
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canCheck = await canAuthenticateWithBiometrics();
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to unlock your KwartaKo account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
