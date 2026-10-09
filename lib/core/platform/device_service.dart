import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ─────────────────────────────────────────────────────────────────
///  Platform Channel Service (Week 8 — Part 7)
///  Native Interop with Android (Kotlin) & iOS (Swift)
///  Channel Name: 'vn.edu.vku/device_info'
/// ─────────────────────────────────────────────────────────────────
class DevicePlatformService {
  DevicePlatformService._();
  static final DevicePlatformService instance = DevicePlatformService._();

  static const MethodChannel _channel = MethodChannel('vn.edu.vku/device_info');

  /// Fetches battery percentage from native OS via MethodChannel
  Future<int> getBatteryLevel() async {
    // If not mobile platform, return a mocked realistic value to avoid unhandled errors
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      return 100;
    }

    try {
      final dynamic result = await _channel.invokeMethod('getBatteryLevel');
      if (result is int) {
        return result;
      }
      return -1;
    } on PlatformException catch (e) {
      debugPrint('MethodChannel error getBatteryLevel: ${e.message}');
      return -1;
    } catch (e) {
      debugPrint('Unexpected error getBatteryLevel: $e');
      return -1;
    }
  }

  /// Fetches native platform OS descriptor
  Future<String> getDevicePlatformName() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android (Kotlin MethodChannel)';
    if (Platform.isIOS) return 'iOS (Swift MethodChannel)';
    if (Platform.isWindows) return 'Windows Desktop';
    return 'Native Host';
  }
}

/// Riverpod FutureProvider to expose the device battery level reactively
final batteryLevelProvider = FutureProvider<int>((ref) async {
  return DevicePlatformService.instance.getBatteryLevel();
});
