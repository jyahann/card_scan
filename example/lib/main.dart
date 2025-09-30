import 'dart:io';

import 'package:flutter/material.dart';
import 'package:card_scan/card_scan.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CardScannedEvent? _lastEvent;

  Future<void> _openScanner() async {
    if (Platform.isAndroid) {
      final result = await GoogleCardScanner.scan(testEnvironment: true);
      if (result is CardScannedEvent) {
        setState(() {
          _lastEvent = result;
        });
      }
      return;
    }

    final result = await showDialog<CardScannedEvent>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CardScannerModal();
      },
    );

    if (result != null) {
      setState(() {
        _lastEvent = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Scanner Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _openScanner,
              child: const Text('Scan card'),
            ),
            const SizedBox(height: 20),
            if (_lastEvent != null)
              Text(
                'CardNumber: ${_lastEvent!.number}\n'
                'ExpDate: ${_lastEvent!.expDate}\n'
                'Holder: ${_lastEvent!.holder}',
                textAlign: TextAlign.center,
              )
            else
              const Text('No data'),
          ],
        ),
      ),
    );
  }
}

/// Вынес сканер в отдельный экран-модалку
class CardScannerModal extends StatefulWidget {
  const CardScannerModal({super.key});

  @override
  State<CardScannerModal> createState() => _CardScannerModalState();
}

class _CardScannerModalState extends State<CardScannerModal> {
  final bounds = const CardScanBounds(
    left: 0.1,
    top: 0.35,
    right: 0.1,
    bottom: 0.35,
  );

  bool isProcessed = false;
  CardScanningEvent? _scanningEvent;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Stack(
        children: [
          /// Camera + scanner
          Positioned.fill(
            child: CardScan(
              observationsCountLimit: 10,
              bounds: bounds,
              onScanning: (event) {
                setState(() {
                  _scanningEvent = event;
                });
              },
              onScanned: (event) {
                if (!isProcessed) {
                  isProcessed = true;
                  Navigator.of(context).pop(event); // return event
                }
              },
            ),
          ),

          /// Overlay
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final rect = Rect.fromLTRB(
                  bounds.left * width,
                  bounds.top * height,
                  width - bounds.right * width,
                  height - bounds.bottom * height,
                );

                return Stack(
                  children: [
                    /// Mask
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5),
                        BlendMode.srcOut,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              backgroundBlendMode: BlendMode.dstOut,
                            ),
                          ),
                          Positioned.fromRect(
                            rect: rect,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// White frame
                    Positioned.fromRect(
                      rect: rect,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    /// Hint
                    Positioned(
                      top: rect.top - 60,
                      left: 0,
                      right: 0,
                      child: const Center(
                        child: Text(
                          'Put the card in the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    /// Real-time scanning info
                    if (_scanningEvent != null)
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Scanning...\n'
                            'Card: ${_scanningEvent!.number ?? "-"}\n'
                            'Exp: ${_scanningEvent!.expDate ?? "-"}\n'
                            'Holder: ${_scanningEvent!.holder ?? "-"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
