import 'package:card_scan/types/bounds.dart';
import 'package:flutter/material.dart';
import 'package:card_scan/card_scan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final bounds = const CardScanBounds(
    left: 0.1,
    top: 0.35,
    right: 0.1,
    bottom: 0.35,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: CardScan(bounds: bounds)),
    );

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            /// Камера + сканер
            Positioned.fill(child: CardScan(bounds: bounds)),

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
      ),
    );
  }
}
