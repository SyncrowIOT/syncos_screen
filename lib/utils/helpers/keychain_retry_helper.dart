import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:syncos_screen/secure_storage.dart';

class KeychainRetryHelper {
  static Future<T> retryKeychainOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    var attempt = 0;
    var delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } on PlatformException catch (e) {
        attempt++;
        log('Keychain operation failed (attempt $attempt/$maxRetries): $e');

        if (attempt >= maxRetries) {
          if (e.code == '-25299' ||
              (e.message?.contains('already exists') ?? false)) {
            rethrow;
          }
          rethrow;
        }

        await Future<void>.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }

    throw Exception('Keychain operation failed after $maxRetries attempts');
  }

  static Future<void> retryKeychainWrites(
    Map<String, String> keyValuePairs, {
    int maxRetries = 3,
  }) async {
    await retryKeychainOperation(
      () async {
        await Future.wait(
          keyValuePairs.entries.map(
            (entry) => flutterSecureStorage.write(
              key: entry.key,
              value: entry.value,
            ),
          ),
        );
      },
      maxRetries: maxRetries,
    );
  }

  static Future<void> retryKeychainDeletes(
    List<String> keys, {
    int maxRetries = 3,
  }) async {
    await retryKeychainOperation(
      () async {
        await Future.wait(
          keys.map((key) => flutterSecureStorage.delete(key: key)),
        );
      },
      maxRetries: maxRetries,
    );
  }
}
