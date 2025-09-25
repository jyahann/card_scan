sealed class CardScanEvent {
  const CardScanEvent();

  factory CardScanEvent.fromMap(Map<String, dynamic> map) {
    if (map['type'] == 'scanDataReceived') {
      return CardScanEventScanDataReceived(
        number: map['number'],
        expDate: map['expDate'],
        holder: map['holder'],
      );
    }
    throw UnsupportedError('Unsupported event type: ${map['type']}');
  }
}

final class CardScanEventScanDataReceived extends CardScanEvent {
  final String number;
  final String expDate;
  final String holder;

  const CardScanEventScanDataReceived({
    required this.number,
    required this.expDate,
    required this.holder,
  });
}
