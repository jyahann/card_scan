sealed class CardScanEvent {
  const CardScanEvent();

  factory CardScanEvent.fromMap(Map map) {
    switch (map['type']) {
      case 'scanDataReceived':
        final data = map['data'] as Map;
        return CardScannedEvent(
          number: data['cardNumber'] as String?,
          expDate: data['expiryDate'] as String?,
          holder: data['cardHolder'] as String?,
        );
      case 'scanCancelled':
        return const CardScanCancelledEvent();
      case 'scanFailed':
        return CardScanFailedEvent(error: map['error'] as String?);
      default:
        throw UnsupportedError('Unsupported event type: ${map['type']}');
    }
  }
}

final class CardScannedEvent extends CardScanEvent {
  final String? number;
  final String? expDate;
  final String? holder;

  const CardScannedEvent({
    required this.number,
    required this.expDate,
    required this.holder,
  });
}

final class CardScanCancelledEvent extends CardScanEvent {
  const CardScanCancelledEvent();
}

final class CardScanFailedEvent extends CardScanEvent {
  final String? error;
  const CardScanFailedEvent({this.error});
}
