import Flutter
import SwiftUI

struct CardScanView: View {
    let bounds: CardScanBounds
    let observationsCountLimit: Int
    let cardNumberThreshold: Int
    let cardExpiryThreshold: Int
    let cardHolderThreshold: Int
    let channel: FlutterMethodChannel

    var body: some View {
        CardScanner(
            configuration: CardScanner.Configuration(
                bounds: bounds,
                observationsCountLimit: observationsCountLimit,
                cardNumberThreshold: cardNumberThreshold,
                cardExpiryThreshold: cardExpiryThreshold,
                cardHolderThreshold: cardHolderThreshold
            ),
            channel: channel

        ) { cardNumber, expiryDate, holder in
            channel.invokeMethod(
                "onCardScanned",
                arguments: [
                    "type": "scanDataReceived",
                    "data": [
                        "cardNumber": cardNumber ?? "",
                        "expiryDate": expiryDate ?? "",
                        "cardHolder": holder ?? "",
                    ],
                ]
            )
        }
    }
}
