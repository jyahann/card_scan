// Region of interest
final class CardScanBounds {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const CardScanBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory CardScanBounds.fromMap(Map<String, double> map) {
    return CardScanBounds(
      left: map['left']!,
      top: map['top']!,
      right: map['right']!,
      bottom: map['bottom']!,
    );
  }

  Map<String, double> toMap() {
    return {'left': left, 'top': top, 'right': right, 'bottom': bottom};
  }
}
