import 'dart:async';

import 'package:card_scan/types/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'card_scan_platform_interface.dart';

/// An implementation of [CardScanPlatform] that uses method channels.
class MethodChannelCardScan extends CardScanPlatform {
  /// The method channel used to interact with the native platform.

  @visibleForTesting
  final methodChannel = const MethodChannel('jyahann:card_scan_channel');

  bool _isCallHandlerInitialized = false;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  final _eventController = StreamController<CardScanEvent>.broadcast();

  Stream<CardScanEvent> get events => _eventController.stream;

  @override
  void initCallHandler() {
    if (_isCallHandlerInitialized) return;
    _isCallHandlerInitialized = true;
    methodChannel.setMethodCallHandler((call) async {
      final event = CardScanEvent.fromMap(call.arguments);
      _eventController.add(event);
    });
  }

  @override
  void startGoogleScanner(bool isTest) {
    methodChannel.invokeMapMethod('startScan', {'isTest': isTest});
  }
}
