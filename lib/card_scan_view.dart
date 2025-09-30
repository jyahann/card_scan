import 'dart:async';

import 'package:card_scan/card_scan_platform_interface.dart';
import 'package:card_scan/types/bounds.dart';
import 'package:card_scan/types/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// iOS ONLY: CardScan widget for embedding camera scanning view.
class CardScan extends StatefulWidget {
  /// Region of interest on screen (0.0–1.0 relative coordinates)
  final CardScanBounds bounds;

  /// Number of observations to wait before trying to stop scanning
  /// If no strong values are detected, returns the consensus.
  final int observationsCountLimit;

  /// Minimum repeats required to consider that card number, expiry, or holder is strong
  final int cardNumberThreshold;
  final int cardExpiryThreshold;
  final int cardHolderThreshold;

  /// Callbacks for scanning events
  final void Function(CardScannedEvent event)? onScanned;
  final void Function(CardScanningEvent event)? onScanning;

  const CardScan({
    super.key,
    this.bounds = const CardScanBounds(
      left: 0.1,
      top: 0.35,
      right: 0.1,
      bottom: 0.35,
    ),
    this.observationsCountLimit = 5,
    this.cardNumberThreshold = 2,
    this.cardExpiryThreshold = 2,
    this.cardHolderThreshold = 2,
    this.onScanned,
    this.onScanning,
  });

  @override
  State<CardScan> createState() => _CardScanState();
}

class _CardScanState extends State<CardScan> {
  /// Subscription to platform events coming from native side
  late StreamSubscription<CardScanEvent> _subscription;

  @override
  void initState() {
    super.initState();

    // Listen for events from the native side
    _subscription = CardScanPlatform.instance.events.listen((event) {
      if (event is CardScannedEvent) {
        // Trigger onScanned callback when a card is successfully recognized
        widget.onScanned?.call(event);
      } else if (event is CardScanningEvent) {
        // Optional: intermediate scanning events
        widget.onScanning?.call(event);
      }
    });

    // Initialize platform method channel handler (must be called)
    CardScanPlatform.instance.initCallHandler();
  }

  @override
  void dispose() {
    // Cancel subscription to avoid memory leaks
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Unique identifier for the native view
    const String viewType = 'jyahann:card_scan_view';

    // Parameters passed to the platform side
    final Map<String, dynamic> creationParams = {
      'bounds': widget.bounds.toMap(),
      'observationsCountLimit': widget.observationsCountLimit,
      'cardNumberThreshold': widget.cardNumberThreshold,
      'cardExpiryThreshold': widget.cardExpiryThreshold,
      'cardHolderThreshold': widget.cardHolderThreshold,
    };

    // iOS UiKitView embeds native scanning view
    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
