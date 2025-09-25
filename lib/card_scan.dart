import 'dart:convert';

import 'package:card_scan/types/bounds.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CardScan extends StatefulWidget {
  final CardScanBounds bounds;

  const CardScan({
    super.key,
    this.bounds = const CardScanBounds(
      left: 0.1,
      top: 0.35,
      right: 0.1,
      bottom: 0.35,
    ),
  });

  @override
  State<CardScan> createState() => _CardScanState();
}

class _CardScanState extends State<CardScan> {
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
