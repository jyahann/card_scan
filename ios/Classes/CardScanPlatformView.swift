import Flutter
import UIKit
import SwiftUI

// Фабрика (без изменений, только возвращает платфор. вью)
class CardScanViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
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
            viewIdentifier: viewId,
            arguments: args,
            bounds: bounds,
            messenger: messenger)
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// Платформенная вью — хранит контейнер UIView и UIHostingController
class CardScanPlatformView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    private var hostingController: UIHostingController<CardScanView>?
    private let bounds: CardScanBounds
    private let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        bounds: CardScanBounds,
        messenger: FlutterBinaryMessenger
    ) {
        self.bounds = bounds
        self.channel = FlutterMethodChannel(name: "jyahann:card_scan_channel", binaryMessenger: messenger)

        // создаём контейнер с нужным фреймом
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear
        super.init()

        createNativeView(frame: frame, args: args)
    }

    func view() -> UIView {
        return containerView
    }

    private func createNativeView(frame: CGRect, args: Any?) {
        // Берём topController (самый верхний VC, а не просто root)
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var topController = keyWindow?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }

        // Создаём SwiftUI-вью
        let swiftUIView = CardScanView(
            bounds: bounds,
            channel: channel
        )

        // Оборачиваем в UIHostingController
        let host = UIHostingController(rootView: swiftUIView)
        hostingController = host

        // Настраиваем view hosting'а
        host.view.frame = containerView.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear

        // Добавляем как сабвью
        containerView.addSubview(host.view)

        // Подвязываем к topController
        if let parent = topController {
            parent.addChild(host)
            host.didMove(toParent: parent)
        } else {
            assertionFailure("❌ Не удалось найти topController для UIHostingController")
        }
    }
}
