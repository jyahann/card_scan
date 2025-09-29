import 'dart:async';

import 'package:card_scan/card_scan_platform_interface.dart';
import 'package:card_scan/types/bounds.dart';
import 'package:card_scan/types/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CardScan extends StatefulWidget {
  final CardScanBounds bounds;
  final void Function(CardScannedEvent event)? onScanned;

  const CardScan({
    super.key,
    this.bounds = const CardScanBounds(
      left: 0.1,
      top: 0.35,
      right: 0.1,
      bottom: 0.35,
    ),
    this.onScanned,
  });

  @override
  State<CardScan> createState() => _CardScanState();
}

class _CardScanState extends State<CardScan> {
  late StreamSubscription<CardScanEvent> _subscription;
  @override
  void initState() {
    _subscription = CardScanPlatform.instance.events.listen((event) {
      if (event is CardScannedEvent) {
        widget.onScanned?.call(event);
      }
    });

    super.initState();

    CardScanPlatform.instance.initCallHandler();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'jyahann:card_scan_view';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = {
      'bounds': widget.bounds.toMap(),
    };

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
