import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'dart:developer' as developer;

enum ShorebirdUpdateStatus {
  idle,
  checking,
  downloading,
  readyToRestart,
  error,
}

class ShorebirdService {
  final _shorebirdCodePush = ShorebirdCodePush();
  final updateStatus = ValueNotifier<ShorebirdUpdateStatus>(
    ShorebirdUpdateStatus.idle,
  );

  Future<void> init() async {
    try {
      final isShorebirdAvailable = _shorebirdCodePush.isShorebirdAvailable();
      developer.log(
        'Shorebird available: $isShorebirdAvailable',
        name: 'ShorebirdService',
      );

      if (isShorebirdAvailable) {
        final currentPatch = await _shorebirdCodePush.currentPatchNumber();
        developer.log(
          'Current patch number: ${currentPatch ?? 'none'}',
          name: 'ShorebirdService',
        );

        // Check for updates in background
        _checkForUpdates();
      }
    } catch (e) {
      developer.log(
        'Error initializing Shorebird: $e',
        name: 'ShorebirdService',
      );
    }
  }

  Future<void> _checkForUpdates() async {
    updateStatus.value = ShorebirdUpdateStatus.checking;
    try {
      final isUpdateAvailable = await _shorebirdCodePush
          .isNewPatchAvailableForDownload();
      developer.log(
        'New patch available: $isUpdateAvailable',
        name: 'ShorebirdService',
      );

      if (isUpdateAvailable) {
        updateStatus.value = ShorebirdUpdateStatus.downloading;
        developer.log('Downloading patch...', name: 'ShorebirdService');
        await _shorebirdCodePush.downloadUpdateIfAvailable();
        updateStatus.value = ShorebirdUpdateStatus.readyToRestart;
        developer.log(
          'Patch downloaded successfully. It will be applied on next restart.',
          name: 'ShorebirdService',
        );
      } else {
        updateStatus.value = ShorebirdUpdateStatus.idle;
      }
    } catch (e) {
      updateStatus.value = ShorebirdUpdateStatus.error;
      developer.log(
        'Error checking for Shorebird updates: $e',
        name: 'ShorebirdService',
      );
    }
  }

  Future<int?> getCurrentPatchNumber() async {
    if (!_shorebirdCodePush.isShorebirdAvailable()) return null;
    return await _shorebirdCodePush.currentPatchNumber();
  }
}
