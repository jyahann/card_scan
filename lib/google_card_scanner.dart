import 'dart:async';

import 'package:card_scan/card_scan_platform_interface.dart';
import 'package:card_scan/types/events.dart';

final class GoogleCardScanner {
  static Future<CardScanEvent> scan() async {
    return CardScanPlatform.instance.events.first;
  }
}
