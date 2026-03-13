import 'package:flutter/material.dart';

class BiometricService {
  /// Mocks a biometric authentication check.
  /// In a real app, this would use `local_auth`.
  Future<bool> authenticate(BuildContext context, {String reason = 'Confirm transaction'}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text('Biometric Auth'),
              ],
            ),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

final biometricService = BiometricService();
