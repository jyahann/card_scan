import Flutter
import UIKit
import SwiftUI

class CardScanViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }

    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        
        guard let bounds = CardScanBounds(from: args) else {
            fatalError("Invalid CardScanBounds params from Flutter")
        }
        
        return CardScanPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            bounds: bounds
        )
    }
}


class CardScanPlatformView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let bounds: CardScanBounds
    private let rootView: UIView
    
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, bounds: CardScanBounds) {
        self.bounds = bounds
        self.channel = FlutterMethodChannel(name: "jyahann:card_scan_channel", binaryMessenger: messenger)
        
        let hosting = UIHostingController(
            rootView: CardScanView(bounds: bounds, channel: self.channel)
        )
        
        self.rootView = hosting.view
        self.rootView.frame = frame
        
        super.init()
    }
    
    func view() -> UIView {
        return rootView
    }
}
