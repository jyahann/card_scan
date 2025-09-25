import SwiftUI
import Flutter

struct CardScanView: View {
    let bounds: CardScanBounds
    let channel: FlutterMethodChannel

    var body: some View {
        CardScanner(
            configuration: CardScanner.Configuration(bounds: bounds),
        ) { cardNumber, expiryDate, holder in
            channel.invokeMethod("onCardScanned", arguments: [
                "cardNumber": cardNumber ?? "",
                "expiryDate": expiryDate ?? "",
                "cardHolder": holder ?? ""
            ])
        }
    }
}
