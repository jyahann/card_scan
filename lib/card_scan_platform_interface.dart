import 'package:card_scan/types/events.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'card_scan_method_channel.dart';

abstract class CardScanPlatform extends PlatformInterface {
  /// Constructs a CardScanPlatform.
  CardScanPlatform() : super(token: _token);

  static final Object _token = Object();

  static CardScanPlatform _instance = MethodChannelCardScan();

  /// The default instance of [CardScanPlatform] to use.
  ///
  /// Defaults to [MethodChannelCardScan].
  static CardScanPlatform get instance => _instance;

  Stream<CardScanEvent> get events;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CardScanPlatform] when
  /// they register themselves.
  static set instance(CardScanPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void startGoogleScanner(bool isTest);

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  void initCallHandler();
}
