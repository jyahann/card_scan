import 'dart:io';

import 'package:card_scan/google_card_scanner.dart';
import 'package:card_scan/types/bounds.dart';
import 'package:card_scan/types/events.dart';
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
      final result = await GoogleCardScanner.scan();
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
              child: const Text('Сканировать карту'),
            ),
            const SizedBox(height: 20),
            if (_lastEvent != null)
              Text(
                'Карта: ${_lastEvent!.number}\n'
                'Дата: ${_lastEvent!.expDate}\n'
                'Владелец: ${_lastEvent!.holder}',
                textAlign: TextAlign.center,
              )
            else
              const Text('Нет данных'),
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

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Stack(
        children: [
          /// Камера + сканер
          Positioned.fill(
            child: CardScan(
              bounds: bounds,
              onScanned: (event) {
                if (!isProcessed) {
                  isProcessed = true;
                  Navigator.of(context).pop(event); // вернуть ивент
                }
              },
            ),
          ),

          /// Оверлей
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
                    /// Полупрозрачная маска
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

                    /// Белая рамка
                    Positioned.fromRect(
                      rect: rect,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    /// Подсказка
                    Positioned(
                      top: rect.top - 60,
                      left: 0,
                      right: 0,
                      child: const Center(
                        child: Text(
                          'Наведите карту в рамку',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
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
