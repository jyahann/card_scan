import 'package:card_scan/types/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'card_scan_platform_interface.dart';

/// An implementation of [CardScanPlatform] that uses method channels.
class MethodChannelCardScan extends CardScanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('jyahann:card_scan_channel');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  void initCallHandler() {
    methodChannel.setMethodCallHandler((call) async {
      final event = CardScanEvent.fromMap(call.arguments);
      if (event is CardScanEventScanDataReceived) {
        print(
          "Scan Data Received: ${event.number} ${event.expDate} ${event.holder}",
        );
      }
    });
  }
}
