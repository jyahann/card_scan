import 'dart:async';

import 'package:card_scan/card_scan_platform_interface.dart';
import 'package:card_scan/types/events.dart';

final class GoogleCardScanner {
  static Future<CardScanEvent> scan({bool testEnvironment = false}) async {
    CardScanPlatform.instance.initCallHandler();
    CardScanPlatform.instance.startGoogleScanner(testEnvironment);
    return CardScanPlatform.instance.events.first;
  }
}
