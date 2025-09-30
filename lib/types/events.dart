/// Base class for all card scanning events
sealed class CardScanEvent {
  const CardScanEvent();

  /// Factory to convert platform map into Dart event
  factory CardScanEvent.fromMap(Map map) {
    switch (map['type']) {
      case 'scanDataReceived':
        final data = map['data'] as Map;
        // Fired when card data is successfully scanned
        return CardScannedEvent(
          number: data['cardNumber'] as String?,
          expDate: data['expiryDate'] as String?,
          holder: data['cardHolder'] as String?,
        );
      case 'cardScanning':
        final data = map['data'] as Map;
        return CardScanningEvent(
          number: data['cardNumber'] as String?,
          expDate: data['expiryDate'] as String?,
          holder: data['cardHolder'] as String?,
        );
      case 'scanCancelled':
        // Fired when user cancels scanning
        return const CardScanCancelledEvent();
      case 'scanFailed':
        // Fired when scanning fails due to error
        return CardScanFailedEvent(error: map['error'] as String?);
      case 'scanGoogleAccountError':
        // Fired if Google account / authorization error occurs on Android
        return const CardScanGoogleAccountErrorEvent();
      default:
        throw UnsupportedError('Unsupported event type: ${map['type']}');
    }
  }
}

/// Fired when a card is successfully scanned
final class CardScannedEvent extends CardScanEvent {
  final String? number; // Card number (may be null if partial scan)
  final String? expDate; // Expiry date, format XX/XX
  final String? holder; // Card holder name

  const CardScannedEvent({
    required this.number,
    required this.expDate,
    required this.holder,
  });
}

/// Optional intermediate scanning data (per frame or per observation)
/// (iOS) only
final class CardScanningEvent extends CardScanEvent {
  final String? number;
  final String? expDate;
  final String? holder;

  const CardScanningEvent({
    required this.number,
    required this.expDate,
    required this.holder,
  });
}

/// User cancelled scanning
final class CardScanCancelledEvent extends CardScanEvent {
  const CardScanCancelledEvent();
}

/// Scanning failed due to error
final class CardScanFailedEvent extends CardScanEvent {
  final String? error;
  const CardScanFailedEvent({this.error});
}

/// Google account / auth error on Android
final class CardScanGoogleAccountErrorEvent extends CardScanEvent {
  const CardScanGoogleAccountErrorEvent();
}
