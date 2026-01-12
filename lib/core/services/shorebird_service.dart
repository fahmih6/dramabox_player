import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _appVersion = '';
  String get appVersion => _appVersion;

  Future<void> init() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';

      final isShorebirdAvailable = _shorebirdCodePush.isShorebirdAvailable();
      developer.log(
        'Shorebird available: $isShorebirdAvailable (App Version: $_appVersion)',
        name: 'ShorebirdService',
      );

      if (isShorebirdAvailable) {
        final currentPatch = await _shorebirdCodePush.currentPatchNumber();
        developer.log(
          'Current patch number: ${currentPatch ?? 'none'}',
          name: 'ShorebirdService',
        );

        // Check for updates in background
        checkForUpdates();
      }
    } catch (e) {
      developer.log(
        'Error initializing Shorebird: $e',
        name: 'ShorebirdService',
      );
    }
  }

  Future<void> checkForUpdates() async {
    // Add a small delay to ensure the app is fully settled
    await Future.delayed(const Duration(seconds: 2));

    updateStatus.value = ShorebirdUpdateStatus.checking;
    try {
      final currentPatch = await _shorebirdCodePush.currentPatchNumber();
      developer.log(
        'Checking for updates. Current patch: ${currentPatch ?? 'none'}',
        name: 'ShorebirdService',
      );

      // 1. Check if a patch is already downloaded and ready to be installed
      final isReadyToInstall = await _shorebirdCodePush
          .isNewPatchReadyToInstall();
      developer.log(
        'New patch ready to install: $isReadyToInstall',
        name: 'ShorebirdService',
      );

      if (isReadyToInstall) {
        updateStatus.value = ShorebirdUpdateStatus.readyToRestart;
        return;
      }

      // 2. If no patch is ready, check if there's a new patch available for download
      final isUpdateAvailable = await _shorebirdCodePush
          .isNewPatchAvailableForDownload();
      developer.log(
        'New patch available for download: $isUpdateAvailable',
        name: 'ShorebirdService',
      );

      if (isUpdateAvailable) {
        updateStatus.value = ShorebirdUpdateStatus.downloading;
        developer.log('Downloading patch...', name: 'ShorebirdService');
        await _shorebirdCodePush.downloadUpdateIfAvailable();

        // After download, check again if it's ready
        final isNowReady = await _shorebirdCodePush.isNewPatchReadyToInstall();
        if (isNowReady) {
          updateStatus.value = ShorebirdUpdateStatus.readyToRestart;
          developer.log(
            'Patch downloaded and ready. It will be applied on next restart.',
            name: 'ShorebirdService',
          );
        } else {
          // If for some reason it's not ready after download, set to idle or error
          updateStatus.value = ShorebirdUpdateStatus.idle;
          developer.log(
            'Patch downloaded but not reported as ready to install.',
            name: 'ShorebirdService',
          );
        }
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
