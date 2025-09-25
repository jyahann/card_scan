import Flutter
import UIKit

public class CardScanPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = CardScanViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "jyahann:card_scan_view")
    }
}
