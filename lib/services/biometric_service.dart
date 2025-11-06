/**
 * File: biometric_service.dart
 * Lokasi: lib/services/biometric_service.dart
 * Deskripsi: Service untuk autentikasi biometrik (Fingerprint/Face ID)
 */

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BiometricService {
  // Singleton pattern
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Cek apakah device support biometrik
  Future<bool> isDeviceSupported() async {
    try {
      final bool canAuthenticate = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      print('[BiometricService] Can check biometrics: $canAuthenticate');
      print('[BiometricService] Device supported: $isDeviceSupported');
      
      return canAuthenticate || isDeviceSupported;
    } on PlatformException catch (e) {
      print('[BiometricService] Error checking device support: $e');
      return false;
    }
  }

  /// Cek biometrik yang tersedia di device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = 
          await _auth.getAvailableBiometrics();
      
      print('[BiometricService] Available biometrics: $availableBiometrics');
      return availableBiometrics;
    } on PlatformException catch (e) {
      print('[BiometricService] Error getting biometrics: $e');
      return [];
    }
  }

  /// Cek apakah biometrik diaktifkan oleh user di settings
  static Future<bool> isEnabled() async {
    try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail');
      
      print('[BiometricService] Checking enabled for user: $currentUserEmail');
      
      if (currentUserEmail != null) {
        final userData = userBox.get(currentUserEmail) as Map?;
        if (userData != null) {
          final enabled = userData['biometricEnabled'] ?? false;
          print('[BiometricService] Biometric enabled: $enabled');
          return enabled;
        }
      }
      print('[BiometricService] No user logged in or no data');
      return false;
    } catch (e) {
      print('[BiometricService] Error checking enabled status: $e');
      return false;
    }
  }

  /// Set biometrik enabled/disabled untuk user
  static Future<void> setEnabled(bool enabled) async {
    try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail');
      
      if (currentUserEmail != null) {
        final userData = Map<dynamic, dynamic>.from(
          userBox.get(currentUserEmail) ?? {}
        );
        userData['biometricEnabled'] = enabled;
        await userBox.put(currentUserEmail, userData);
        
        print('[BiometricService] Biometric ${enabled ? "enabled" : "disabled"} for $currentUserEmail');
      }
    } catch (e) {
      print('[BiometricService] Error setting enabled status: $e');
      throw Exception('Gagal menyimpan pengaturan biometrik');
    }
  }

  /// Autentikasi biometrik
  static Future<bool> authenticate({
    required String reason,
    bool allowSkip = false,
  }) async {
    try {
      final auth = LocalAuthentication();
      
      print('[BiometricService] Starting authentication...');
      print('[BiometricService] Reason: $reason');
      print('[BiometricService] Allow skip: $allowSkip');
      
      // Cek device support
      final bool canAuthenticate = await auth.canCheckBiometrics || 
                                   await auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        print('[BiometricService] Device tidak support biometrik');
        return allowSkip; // Jika allow skip, return true
      }

      // Cek apakah ada biometrik terdaftar
      final biometrics = await auth.getAvailableBiometrics();
      print('[BiometricService] Available biometrics: $biometrics');
      
      if (biometrics.isEmpty) {
        print('[BiometricService] No biometrics enrolled');
        return allowSkip;
      }

      // Lakukan autentikasi
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      print('[BiometricService] Authentication result: $didAuthenticate');
      return didAuthenticate;

    } on PlatformException catch (e) {
      print('[BiometricService] Authentication error: ${e.code} - ${e.message}');
      
      // Handle specific errors
      if (e.code == 'NotAvailable') {
        print('[BiometricService] Biometric not available');
      } else if (e.code == 'NotEnrolled') {
        print('[BiometricService] No biometric enrolled');
      } else if (e.code == 'LockedOut') {
        print('[BiometricService] Too many attempts, locked out');
      } else if (e.code == 'PermanentlyLockedOut') {
        print('[BiometricService] Permanently locked out');
      }
      
      return allowSkip;
      
    } catch (e) {
      print('[BiometricService] Unexpected error: $e');
      return allowSkip;
    }
  }

  /// Get nama biometrik yang tersedia
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.isEmpty) {
      return 'Biometrik';
    }
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Sidik Jari';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometrik';
    }
  }

  /// Cek apakah user sudah setup biometrik di device
  Future<bool> isBiometricEnrolled() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      print('[BiometricService] Error checking enrollment: $e');
      return false;
    }
  }
}