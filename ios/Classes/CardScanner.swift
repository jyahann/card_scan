import SwiftUI
import Flutter

public typealias CardScannerHandler = (_ number: String?, _ expDate: String?, _ holder: String?) -> Void

public struct CardScanner: UIViewControllerRepresentable {

    public struct Configuration {
        let bounds: CardScanBounds
        let drawBoxes: Bool
        let observationsCountLimit: Int
        let cardNumberThreshold: Int
        let cardExpiryThreshold: Int
        let cardHolderThreshold: Int

        init(
            bounds: CardScanBounds,
            drawBoxes: Bool = false,
            observationsCountLimit: Int,
            cardNumberThreshold: Int,
            cardExpiryThreshold: Int,
            cardHolderThreshold: Int
        ) {
            self.bounds = bounds
            self.drawBoxes = drawBoxes
            self.observationsCountLimit = observationsCountLimit
            self.cardExpiryThreshold = cardExpiryThreshold
            self.cardNumberThreshold = cardNumberThreshold
            self.cardHolderThreshold = cardHolderThreshold
        }
    }
    
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    private let firstNameSuggestion: String
    private let lastNameSuggestion: String
    private let configuration: Configuration
    private let channel: FlutterMethodChannel
    
    // MARK: - Actions
    let onCardScanned: CardScannerHandler
    
    public init(
        firstNameSuggestion: String = "",
        lastNameSuggestion: String = "",
        configuration: Configuration,
        channel: FlutterMethodChannel,
        onCardScanned: @escaping CardScannerHandler = { _, _, _ in }
    ) {
        self.firstNameSuggestion = firstNameSuggestion
        self.lastNameSuggestion = lastNameSuggestion
        self.configuration = configuration
        self.channel = channel
        self.onCardScanned = onCardScanned
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
   
    public func makeUIViewController(context: Context) -> CardScannerController {
        let scanner = CardScannerController(configuration: configuration, channel: channel)
        scanner.firstNameSuggestion = firstNameSuggestion
        scanner.lastNameSuggestion = lastNameSuggestion
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: CardScannerController, context: Context) { }
    
    public class Coordinator: NSObject, CardScannerDelegate {

        private let parent: CardScanner
        
        init(_ parent: CardScanner) {
            self.parent = parent
        }
        
        func didTapCancel() {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func didTapDone(number: String?, expDate: String?, holder: String?) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCardScanned(number, expDate, holder)
        }
        
        func didScanCard(number: String?, expDate: String?, holder: String?) {
            parent.onCardScanned(number, expDate, holder)
        }
    }
}
